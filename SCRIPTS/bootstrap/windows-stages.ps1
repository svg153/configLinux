Set-StrictMode -Version Latest

function Invoke-WindowsStageBase {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WorkGitHost,
        [switch]$Force
    )

    Install-WindowsSharedConfig -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -Force:$Force
}

function Invoke-WindowsStageGit {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WorkGitHost
    )

    Install-WindowsGitConfig -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost
}

function Invoke-WindowsStagePowerShell {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [switch]$Force
    )

    Install-WindowsPowerShellTemplates -ConfigPath $ConfigPath -HomePath $HomePath -Force:$Force
}

function Invoke-WindowsStageAgent {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [switch]$Force
    )

    Install-WindowsVSCodeAgentTemplates -ConfigPath $ConfigPath -HomePath $HomePath -Force:$Force
}

function Invoke-WindowsStageTerminal {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WindowsTerminalSettingsPath,
        [switch]$Force
    )

    Install-WindowsTerminalTemplate -ConfigPath $ConfigPath -HomePath $HomePath -SettingsPath $WindowsTerminalSettingsPath -Force:$Force
}

function Invoke-WindowsStageVSCode {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$VSCodeSettingsPath,
        [switch]$Force
    )

    Install-WindowsVSCodeTemplate -ConfigPath $ConfigPath -HomePath $HomePath -SettingsPath $VSCodeSettingsPath -Force:$Force
}

function Invoke-WindowsStageConfig {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WorkGitHost,
        [Parameter(Mandatory)] [string]$WindowsTerminalSettingsPath,
        [Parameter(Mandatory)] [string]$VSCodeSettingsPath,
        [switch]$Force
    )

    Invoke-WindowsStageBase -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -Force:$Force
    Invoke-WindowsStageTerminal -ConfigPath $ConfigPath -HomePath $HomePath -WindowsTerminalSettingsPath $WindowsTerminalSettingsPath -Force:$Force
    Invoke-WindowsStageVSCode -ConfigPath $ConfigPath -HomePath $HomePath -VSCodeSettingsPath $VSCodeSettingsPath -Force:$Force
    Invoke-WindowsStageAgent -ConfigPath $ConfigPath -HomePath $HomePath -Force:$Force
}

function Invoke-WindowsStageTools {
    param([Parameter(Mandatory)] [string]$HomePath)

    Install-WindowsDeveloperToolchain -HomePath $HomePath
}

function Invoke-WindowsStageModules {
    Install-WindowsPowerShellModules
}

function Invoke-WindowsStageShell {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WorkGitHost,
        [Parameter(Mandatory)] [string]$WindowsTerminalSettingsPath,
        [Parameter(Mandatory)] [string]$VSCodeSettingsPath,
        [switch]$Force
    )

    Invoke-WindowsStageConfig -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -WindowsTerminalSettingsPath $WindowsTerminalSettingsPath -VSCodeSettingsPath $VSCodeSettingsPath -Force:$Force
}

function Invoke-WindowsFullBootstrap {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WorkGitHost,
        [Parameter(Mandatory)] [string]$WindowsTerminalSettingsPath,
        [Parameter(Mandatory)] [string]$VSCodeSettingsPath,
        [switch]$Force
    )

    Invoke-WindowsStageTools -HomePath $HomePath
    Invoke-WindowsStageModules
    Invoke-WindowsStageShell -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost -WindowsTerminalSettingsPath $WindowsTerminalSettingsPath -VSCodeSettingsPath $VSCodeSettingsPath -Force:$Force
}