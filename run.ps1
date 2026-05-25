param(
    [ValidateSet('help','list-modes','doctor','git-config-only','git-only','powershell-config-only','agent-config-only','windows-terminal-only','vscode-config-only','shared-config-only','windows-config-only','windows-tools','windows-modules','windows-shell','windows-full')]
    [string]$Mode = 'help',
    [string]$ConfigPath = $PSScriptRoot,
    [string]$HomePath = $HOME,
    [string]$WorkGitHost = '<WORK_GIT_HOST>',
    [string]$WindowsTerminalSettingsPath = (Join-Path $HOME 'AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    [string]$VSCodeSettingsPath = (Join-Path $HOME 'AppData\Roaming\Code - Insiders\User\settings.json'),
    [switch]$Force,
    [switch]$Yes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'SCRIPTS\bootstrap\Windows.ps1')
. (Join-Path $PSScriptRoot 'SCRIPTS\bootstrap\windows-stages.ps1')

if ($Mode -eq 'windows-full' -and -not $Yes) {
    Write-ConfigLog -Level warn -Message 'windows-full installs tools and rewires local config.'
    Write-Host 'Re-run with: .\run.ps1 windows-full -Yes'
    exit 1
}

switch ($Mode) {
    'help' {
        Show-ConfigLinuxWindowsHelp
        break
    }
    'list-modes' {
        Show-ConfigLinuxWindowsHelp
        break
    }
    'doctor' {
        Show-ConfigLinuxWindowsDoctor -ConfigPath $ConfigPath -HomePath $HomePath -WindowsTerminalSettingsPath $WindowsTerminalSettingsPath -VSCodeSettingsPath $VSCodeSettingsPath
        break
    }
    'git-config-only' {
        Invoke-WindowsStageBase -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -Force:$Force
        break
    }
    'git-only' {
        Invoke-WindowsStageGit -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost
        break
    }
    'powershell-config-only' {
        Invoke-WindowsStagePowerShell -ConfigPath $ConfigPath -HomePath $HomePath -Force:$Force
        break
    }
    'agent-config-only' {
        Invoke-WindowsStageAgent -ConfigPath $ConfigPath -HomePath $HomePath -Force:$Force
        break
    }
    'windows-terminal-only' {
        Invoke-WindowsStageTerminal -ConfigPath $ConfigPath -HomePath $HomePath -WindowsTerminalSettingsPath $WindowsTerminalSettingsPath -Force:$Force
        break
    }
    'vscode-config-only' {
        Invoke-WindowsStageVSCode -ConfigPath $ConfigPath -HomePath $HomePath -VSCodeSettingsPath $VSCodeSettingsPath -Force:$Force
        break
    }
    'shared-config-only' {
        Invoke-WindowsStageBase -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -Force:$Force
        break
    }
    'windows-config-only' {
        Invoke-WindowsStageConfig -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -WindowsTerminalSettingsPath $WindowsTerminalSettingsPath -VSCodeSettingsPath $VSCodeSettingsPath -Force:$Force
        break
    }
    'windows-tools' {
        Invoke-WindowsStageTools -HomePath $HomePath
        break
    }
    'windows-modules' {
        Invoke-WindowsStageModules
        break
    }
    'windows-shell' {
        Invoke-WindowsStageShell -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -WindowsTerminalSettingsPath $WindowsTerminalSettingsPath -VSCodeSettingsPath $VSCodeSettingsPath -Force:$Force
        break
    }
    'windows-full' {
        Invoke-WindowsFullBootstrap -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -WindowsTerminalSettingsPath $WindowsTerminalSettingsPath -VSCodeSettingsPath $VSCodeSettingsPath -Force:$Force
        break
    }
}