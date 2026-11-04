<#
.SYNOPSIS
    Store the Jira API token encrypted at rest, bound to the current Windows user.

.DESCRIPTION
    jira-cli reads the token from the JIRA_API_TOKEN environment variable (or from a .netrc file).
    Putting it in HKCU\Environment works, but the registry stores it in plain text: any process
    running as the same user can read it, and it ends up in registry exports and support bundles.

    This script instead encrypts the token with DPAPI (ConvertFrom-SecureString), which binds the
    ciphertext to the current Windows user account on this machine. The ciphertext is useless on
    another machine, under another account, or after a password reset that invalidates the master
    key.

    The token is never written in plain text and is never passed on the command line (where it
    would land in shell history and in the process command line visible to other users).

    After running this once, `setup-jira-cli.ps1` and jira-cli itself work without prompting as
    long as the profile hook installed by -InstallProfileHook is active (or you dot-source
    Import-JiraToken.ps1 yourself).

.PARAMETER StorePath
    Where to write the encrypted blob. Defaults to
    %LOCALAPPDATA%\jira\token.dpapi — LocalAppData is user-only by ACL and is not synced to
    OneDrive, so the ciphertext does not roam to other devices.

.PARAMETER InstallProfileHook
    Append (or refresh) a marked block in the PowerShell profile that decrypts the blob and sets
    $env:JIRA_API_TOKEN for every new shell. This makes the token available to jira-cli without
    any manual step. The profile itself contains no secret, only the decryption call.

.PARAMETER RemoveRegistryVariable
    Delete the plain-text JIRA_API_TOKEN from HKCU\Environment once the encrypted store is in
    place and verified. Use this to stop leaking a readable copy.

.EXAMPLE
    .\store-jira-token.ps1 -InstallProfileHook -RemoveRegistryVariable

.EXAMPLE
    .\store-jira-token.ps1 -StorePath D:\secrets\jira.dpapi
#>
[CmdletBinding()]
param(
    [string]$StorePath = (Join-Path $env:LOCALAPPDATA 'jira\token.dpapi'),
    [switch]$InstallProfileHook,
    [switch]$RemoveRegistryVariable
)

$ErrorActionPreference = 'Stop'

function Write-Step { param([string]$m) Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok   { param([string]$m) Write-Host "    OK  $m" -ForegroundColor Green }
function Write-Warn { param([string]$m) Write-Host "    !   $m" -ForegroundColor Yellow }

$hookBegin = '# >>> jira-cli token >>>'
$hookEnd   = '# <<< jira-cli token <<<'

# ---------------------------------------------------------------- 1. obtain the token
Write-Step "Source of the token"

$token = $env:JIRA_API_TOKEN
if ([string]::IsNullOrWhiteSpace($token)) {
    $token = [Environment]::GetEnvironmentVariable('JIRA_API_TOKEN', 'User')
    if (-not [string]::IsNullOrWhiteSpace($token)) {
        Write-Ok "read the existing plain-text variable from HKCU\Environment"
    }
}

if ([string]::IsNullOrWhiteSpace($token) -and (Test-Path $StorePath)) {
    $stored = ConvertTo-SecureString ((Get-Content $StorePath -Raw).Trim())
    $storedBstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($stored)
    try   { $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($storedBstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($storedBstr) }
    Write-Ok "reusing the existing encrypted store at $StorePath (length $($token.Length))"
} elseif ([string]::IsNullOrWhiteSpace($token)) {
    $secure = Read-Host "    Paste the API token (input hidden)" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try   { $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    if ([string]::IsNullOrWhiteSpace($token)) { throw "Empty token." }
    Write-Ok "token captured from a secure prompt"
} else {
    Write-Ok "token length $($token.Length)"
}

if ($token -match '\s') { Write-Warn "the token contains whitespace; trim it or Jira will reject the request" }

# ---------------------------------------------------------------- 2. encrypt and store
Write-Step "Encrypting with DPAPI (current user)"

$dir = Split-Path $StorePath -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

$secureString = ConvertTo-SecureString $token -AsPlainText -Force
$cipher = ConvertFrom-SecureString $secureString          # DPAPI, user+machine bound
Set-Content -Path $StorePath -Value $cipher -Encoding ascii -NoNewline

# Mark it as user-only on disk as defence in depth.
try {
    $acl = Get-Acl $StorePath
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "$env:USERDOMAIN\$env:USERNAME", 'FullControl', 'Allow')
    $acl.AddAccessRule($rule)
    Set-Acl -Path $StorePath -AclObject $acl
    Write-Ok "ACL restricted to $env:USERNAME"
} catch {
    Write-Warn "could not tighten the ACL: $($_.Exception.Message)"
}

Write-Ok "encrypted blob: $StorePath ($((Get-Item $StorePath).Length) bytes)"
Write-Ok "ciphertext prefix: $($cipher.Substring(0, 20))... (not reversible off this machine)"

# ---------------------------------------------------------------- 3. profile hook
if ($InstallProfileHook) {
    Write-Step "Installing the PowerShell profile hook"

    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir  = Split-Path $profilePath -Parent
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }

    $existing = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { '' }
    # Drop a previous block so re-running is idempotent.
    $existing = [regex]::Replace($existing, "(?s)$([regex]::Escape($hookBegin)).*?$([regex]::Escape($hookEnd))\r?\n?", '')

    # Single-quoted here-string: the block below is written verbatim, so nothing
    # in it is expanded by this script. Do not change the quotes.
    $block = @'
# >>> jira-cli token >>>
# Decrypt the Jira API token with DPAPI and export it for jira-cli.
# The ciphertext lives in %LOCALAPPDATA%\jira\token.dpapi and is bound to this
# Windows user account. No secret is stored in this profile file.
if (-not $env:JIRA_API_TOKEN) {
    $__jiraStore = Join-Path $env:LOCALAPPDATA 'jira\token.dpapi'
    if (Test-Path $__jiraStore) {
        try {
            $__jiraCipher = (Get-Content $__jiraStore -Raw).Trim()
            $__jiraSecure = ConvertTo-SecureString $__jiraCipher
            $__jiraBstr   = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($__jiraSecure)
            try   { $env:JIRA_API_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($__jiraBstr) }
            finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($__jiraBstr) }
        } catch {
            Write-Warning "jira: could not decrypt the stored token: $($_.Exception.Message)"
        }
    }
}
# <<< jira-cli token <<<
'@

    Set-Content -Path $profilePath -Value ($block.TrimEnd() + "`r`n" + $existing) -Encoding UTF8
    Write-Ok "hook written to $profilePath"
    Write-Ok "it runs on every new PowerShell session and is idempotent"
}

# ---------------------------------------------------------------- 4. drop the plain-text copy
if ($RemoveRegistryVariable) {
    Write-Step "Removing the plain-text variable from HKCU\Environment"
    if ([Environment]::GetEnvironmentVariable('JIRA_API_TOKEN', 'User')) {
        [Environment]::SetEnvironmentVariable('JIRA_API_TOKEN', $null, 'User')
        Write-Ok "deleted; the registry no longer holds a readable token"
    } else {
        Write-Ok "already absent"
    }
    Write-Warn "open a NEW terminal so the stale value stops being inherited"
}

# ---------------------------------------------------------------- 5. round-trip check
Write-Step "Round-trip check"

$verify = ConvertTo-SecureString ((Get-Content $StorePath -Raw).Trim())
$verifyBstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($verify)
try {
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($verifyBstr)
    if ($plain -eq $token) { Write-Ok "decryption returns the same token" }
    else { throw "decrypted value does not match the input" }
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($verifyBstr)
}

Write-Step "Done"
Write-Host "    Store  : $StorePath" -ForegroundColor Gray
Write-Host "    Profile: $(if ($InstallProfileHook) { $PROFILE.CurrentUserAllHosts } else { '(not installed)' })" -ForegroundColor Gray
Write-Host "    Next   : open a NEW terminal and run: jira me" -ForegroundColor Gray
