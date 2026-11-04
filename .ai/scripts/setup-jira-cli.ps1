<#
.SYNOPSIS
    Configure jira-cli (ankitpokhrel/jira-cli) against Jira Cloud.

.DESCRIPTION
    Interactive, idempotent setup for jira-cli on Windows against a Jira Cloud site.
    It never writes the API token to disk in plain text inside this repository; the token
    is stored as a user-scoped environment variable (JIRA_API_TOKEN) in the registry of the
    current Windows user, which is what jira-cli reads.

    Steps performed:
      1. Verify the `jira` binary is on PATH.
      2. Read the token from a secure prompt (or from an existing JIRA_API_TOKEN).
      3. Persist JIRA_API_TOKEN as a user environment variable.
      4. Run `jira init` non-interactively for a Cloud installation.
      5. Verify with `jira me`, `jira project list` and `jira issue list`.

.PARAMETER Server
    Jira Cloud site URL. Mandatory: pass it explicitly, there is no built-in default.

.PARAMETER Project
    Default project key stored in the jira-cli configuration.

.PARAMETER Board
    Default board name stored in the jira-cli configuration.

.PARAMETER Email
    Atlassian account email. Prompted when omitted.

.PARAMETER UseNetrc
    Store the credentials in %USERPROFILE%\_netrc instead of JIRA_API_TOKEN.

.PARAMETER NonInteractive
    Never prompt. Requires -Email and an existing JIRA_API_TOKEN (session or user scope).
    Intended for re-running the setup, for scripts, and for piping the output.

.EXAMPLE
    .\setup-jira-cli.ps1 -Server https://mysite.atlassian.net -Project ABC

.EXAMPLE
    .\setup-jira-cli.ps1 -NonInteractive -Email me@example.com

.EXAMPLE
    .\setup-jira-cli.ps1 -Email me@example.com -Project ABC -Board "ABC board"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Server,
    [string]$Project,
    [string]$Board,
    [string]$Email,
    [switch]$UseNetrc,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    OK  $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    !   $Message" -ForegroundColor Yellow
}

# This machine's TLS stack intermittently drops connections with
# "Received an unexpected EOF or 0 bytes from the transport stream".
# Retry, and fall back to curl.exe, before declaring a network failure.
function Get-JiraRest {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][string]$Authorization,
        [int]$Attempts = 3
    )

    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            return Invoke-WebRequest -Uri $Uri -Headers @{ Authorization = $Authorization } `
                -UseBasicParsing -SkipHttpErrorCheck -TimeoutSec 45
        } catch {
            if ($i -eq $Attempts) {
                Write-Warn "Invoke-WebRequest failed $i times: $($_.Exception.GetBaseException().Message)"
            } else {
                Start-Sleep -Seconds (2 * $i)
            }
        }
    }

    Write-Warn "falling back to curl.exe"
    $hdr = Join-Path $env:TEMP "jira-probe-$([guid]::NewGuid()).hdr"
    try {
        Set-Content -Path $hdr -Value "Authorization: $Authorization" -Encoding ascii
        # -o writes the body to a temp file so the caller can still parse .Content
        $body = Join-Path $env:TEMP "jira-probe-$([guid]::NewGuid()).json"
        $code = & curl.exe -sS -o $body -w '%{http_code}' -H "@$hdr" $Uri 2>&1
        if (-not ($code -match '^\d{3}$')) {
            throw "curl.exe failed: $code"
        }
        return [pscustomobject]@{
            StatusCode = [int]$code
            Content    = if (Test-Path $body) { Get-Content $body -Raw } else { '' }
        }
    } finally {
        Remove-Item $hdr -Force -ErrorAction SilentlyContinue
        if ($body) { Remove-Item $body -Force -ErrorAction SilentlyContinue }
    }
}

# ---------------------------------------------------------------- 1. binary check
Write-Step "Checking the jira binary"

$jira = Get-Command jira -ErrorAction SilentlyContinue
if (-not $jira) {
    $fallback = Join-Path $env:USERPROFILE 'tools\jira-cli\bin\jira.exe'
    if (Test-Path $fallback) {
        $env:Path = "$env:Path;$(Split-Path $fallback -Parent)"
        $jira = Get-Command jira -ErrorAction SilentlyContinue
    }
}
if (-not $jira) {
    throw "jira.exe not found on PATH. Install it first (see https://github.com/ankitpokhrel/jira-cli/wiki/Installation)."
}
Write-Ok "$($jira.Source)"
Write-Ok (& jira version)

# ---------------------------------------------------------------- 2. identity
Write-Step "Atlassian account"

if ([string]::IsNullOrWhiteSpace($Email)) {
    if ($NonInteractive) {
        throw "-NonInteractive requires -Email."
    }
    do {
        $Email = Read-Host "    Atlassian email"
    } while ([string]::IsNullOrWhiteSpace($Email))
}
Write-Ok "email: $Email"

# ---------------------------------------------------------------- 3. token
Write-Step "API token"

$token = $env:JIRA_API_TOKEN
if ([string]::IsNullOrWhiteSpace($token)) {
    $token = [Environment]::GetEnvironmentVariable('JIRA_API_TOKEN', 'User')
    if (-not [string]::IsNullOrWhiteSpace($token)) {
        $env:JIRA_API_TOKEN = $token
        Write-Ok "loaded JIRA_API_TOKEN from the user environment"
    }
}
if ([string]::IsNullOrWhiteSpace($token)) {
    if ($NonInteractive) {
        throw "-NonInteractive requires JIRA_API_TOKEN to be set (session or user scope)."
    }
    $secure = Read-Host "    Paste the API token (input hidden)" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "Empty token."
    }
    Write-Ok "token captured (length $($token.Length))"
} else {
    Write-Ok "reusing JIRA_API_TOKEN (length $($token.Length))"
}
if ($token -match '\s') {
    Write-Warn "the token contains whitespace; trim it or Jira will reject the request"
}

if ($UseNetrc) {
    $netrc = Join-Path $env:USERPROFILE '_netrc'
    $host_ = ([Uri]$Server).Host
    $line = "machine $host_ login $Email password $token"
    if (Test-Path $netrc) {
        $kept = Get-Content $netrc | Where-Object { $_ -notmatch [regex]::Escape($host_) }
        Set-Content -Path $netrc -Value ($kept + $line) -Encoding ascii
    } else {
        Set-Content -Path $netrc -Value $line -Encoding ascii
    }
    Write-Ok "credentials written to $netrc"
    Write-Warn "jira-cli reads netrc lazily; if auth fails, fall back to JIRA_API_TOKEN"
} else {
    [Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $token, 'User')
    $env:JIRA_API_TOKEN = $token
    Write-Ok "JIRA_API_TOKEN persisted for the current Windows user"
}

# ---------------------------------------------------------------- 4. connectivity
Write-Step "Checking connectivity to $Server"

$authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Email}:${token}"))
$probe = Get-JiraRest -Uri "$Server/rest/api/2/myself" -Authorization $authorization

if ($probe.StatusCode -ne 200) {
    $detail = if ($probe.Content) { ($probe.Content | ConvertFrom-Json).errorMessages -join '; ' } else { 'no response body' }
    throw "Authentication failed (HTTP $($probe.StatusCode)): $detail. Check the email and the API token."
}
$me = $probe.Content | ConvertFrom-Json
Write-Ok "authenticated as $($me.displayName) <$($me.emailAddress)>"
Write-Ok "accountId: $($me.accountId)"

# ---------------------------------------------------------------- 5. init
Write-Step "Initialising jira-cli configuration"

& jira init `
    --installation cloud `
    --server $Server `
    --login $Email `
    --auth-type basic `
    --project $Project `
    --board $Board `
    --force

if ($LASTEXITCODE -ne 0) {
    throw "jira init failed with exit code $LASTEXITCODE"
}

$configPath = Join-Path $env:USERPROFILE '.config\.jira\.config.yml'
if (Test-Path $configPath) {
    Write-Ok "config written to $configPath"
    Write-Ok "size: $((Get-Item $configPath).Length) bytes"
} else {
    Write-Warn "expected config not found at $configPath"
}

# ---------------------------------------------------------------- 6. verification
Write-Step "Verifying"

Write-Host "    --- jira me ---"
& jira me

Write-Host "    --- projects visible to the account (REST) ---"
$projResp = Get-JiraRest -Uri "$Server/rest/api/2/project" -Authorization $authorization
($projResp.Content | ConvertFrom-Json) | Select-Object -First 12 | ForEach-Object { "        $($_.key)  $($_.name)" }

Write-Host "    --- my issues (jira-cli) ---"
$me_login = & jira me 2>&1
& jira issue list -a"$me_login" --plain --no-headers 2>&1 | Select-Object -First 10

Write-Step "Done"
Write-Host "    Config : $configPath"
Write-Host "    Token  : $(if ($UseNetrc) { 'netrc' } else { 'JIRA_API_TOKEN (user env var)' })"
Write-Host "    Next   : jira issue list -q ""project = $Project AND statusCategory != Done""" -ForegroundColor Gray
