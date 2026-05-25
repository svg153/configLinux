[CmdletBinding()]
param(
    [int]$PreferredEngramPort = 7437,
    [int]$FallbackEngramPort = 7440,
    [int]$PreferredMonitorPort = 5173,
    [string]$BindHost = '127.0.0.1',
    [string]$MonitorDir = $(if ($env:ENGRAM_MONITOR_DIR) { $env:ENGRAM_MONITOR_DIR } else { Join-Path $HOME 'engram-monitor' }),
    [string]$MonitorRepoUrl = 'https://github.com/egdev6/engram-monitor.git',
    [string]$McpConfigPath = $(if ($env:MCP_CONFIG_PATH) { $env:MCP_CONFIG_PATH } else { Join-Path $env:APPDATA 'Code - Insiders\User\mcp.json' }),
    [string]$E2EProject = 'configlinux',
    [switch]$RunE2ECheck
)

$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogsDir = Join-Path $ScriptRoot 'logs'
$E2EScreenshotPath = Join-Path $LogsDir 'engram-monitor-e2e.png'

New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

function Write-Step([string]$Message) {
    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Write-WarnLine([string]$Message) {
    Write-Host $Message -ForegroundColor Yellow
}

function Invoke-External([string]$FilePath, [object[]]$Arguments, [string]$FailureMessage) {
    if ($null -eq $Arguments -or $Arguments.Count -eq 0) {
        & $FilePath
    }
    else {
        & $FilePath @Arguments
    }
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code: $LASTEXITCODE)"
    }
}

function Resolve-ExistingCommandPath([string[]]$Candidates, [string]$CommandName) {
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    $cmd = Get-Command $CommandName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) {
        return $cmd.Source
    }

    return $null
}

function Get-VsCodeEngramMcpInfo([string]$ConfigPath) {
    $info = [ordered]@{
        ConfigPath = $ConfigPath
        Exists = $false
        Present = $false
        ServerName = $null
        Transport = $null
        Command = $null
        Url = $null
        Status = 'mcp.json not found'
    }

    if (-not (Test-Path $ConfigPath)) {
        return $info
    }

    $info.Exists = $true
    $content = Get-Content $ConfigPath -Raw

    $stdioMatch = [regex]::Match($content, '(?ms)^\s*"engram-stdio"\s*:\s*\{(?<block>.*?)^\s*\}')
    if ($stdioMatch.Success) {
        $block = $stdioMatch.Groups['block'].Value
        $commandMatch = [regex]::Match($block, '(?m)^\s*"command"\s*:\s*"(?<command>[^"]+)"')

        $info.Present = $true
        $info.ServerName = 'engram-stdio'
        $info.Transport = 'stdio'
        $info.Command = if ($commandMatch.Success) { $commandMatch.Groups['command'].Value } else { 'engram' }
        $info.Status = 'OK (active `engram-stdio` entry found in VS Code mcp.json)'
        return $info
    }

    $httpMatch = [regex]::Match($content, '(?ms)^\s*"engram"\s*:\s*\{(?<block>.*?)^\s*\}')
    if ($httpMatch.Success) {
        $block = $httpMatch.Groups['block'].Value
        $typeMatch = [regex]::Match($block, '(?m)^\s*"type"\s*:\s*"(?<type>[^"]+)"')
        $urlMatch = [regex]::Match($block, '(?m)^\s*"url"\s*:\s*"(?<url>[^"]+)"')

        $info.Present = $true
        $info.ServerName = 'engram'
        $info.Transport = if ($typeMatch.Success) { $typeMatch.Groups['type'].Value } else { 'unknown' }
        $info.Url = if ($urlMatch.Success) { $urlMatch.Groups['url'].Value } else { $null }
        $info.Status = 'OK (active `engram` entry found in VS Code mcp.json)'
        return $info
    }

    $info.Status = 'No active Engram MCP entry found in VS Code mcp.json'
    return $info
}

function Invoke-Http([string]$Url, [int]$TimeoutSec = 3) {
    try {
        return Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSec
    }
    catch {
        return $null
    }
}

function Test-EngramHealth([int]$Port) {
    $response = Invoke-Http -Url ("http://${BindHost}:$Port/health") -TimeoutSec 3
    if (-not $response) { return $false }
    return ($response.StatusCode -eq 200)
}

function Test-MonitorUi([int]$Port) {
    $response = Invoke-Http -Url ("http://${BindHost}:$Port/") -TimeoutSec 3
    if (-not $response) { return $false }
    return ($response.StatusCode -eq 200 -and $response.Content -match '<div id="root">')
}

function Get-ListenerProcess([int]$Port) {
    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $listener) { return $null }
    return Get-CimInstance Win32_Process -Filter ("ProcessId = " + $listener.OwningProcess) -ErrorAction SilentlyContinue
}

function Get-FreePort([int[]]$Candidates) {
    foreach ($candidate in $Candidates) {
        $listener = Get-NetTCPConnection -LocalPort $candidate -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $listener) {
            return $candidate
        }
    }

    throw "No free port found in candidates: $($Candidates -join ', ')"
}

function Wait-ForCondition([scriptblock]$Condition, [int]$MaxSeconds, [string]$FailureMessage) {
    for ($i = 0; $i -lt $MaxSeconds; $i++) {
        if (& $Condition) {
            return
        }
        Start-Sleep -Seconds 1
    }

    throw $FailureMessage
}

function Ensure-PnpmInstalled() {
    $pnpmCmd = Resolve-ExistingCommandPath -Candidates @(
        (Join-Path $env:LOCALAPPDATA 'Programs\NodeJS\pnpm.cmd')
    ) -CommandName 'pnpm'

    if ($pnpmCmd) {
        return @{ Mode = 'pnpm'; Path = $pnpmCmd }
    }

    $corepackCmd = Resolve-ExistingCommandPath -Candidates @(
        (Join-Path $env:LOCALAPPDATA 'Programs\NodeJS\corepack.cmd')
    ) -CommandName 'corepack'

    if (-not $corepackCmd) {
        throw 'Neither pnpm nor corepack were found. Install Node.js/Corepack first.'
    }

    Write-Step 'Enabling pnpm with Corepack'
    Invoke-External -FilePath $corepackCmd -Arguments @('enable', 'pnpm') -FailureMessage 'Failed to enable pnpm via Corepack'

    $pnpmCmd = Resolve-ExistingCommandPath -Candidates @(
        (Join-Path $env:LOCALAPPDATA 'Programs\NodeJS\pnpm.cmd')
    ) -CommandName 'pnpm'

    if ($pnpmCmd) {
        return @{ Mode = 'pnpm'; Path = $pnpmCmd }
    }

    return @{ Mode = 'corepack'; Path = $corepackCmd }
}

function Invoke-PnpmCommand([hashtable]$PnpmInfo, [string[]]$CliArgs, [string]$WorkingDirectory) {
    Push-Location $WorkingDirectory
    try {
        if ($PnpmInfo.Mode -eq 'pnpm') {
            Invoke-External -FilePath $PnpmInfo.Path -Arguments @($CliArgs) -FailureMessage 'pnpm command failed'
        }
        else {
            Invoke-External -FilePath $PnpmInfo.Path -Arguments (@('pnpm') + $CliArgs) -FailureMessage 'corepack pnpm command failed'
        }
    }
    finally {
        Pop-Location
    }
}

function Ensure-NpmInstalled() {
    $npmCmd = Resolve-ExistingCommandPath -Candidates @(
        (Join-Path $env:LOCALAPPDATA 'Programs\NodeJS\npm.cmd'),
        (Join-Path $env:LOCALAPPDATA 'Programs\NodeJS\npm.ps1')
    ) -CommandName 'npm'

    if (-not $npmCmd) {
        throw 'npm was not found. Install Node.js first.'
    }

    return $npmCmd
}

function Start-DetachedPowerShell([string]$Command, [string]$StdOut, [string]$StdErr) {
    return Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        $Command
    ) -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr -PassThru
}

function Test-McpLaunch([string]$EngramExe) {
    $stdout = Join-Path $LogsDir 'engram-mcp-smoke.out.log'
    $stderr = Join-Path $LogsDir 'engram-mcp-smoke.err.log'
    $proc = Start-Process -FilePath $EngramExe -ArgumentList @('mcp', '--tools=agent') -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru

    Start-Sleep -Seconds 2

    if (-not $proc.HasExited) {
        Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue
        return @{ Ok = $true; StdOut = $stdout; StdErr = $stderr }
    }

    return @{ Ok = $false; StdOut = $stdout; StdErr = $stderr }
}

function Ensure-GitInstalled() {
    $gitCmd = Resolve-ExistingCommandPath -Candidates @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe'),
        (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Git\cmd\git.exe')
    ) -CommandName 'git'

    if (-not $gitCmd) {
        throw 'git was not found. Install Git before cloning engram-monitor.'
    }

    return $gitCmd
}

function Ensure-MonitorRepo([string]$TargetDir, [string]$RepoUrl) {
    if ((Test-Path (Join-Path $TargetDir 'package.json')) -and (Test-Path (Join-Path $TargetDir 'vite.config.ts'))) {
        return
    }

    $gitCmd = Ensure-GitInstalled
    if (-not (Test-Path $TargetDir)) {
        $parent = Split-Path -Parent $TargetDir
        if ($parent) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }

        Write-Step "Cloning engram-monitor into $TargetDir"
        Invoke-External -FilePath $gitCmd -Arguments @('clone', $RepoUrl, $TargetDir) -FailureMessage 'Failed to clone engram-monitor'
        return
    }

    throw "Monitor directory exists but does not look like engram-monitor: $TargetDir"
}

function Ensure-MonitorProxyPatch([string]$TargetDir) {
    $viteConfigPath = Join-Path $TargetDir 'vite.config.ts'
    $content = Get-Content $viteConfigPath -Raw
    $updated = $content

    if ($updated -notmatch "const engramPort = process\.env\.ENGRAM_PORT \?\? '7437';") {
        $updated = $updated -replace "(import svgr from 'vite-plugin-svgr';\r?\n)", "`$1`r`nconst engramPort = process.env.ENGRAM_PORT ?? '7437';`r`n"
    }

    $updated = $updated -replace "target:\s*'http://127\.0\.0\.1:7437'", 'target: `http://127.0.0.1:${engramPort}`'

    if ($updated -ne $content) {
        Set-Content -Path $viteConfigPath -Value $updated -Encoding UTF8
        Write-Host 'Patched engram-monitor `vite.config.ts` for configurable ENGRAM_PORT.' -ForegroundColor Green
    }
}

function Ensure-PlaywrightInstalled([string]$NpmCmd) {
    $playwrightPath = Join-Path $ScriptRoot 'node_modules\playwright'
    if (Test-Path $playwrightPath) {
        return
    }

    Write-Step 'Installing local Playwright dependency for E2E checks'
    Push-Location $ScriptRoot
    try {
        Invoke-External -FilePath $NpmCmd -Arguments @('install') -FailureMessage 'Failed to install Playwright dependency'
    }
    finally {
        Pop-Location
    }
}

function Invoke-JsonGet([string]$Url) {
    return Invoke-RestMethod -Uri $Url -TimeoutSec 15
}

Ensure-MonitorRepo -TargetDir $MonitorDir -RepoUrl $MonitorRepoUrl
Ensure-MonitorProxyPatch -TargetDir $MonitorDir

$engramExe = Resolve-ExistingCommandPath -Candidates @(
    (Join-Path $env:LOCALAPPDATA 'Programs\NodeJS\engram.exe'),
    (Join-Path $HOME 'bin\engram.exe')
) -CommandName 'engram'

if (-not $engramExe) {
    throw 'engram.exe was not found. Install Engram first.'
}

$nodeCmd = Resolve-ExistingCommandPath -Candidates @(
    (Join-Path $env:LOCALAPPDATA 'Programs\NodeJS\node.exe')
) -CommandName 'node'

if (-not $nodeCmd) {
    throw 'node.exe was not found. Install Node.js first.'
}

$npmCmd = Ensure-NpmInstalled

Write-Step 'Checking MCP stdio configuration'
$mcpInfo = Get-VsCodeEngramMcpInfo -ConfigPath $McpConfigPath
$mcpConfigOk = $mcpInfo.Present
if ($mcpConfigOk) {
    Write-Host $mcpInfo.Status -ForegroundColor Green
}
else {
    Write-WarnLine $mcpInfo.Status
}

Write-Step 'Checking MCP stdio launchability'
$mcpSmoke = Test-McpLaunch -EngramExe $engramExe
if ($mcpSmoke.Ok) {
    Write-Host 'MCP stdio smoke test: OK (launchable)' -ForegroundColor Green
}
else {
    Write-WarnLine "MCP stdio smoke test failed. Check: $($mcpSmoke.StdErr)"
}

Write-Step 'Ensuring pnpm is available'
$pnpmInfo = Ensure-PnpmInstalled
Write-Host "pnpm mode: $($pnpmInfo.Mode)" -ForegroundColor Green

if (-not (Test-Path (Join-Path $MonitorDir 'node_modules'))) {
    Write-Step 'Installing engram-monitor dependencies'
    Invoke-PnpmCommand -PnpmInfo $pnpmInfo -CliArgs @('install', '--ignore-scripts') -WorkingDirectory $MonitorDir
}

Write-Step 'Resolving Engram API port'
$engramPort = $null
$engramStarted = $false

$engramCandidates = @($PreferredEngramPort) + ($FallbackEngramPort..($FallbackEngramPort + 10))
$healthyExistingEngram = $engramCandidates | Where-Object { Test-EngramHealth -Port $_ } | Select-Object -First 1

if ($healthyExistingEngram) {
    $engramPort = [int]$healthyExistingEngram
    Write-Host "Engram API already healthy on $engramPort" -ForegroundColor Green
}
else {
    $listener = Get-ListenerProcess -Port $PreferredEngramPort
    if ($listener) {
        Write-WarnLine "Port $PreferredEngramPort is busy by $($listener.Name). Falling back."
        $engramPort = Get-FreePort -Candidates ($FallbackEngramPort..($FallbackEngramPort + 10))
    }
    else {
        $engramPort = $PreferredEngramPort
    }

    $engramOut = Join-Path $LogsDir "engram-serve-$engramPort.out.log"
    $engramErr = Join-Path $LogsDir "engram-serve-$engramPort.err.log"
    $engramProc = Start-Process -FilePath $engramExe -ArgumentList @('serve', "$engramPort") -RedirectStandardOutput $engramOut -RedirectStandardError $engramErr -PassThru
    $engramStarted = $true

    Wait-ForCondition -Condition { Test-EngramHealth -Port $engramPort } -MaxSeconds 30 -FailureMessage "Engram API did not become healthy on port $engramPort. Check $engramErr"
    Write-Host "Engram API healthy on $engramPort (PID $($engramProc.Id))" -ForegroundColor Green
}

Write-Step 'Resolving monitor port'
$monitorPort = $null
$monitorStarted = $false
foreach ($candidate in ($PreferredMonitorPort..($PreferredMonitorPort + 10))) {
    if (Test-MonitorUi -Port $candidate) {
        $monitorPort = $candidate
        Write-Host "Monitor already responding on $monitorPort" -ForegroundColor Green
        break
    }

    $listener = Get-NetTCPConnection -LocalPort $candidate -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $listener) {
        $monitorPort = $candidate
        break
    }
}

if (-not $monitorPort) {
    throw 'Could not find a usable port for engram-monitor.'
}

if (-not (Test-MonitorUi -Port $monitorPort)) {
    $monitorOut = Join-Path $LogsDir "engram-monitor-$monitorPort.out.log"
    $monitorErr = Join-Path $LogsDir "engram-monitor-$monitorPort.err.log"

    $pnpmCommand = if ($pnpmInfo.Mode -eq 'pnpm') {
        "& '$($pnpmInfo.Path)' exec vite --host $BindHost --port $monitorPort --strictPort"
    }
    else {
        "& '$($pnpmInfo.Path)' pnpm exec vite --host $BindHost --port $monitorPort --strictPort"
    }

    $monitorCommand = @"
`$env:ENGRAM_PORT = '$engramPort'
Set-Location '$MonitorDir'
$pnpmCommand
"@

    $monitorProc = Start-DetachedPowerShell -Command $monitorCommand -StdOut $monitorOut -StdErr $monitorErr
    $monitorStarted = $true

    Wait-ForCondition -Condition { Test-MonitorUi -Port $monitorPort } -MaxSeconds 60 -FailureMessage "engram-monitor did not become reachable on port $monitorPort. Check $monitorErr"
    Write-Host "engram-monitor reachable on $monitorPort (PID $($monitorProc.Id))" -ForegroundColor Green
}

$e2eInfo = @{ Ran = $false; Token = $null; Screenshot = $null; DirectCount = 0; ProxyCount = 0 }
if ($RunE2ECheck) {
    Write-Step 'Running end-to-end Engram save/API/monitor validation'
    Ensure-PlaywrightInstalled -NpmCmd $npmCmd

    $token = 'ENGRAM-E2E-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
    Invoke-External -FilePath $engramExe -Arguments @('save', $token, 'Portable E2E seed created by configLinux start-engram-stack.ps1', '--type', 'manual', '--project', $E2EProject, '--scope', 'project') -FailureMessage 'Failed to save E2E observation through Engram CLI'

    $encodedToken = [uri]::EscapeDataString($token)
    $directResults = @(Invoke-JsonGet -Url ("http://${BindHost}:$engramPort/search?q=$encodedToken&limit=10"))
    $proxyResults = @(Invoke-JsonGet -Url ("http://${BindHost}:$monitorPort/engram-api/search?q=$encodedToken&limit=10"))

    if ($directResults.Count -lt 1) {
        throw "Direct Engram API did not return the E2E token $token"
    }
    if ($proxyResults.Count -lt 1) {
        throw "Monitor proxy did not return the E2E token $token"
    }

    Push-Location $ScriptRoot
    try {
        $env:ENGRAM_MONITOR_URL = "http://${BindHost}:$monitorPort/"
        $env:ENGRAM_E2E_TOKEN = $token
        $env:ENGRAM_E2E_SCREENSHOT = $E2EScreenshotPath
        $env:ENGRAM_LOGS_DIR = $LogsDir
        Invoke-External -FilePath $nodeCmd -Arguments @((Join-Path $ScriptRoot 'check-engram-monitor-e2e.js')) -FailureMessage 'Engram Monitor E2E UI check failed'
    }
    finally {
        Pop-Location
        Remove-Item Env:ENGRAM_MONITOR_URL -ErrorAction SilentlyContinue
        Remove-Item Env:ENGRAM_E2E_TOKEN -ErrorAction SilentlyContinue
        Remove-Item Env:ENGRAM_E2E_SCREENSHOT -ErrorAction SilentlyContinue
        Remove-Item Env:ENGRAM_LOGS_DIR -ErrorAction SilentlyContinue
    }

    $e2eInfo = @{
        Ran = $true
        Token = $token
        Screenshot = $E2EScreenshotPath
        DirectCount = $directResults.Count
        ProxyCount = $proxyResults.Count
    }
}

Write-Step 'Summary'
Write-Host "Script path        : $PSCommandPath"
Write-Host "Engram executable  : $engramExe"
Write-Host "Engram API         : http://${BindHost}:$engramPort/health"
Write-Host "Monitor UI         : http://${BindHost}:$monitorPort/"
Write-Host "Monitor repo       : $MonitorDir"
Write-Host "MCP server         : $(if ($mcpInfo.ServerName) { $mcpInfo.ServerName } else { 'not configured' })"
Write-Host "MCP transport      : $(if ($mcpInfo.Transport) { $mcpInfo.Transport } else { 'unknown' })"
Write-Host "MCP URL            : $(if ($mcpInfo.Url) { $mcpInfo.Url } else { 'N/A (VS Code lo usa por stdio)' })"
Write-Host "MCP in VS Code     : $($mcpInfo.Status)"
Write-Host "MCP config path    : $($mcpInfo.ConfigPath)"
Write-Host "MCP command        : $(if ($mcpInfo.Command) { $mcpInfo.Command + ' mcp --tools=agent' } else { 'N/A' })"
Write-Host "MCP smoke test     : $(if ($mcpSmoke.Ok) { 'OK (launchable)' } else { 'FAILED' })"
Write-Host "E2E check          : $(if ($e2eInfo.Ran) { 'OK' } else { 'skipped (use -RunE2ECheck)' })"
if ($e2eInfo.Ran) {
    Write-Host "E2E token          : $($e2eInfo.Token)"
    Write-Host "E2E API hits       : $($e2eInfo.DirectCount)"
    Write-Host "E2E proxy hits     : $($e2eInfo.ProxyCount)"
    Write-Host "E2E screenshot     : $($e2eInfo.Screenshot)"
}
Write-Host "Logs               : $LogsDir"

if ($engramStarted -or $monitorStarted) {
    Write-WarnLine 'Note: this script validates that the MCP command is launchable, but only VS Code can make it truly active/attached.'
}