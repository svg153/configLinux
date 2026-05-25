param(
    [string]$RepoPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$WorkGitHost = 'git.example.internal'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-GitBashPath {
    $cmd = Get-Command bash.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $fallbacks = @(
        (Join-Path $env:LocalAppData 'Programs\Git\bin\bash.exe'),
        (Join-Path $env:ProgramFiles 'Git\bin\bash.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Git\bin\bash.exe')
    )

    foreach ($fallback in $fallbacks) {
        if ($fallback -and (Test-Path $fallback)) { return $fallback }
    }

    throw 'Git Bash not found.'
}

function Test-PowerShellParse {
    param([Parameter(Mandatory)] [string]$Path)

    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null

    [pscustomobject]@{
        Path = $Path
        Pass = (@($errors).Count -eq 0)
        Errors = @($errors)
    }
}

function New-TempRepoCopy {
    param(
        [Parameter(Mandatory)] [string]$SourceRepo,
        [Parameter(Mandatory)] [string]$Tag
    )

    $root = Join-Path $env:TEMP ($Tag + [guid]::NewGuid().ToString('N'))
    $homeDir = Join-Path $root 'home'
    $repo = Join-Path $homeDir 'REPOSITORIOS\configLinux'
    New-Item -ItemType Directory -Force -Path (Split-Path $repo) | Out-Null
    Copy-Item $SourceRepo $repo -Recurse -Force
    [pscustomobject]@{
        Root = $root
        Home = $homeDir
        Repo = $repo
    }
}

function Invoke-BashSnippet {
    param(
        [Parameter(Mandatory)] [string]$BashPath,
        [Parameter(Mandatory)] [string]$RepoPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$Snippet,
        [string]$WorkGitHost = ''
    )

    $previousHome = $env:HOME
    $previousHost = $env:WORK_GIT_HOST
    try {
        $env:HOME = $HomePath
        if ($WorkGitHost) {
            $env:WORK_GIT_HOST = $WorkGitHost
        }

        $output = & $BashPath -lc "cd ~/REPOSITORIOS/configLinux; $Snippet" 2>&1
        [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = @($output | ForEach-Object { $_.ToString() })
            RepoPath = $RepoPath
        }
    }
    finally {
        if ($null -eq $previousHome) { Remove-Item Env:HOME -ErrorAction SilentlyContinue } else { $env:HOME = $previousHome }
        if ($null -eq $previousHost) { Remove-Item Env:WORK_GIT_HOST -ErrorAction SilentlyContinue } else { $env:WORK_GIT_HOST = $previousHost }
    }
}

function Invoke-WindowsEntryPoint {
    param(
        [Parameter(Mandatory)] [string]$RepoPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$Mode,
        [Parameter(Mandatory)] [string]$WorkGitHost
    )

    $terminalSettings = Join-Path $HomePath 'AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    $vscodeSettings = Join-Path $HomePath 'AppData\Roaming\Code - Insiders\User\settings.json'

    $output = & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File (Join-Path $RepoPath 'run.ps1') $Mode -HomePath $HomePath -WorkGitHost $WorkGitHost -WindowsTerminalSettingsPath $terminalSettings -VSCodeSettingsPath $vscodeSettings 2>&1
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = @($output | ForEach-Object { $_.ToString() })
        TerminalSettings = $terminalSettings
        VSCodeSettings = $vscodeSettings
    }
}

function Get-GitTemplateStatus {
    param([Parameter(Mandatory)] [string]$RepoPath)

    $personal = Join-Path $RepoPath '.gitconfig.d\personal-mail.gitconfig'
    $workIdentity = Join-Path $RepoPath '.gitconfig.d\work\work-company.gitconfig'
    $workRules = Join-Path $RepoPath '.gitconfig.d\work\work.gitconfig'
    $hostLine = ''
    if (Test-Path $workRules) {
        $match = Select-String -Path $workRules -SimpleMatch $WorkGitHost | Select-Object -First 1
        if ($match) { $hostLine = $match.Line.Trim() }
    }

    [pscustomobject]@{
        Personal = Test-Path $personal
        WorkIdentity = Test-Path $workIdentity
        WorkRules = Test-Path $workRules
        HostMatch = [bool]$hostLine
        HostLine = $hostLine
    }
}

function Write-Result {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [bool]$Pass,
        [string]$Details = ''
    )

    $status = if ($Pass) { 'PASS' } else { 'FAIL' }
    if ($Details) {
        Write-Host ("RESULT $Name $status $Details")
    } else {
        Write-Host ("RESULT $Name $status")
    }
}

function Write-Skip {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [string]$Details = ''
    )

    if ($Details) {
        Write-Host ("RESULT $Name SKIP $Details")
    } else {
        Write-Host ("RESULT $Name SKIP")
    }
}

$runPsParse = Test-PowerShellParse -Path (Join-Path $RepoPath 'run.ps1')
Write-Result -Name 'ps-parse-run.ps1' -Pass $runPsParse.Pass -Details (("errors=" + @($runPsParse.Errors).Count))

$windowsStagesParse = Test-PowerShellParse -Path (Join-Path $RepoPath 'SCRIPTS\bootstrap\windows-stages.ps1')
Write-Result -Name 'ps-parse-windows-stages.ps1' -Pass $windowsStagesParse.Pass -Details (("errors=" + @($windowsStagesParse.Errors).Count))

$windowsHelperParse = Test-PowerShellParse -Path (Join-Path $RepoPath 'SCRIPTS\bootstrap\Windows.ps1')
Write-Result -Name 'ps-parse-Windows.ps1' -Pass $windowsHelperParse.Pass -Details (("errors=" + @($windowsHelperParse.Errors).Count))

$bash = $null
try {
    $bash = Get-GitBashPath
}
catch {
    Write-Skip -Name 'bash-syntax' -Details 'Git Bash/bash not available'
}

if ($bash) {
    Push-Location $RepoPath
    try {
        & $bash -n .\run.sh
        Write-Result -Name 'bash-syntax' -Pass ($LASTEXITCODE -eq 0) -Details ("exit=$LASTEXITCODE")
    }
    finally {
        Pop-Location
    }
}

if ($bash) {
    $linuxList = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-linux-list-'
    $listRun = Invoke-BashSnippet -BashPath $bash -RepoPath $linuxList.Repo -HomePath $linuxList.Home -Snippet 'bash ./run.sh list-modes' -WorkGitHost $WorkGitHost
    Write-Result -Name 'bash-list-modes' -Pass ($listRun.ExitCode -eq 0) -Details ("exit=$($listRun.ExitCode)")

    $linuxDoctor = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-linux-doctor-'
    $doctorRun = Invoke-BashSnippet -BashPath $bash -RepoPath $linuxDoctor.Repo -HomePath $linuxDoctor.Home -Snippet 'bash ./run.sh doctor' -WorkGitHost $WorkGitHost
    Write-Result -Name 'bash-doctor' -Pass ($doctorRun.ExitCode -eq 0) -Details ("exit=$($doctorRun.ExitCode)")

    $linuxShared = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-linux-shared-'
    $sharedRun = Invoke-BashSnippet -BashPath $bash -RepoPath $linuxShared.Repo -HomePath $linuxShared.Home -Snippet 'bash ./run.sh shared-config-only' -WorkGitHost $WorkGitHost
    $sharedGitStatus = Get-GitTemplateStatus -RepoPath $linuxShared.Repo
    $sharedPwshProfile = Join-Path $linuxShared.Home '.config\powershell\Microsoft.PowerShell_profile.ps1'
    $linuxSharedOk = ($sharedRun.ExitCode -eq 0 -and $sharedGitStatus.Personal -and $sharedGitStatus.WorkIdentity -and $sharedGitStatus.WorkRules -and (Test-Path $sharedPwshProfile))
    Write-Result -Name 'bash-shared-config-only' -Pass $linuxSharedOk -Details ("exit=$($sharedRun.ExitCode) git=$($sharedGitStatus.Personal -and $sharedGitStatus.WorkIdentity -and $sharedGitStatus.WorkRules) profile=$((Test-Path $sharedPwshProfile))")

    $linuxGit = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-linux-git-'
    $gitRun = Invoke-BashSnippet -BashPath $bash -RepoPath $linuxGit.Repo -HomePath $linuxGit.Home -Snippet 'bash ./run.sh git-only' -WorkGitHost $WorkGitHost
    $gitStatus = Get-GitTemplateStatus -RepoPath $linuxGit.Repo
    $linuxGitOk = ($gitRun.ExitCode -eq 0 -and $gitStatus.Personal -and $gitStatus.WorkIdentity -and $gitStatus.WorkRules -and $gitStatus.HostMatch)
    Write-Result -Name 'bash-git-only' -Pass $linuxGitOk -Details ("exit=$($gitRun.ExitCode) files=$($gitStatus.Personal -and $gitStatus.WorkIdentity -and $gitStatus.WorkRules) host=$($gitStatus.HostMatch)")

    $linuxDotfiles = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-linux-dotfiles-'
    $dotfilesRun = Invoke-BashSnippet -BashPath $bash -RepoPath $linuxDotfiles.Repo -HomePath $linuxDotfiles.Home -Snippet 'bash ./run.sh dotfiles-links-only' -WorkGitHost $WorkGitHost
    $dotfilesBashrc = Join-Path $linuxDotfiles.Home '.bashrc'
    $dotfilesConfig = Join-Path $linuxDotfiles.Home '.config'
    Write-Result -Name 'bash-dotfiles-links-only' -Pass ($dotfilesRun.ExitCode -eq 0 -and (Test-Path $dotfilesBashrc) -and (Test-Path $dotfilesConfig)) -Details ("exit=$($dotfilesRun.ExitCode) links=$((Test-Path $dotfilesBashrc) -and (Test-Path $dotfilesConfig))")

    $linuxPwsh = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-linux-pwsh-'
    $pwshRun = Invoke-BashSnippet -BashPath $bash -RepoPath $linuxPwsh.Repo -HomePath $linuxPwsh.Home -Snippet 'bash ./run.sh powershell-config-only' -WorkGitHost $WorkGitHost
    $pwshProfile = Join-Path $linuxPwsh.Home '.config\powershell\Microsoft.PowerShell_profile.ps1'
    Write-Result -Name 'bash-powershell-config-only' -Pass ($pwshRun.ExitCode -eq 0 -and (Test-Path $pwshProfile)) -Details ("exit=$($pwshRun.ExitCode) profile=$((Test-Path $pwshProfile))")

    $linuxAgent = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-linux-agent-'
    $agentRun = Invoke-BashSnippet -BashPath $bash -RepoPath $linuxAgent.Repo -HomePath $linuxAgent.Home -Snippet 'bash ./run.sh agent-config-only' -WorkGitHost $WorkGitHost
    $agentMcp = Join-Path $linuxAgent.Home '.config\Code - Insiders\User\mcp.json'
    $agentPrompt = Join-Path $linuxAgent.Home '.config\Code - Insiders\User\prompts\code.instructions.md'
    Write-Result -Name 'bash-agent-config-only' -Pass ($agentRun.ExitCode -eq 0 -and (Test-Path $agentMcp) -and (Test-Path $agentPrompt)) -Details ("exit=$($agentRun.ExitCode) assets=$((Test-Path $agentMcp) -and (Test-Path $agentPrompt))")
}
else {
    Write-Skip -Name 'bash-list-modes' -Details 'Git Bash/bash not available'
    Write-Skip -Name 'bash-doctor' -Details 'Git Bash/bash not available'
    Write-Skip -Name 'bash-shared-config-only' -Details 'Git Bash/bash not available'
    Write-Skip -Name 'bash-git-only' -Details 'Git Bash/bash not available'
    Write-Skip -Name 'bash-dotfiles-links-only' -Details 'Git Bash/bash not available'
    Write-Skip -Name 'bash-powershell-config-only' -Details 'Git Bash/bash not available'
    Write-Skip -Name 'bash-agent-config-only' -Details 'Git Bash/bash not available'
}

$windowsList = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-list-'
$winListRun = Invoke-WindowsEntryPoint -RepoPath $windowsList.Repo -HomePath $windowsList.Home -Mode 'list-modes' -WorkGitHost $WorkGitHost
Write-Result -Name 'ps-list-modes' -Pass ($winListRun.ExitCode -eq 0) -Details ("exit=$($winListRun.ExitCode)")

$windowsDoctor = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-doctor-'
$winDoctorRun = Invoke-WindowsEntryPoint -RepoPath $windowsDoctor.Repo -HomePath $windowsDoctor.Home -Mode 'doctor' -WorkGitHost $WorkGitHost
Write-Result -Name 'ps-doctor' -Pass ($winDoctorRun.ExitCode -eq 0) -Details ("exit=$($winDoctorRun.ExitCode)")

$windowsShared = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-shared-'
$winSharedRun = Invoke-WindowsEntryPoint -RepoPath $windowsShared.Repo -HomePath $windowsShared.Home -Mode 'shared-config-only' -WorkGitHost $WorkGitHost
$winSharedGitStatus = Get-GitTemplateStatus -RepoPath $windowsShared.Repo
$winSharedPwsh7Profile = Join-Path $windowsShared.Home 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$winSharedPwsh51Profile = Join-Path $windowsShared.Home 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
$windowsSharedOk = ($winSharedRun.ExitCode -eq 0 -and $winSharedGitStatus.Personal -and $winSharedGitStatus.WorkIdentity -and $winSharedGitStatus.WorkRules -and (Test-Path $winSharedPwsh7Profile) -and (Test-Path $winSharedPwsh51Profile))
Write-Result -Name 'ps-shared-config-only' -Pass $windowsSharedOk -Details ("exit=$($winSharedRun.ExitCode) git=$($winSharedGitStatus.Personal -and $winSharedGitStatus.WorkIdentity -and $winSharedGitStatus.WorkRules) profiles=$((Test-Path $winSharedPwsh7Profile) -and (Test-Path $winSharedPwsh51Profile))")

$windowsGit = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-git-'
$winGitRun = Invoke-WindowsEntryPoint -RepoPath $windowsGit.Repo -HomePath $windowsGit.Home -Mode 'git-only' -WorkGitHost $WorkGitHost
$winGitStatus = Get-GitTemplateStatus -RepoPath $windowsGit.Repo
$windowsGitOk = ($winGitRun.ExitCode -eq 0 -and $winGitStatus.Personal -and $winGitStatus.WorkIdentity -and $winGitStatus.WorkRules -and $winGitStatus.HostMatch)
Write-Result -Name 'ps-git-only' -Pass $windowsGitOk -Details ("exit=$($winGitRun.ExitCode) files=$($winGitStatus.Personal -and $winGitStatus.WorkIdentity -and $winGitStatus.WorkRules) host=$($winGitStatus.HostMatch)")

$windowsTerminal = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-terminal-'
$winTerminalRun = Invoke-WindowsEntryPoint -RepoPath $windowsTerminal.Repo -HomePath $windowsTerminal.Home -Mode 'windows-terminal-only' -WorkGitHost $WorkGitHost
Write-Result -Name 'ps-windows-terminal-only' -Pass ($winTerminalRun.ExitCode -eq 0 -and (Test-Path $winTerminalRun.TerminalSettings)) -Details ("exit=$($winTerminalRun.ExitCode) settings=$((Test-Path $winTerminalRun.TerminalSettings))")

$windowsVSCode = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-vscode-'
$winVSCodeRun = Invoke-WindowsEntryPoint -RepoPath $windowsVSCode.Repo -HomePath $windowsVSCode.Home -Mode 'vscode-config-only' -WorkGitHost $WorkGitHost
Write-Result -Name 'ps-vscode-config-only' -Pass ($winVSCodeRun.ExitCode -eq 0 -and (Test-Path $winVSCodeRun.VSCodeSettings)) -Details ("exit=$($winVSCodeRun.ExitCode) settings=$((Test-Path $winVSCodeRun.VSCodeSettings))")

$windowsPwsh = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-pwsh-'
$winPwshRun = Invoke-WindowsEntryPoint -RepoPath $windowsPwsh.Repo -HomePath $windowsPwsh.Home -Mode 'powershell-config-only' -WorkGitHost $WorkGitHost
$pwsh7Profile = Join-Path $windowsPwsh.Home 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$pwsh51Profile = Join-Path $windowsPwsh.Home 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
Write-Result -Name 'ps-powershell-config-only' -Pass ($winPwshRun.ExitCode -eq 0 -and (Test-Path $pwsh7Profile) -and (Test-Path $pwsh51Profile)) -Details ("exit=$($winPwshRun.ExitCode) profiles=$((Test-Path $pwsh7Profile) -and (Test-Path $pwsh51Profile))")

$windowsAgent = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-agent-'
$winAgentRun = Invoke-WindowsEntryPoint -RepoPath $windowsAgent.Repo -HomePath $windowsAgent.Home -Mode 'agent-config-only' -WorkGitHost $WorkGitHost
$winAgentMcp = Join-Path $windowsAgent.Home 'AppData\Roaming\Code - Insiders\User\mcp.json'
$winAgentPrompt = Join-Path $windowsAgent.Home 'AppData\Roaming\Code - Insiders\User\prompts\code.instructions.md'
Write-Result -Name 'ps-agent-config-only' -Pass ($winAgentRun.ExitCode -eq 0 -and (Test-Path $winAgentMcp) -and (Test-Path $winAgentPrompt)) -Details ("exit=$($winAgentRun.ExitCode) assets=$((Test-Path $winAgentMcp) -and (Test-Path $winAgentPrompt))")

$windowsConfig = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-config-'
$winConfigRun = Invoke-WindowsEntryPoint -RepoPath $windowsConfig.Repo -HomePath $windowsConfig.Home -Mode 'windows-config-only' -WorkGitHost $WorkGitHost
$winConfigGitStatus = Get-GitTemplateStatus -RepoPath $windowsConfig.Repo
$winConfigPwsh7Profile = Join-Path $windowsConfig.Home 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$winConfigPwsh51Profile = Join-Path $windowsConfig.Home 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
$winConfigMcp = Join-Path $windowsConfig.Home 'AppData\Roaming\Code - Insiders\User\mcp.json'
$windowsConfigOk = ($winConfigRun.ExitCode -eq 0 -and $winConfigGitStatus.Personal -and $winConfigGitStatus.WorkIdentity -and $winConfigGitStatus.WorkRules -and (Test-Path $winConfigPwsh7Profile) -and (Test-Path $winConfigPwsh51Profile) -and (Test-Path $winConfigRun.TerminalSettings) -and (Test-Path $winConfigRun.VSCodeSettings) -and (Test-Path $winConfigMcp))
Write-Result -Name 'ps-windows-config-only' -Pass $windowsConfigOk -Details ("exit=$($winConfigRun.ExitCode) config=$windowsConfigOk")

$windowsShell = New-TempRepoCopy -SourceRepo $RepoPath -Tag 'cfg-win-shell-'
$winShellRun = Invoke-WindowsEntryPoint -RepoPath $windowsShell.Repo -HomePath $windowsShell.Home -Mode 'windows-shell' -WorkGitHost $WorkGitHost
$winShellGitStatus = Get-GitTemplateStatus -RepoPath $windowsShell.Repo
$winShellPwsh7Profile = Join-Path $windowsShell.Home 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$winShellPwsh51Profile = Join-Path $windowsShell.Home 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
$winShellMcp = Join-Path $windowsShell.Home 'AppData\Roaming\Code - Insiders\User\mcp.json'
$windowsShellOk = ($winShellRun.ExitCode -eq 0 -and $winShellGitStatus.Personal -and $winShellGitStatus.WorkIdentity -and $winShellGitStatus.WorkRules -and (Test-Path $winShellPwsh7Profile) -and (Test-Path $winShellPwsh51Profile) -and (Test-Path $winShellRun.TerminalSettings) -and (Test-Path $winShellRun.VSCodeSettings) -and (Test-Path $winShellMcp))
Write-Result -Name 'ps-windows-shell' -Pass $windowsShellOk -Details ("exit=$($winShellRun.ExitCode) shell=$windowsShellOk")

$selfPath = $MyInvocation.MyCommand.Path
$files = Get-ChildItem $RepoPath -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
    $_.FullName -notmatch '[\\/]\.git([\\/]|$)' -and $_.FullName -ne $selfPath
}

$sensitivePatterns = @(
    ('git' + '.internal.ru.com'),
    ('git_' + 'internal_' + 'ru_' + 'com'),
    ('seval' + 'verde'),
    ('svg' + '153' + '@g' + 'mail.com'),
    ('Sergio' + ' Valverde'),
    ('git@github.com:' + 'svg' + '153/' + 'configLinux.git')
)

$legacyPatterns = @(
    ('templates/' + 'linux'),
    ('templates/' + 'posh')
)

$sensitive = Select-String -Path $files.FullName -SimpleMatch -Pattern $sensitivePatterns -ErrorAction SilentlyContinue
$legacy = Select-String -Path $files.FullName -SimpleMatch -Pattern $legacyPatterns -ErrorAction SilentlyContinue

Write-Result -Name 'sensitive-scan' -Pass (@($sensitive).Count -eq 0) -Details ("count=" + @($sensitive).Count)
Write-Result -Name 'legacy-template-ref-scan' -Pass (@($legacy).Count -eq 0) -Details ("count=" + @($legacy).Count)