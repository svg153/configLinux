Set-StrictMode -Version Latest

function Write-ConfigLog {
    param(
        [Parameter(Mandatory)] [string]$Level,
        [Parameter(Mandatory)] [string]$Message
    )

    $color = switch ($Level.ToLowerInvariant()) {
        'info' { 'Green' }
        'warn' { 'Yellow' }
        'warning' { 'Yellow' }
        'error' { 'Red' }
        default { 'Gray' }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Show-ConfigLinuxWindowsHelp {
    @'
Usage:
  .\run.ps1 help
    .\run.ps1 list-modes
    .\run.ps1 doctor
  .\run.ps1 git-config-only
  .\run.ps1 git-only
  .\run.ps1 powershell-config-only
    .\run.ps1 agent-config-only
  .\run.ps1 windows-terminal-only
  .\run.ps1 vscode-config-only
  .\run.ps1 shared-config-only
  .\run.ps1 windows-config-only
  .\run.ps1 windows-tools
  .\run.ps1 windows-modules
  .\run.ps1 windows-shell
  .\run.ps1 windows-full -Yes

Modes:
    list-modes             Show the available modes.
    doctor                 Print a non-destructive environment/config report.
  git-config-only        Backward-compatible alias for the shared base config flow.
  git-only               Refresh only Git config links and ignored identity templates.
  powershell-config-only Refresh only PowerShell / Oh My Posh templates.
    agent-config-only      Refresh VS Code MCP/prompts agent templates only.
  windows-terminal-only  Copy the Windows Terminal template when missing (or with -Force).
  vscode-config-only     Copy the VS Code terminal template when missing (or with -Force).
  shared-config-only     Refresh the cross-platform base config (Git + PowerShell templates).
  windows-config-only    Refresh the shared base config plus Windows Terminal and VS Code templates.
  windows-tools          Install/update the portable Windows CLI toolchain in ~/.local/bin.
  windows-modules        Install/update PowerShell modules (PSReadLine, posh-git, Terminal-Icons).
  windows-shell          Refresh shared config plus terminal/editor shell integration.
  windows-full           Run the full Windows developer bootstrap.

Notes:
  - The shared templates live under templates\git, templates\powershell, and templates\windows.
  - Existing PowerShell, VS Code, and Windows Terminal files are preserved unless you pass -Force.
'@ | Write-Host
}

function Show-ConfigLinuxWindowsDoctor {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WindowsTerminalSettingsPath,
        [Parameter(Mandatory)] [string]$VSCodeSettingsPath
    )

    Write-ConfigLog -Level info -Message 'configLinux doctor'
    Write-Host "config_path=$ConfigPath"
    Write-Host "home_path=$HomePath"

    $commands = 'git','pwsh','powershell','gh','oh-my-posh','rg','fd','bat','fzf','delta','code','code-insiders'
    foreach ($command in $commands) {
        if (Get-Command $command -ErrorAction SilentlyContinue) {
            Write-Host "cmd:$command=present"
        } else {
            Write-Host "cmd:$command=missing"
        }
    }

    $paths = @(
        (Join-Path $ConfigPath '.gitconfig'),
        (Join-Path $ConfigPath '.gitconfig.d\default.gitconfig'),
        (Join-Path $ConfigPath 'templates\git\gitconfig.d\personal-mail.gitconfig'),
        (Join-Path $ConfigPath 'templates\git\gitconfig.d\work\work.gitconfig'),
        (Join-Path $ConfigPath 'templates\powershell\profile.ps1'),
        (Join-Path $ConfigPath 'templates\powershell\Copilot.DevProfile.ps1'),
        (Join-Path $ConfigPath 'templates\windows\terminal\settings.json'),
        (Join-Path $ConfigPath 'templates\vscode\mcp.jsonc'),
        (Join-Path $ConfigPath 'templates\vscode\prompts\code.instructions.md'),
        (Join-Path $HomePath '.configLinux'),
        (Join-Path $HomePath '.gitconfig'),
        (Join-Path $HomePath '.gitconfig.d'),
        (Join-Path $HomePath '.poshthemes\jandedobbeleer.omp.json'),
        (Join-Path $HomePath 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path $HomePath 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path $HomePath 'AppData\Roaming\Code - Insiders\User\mcp.json'),
        (Join-Path $HomePath 'AppData\Roaming\Code - Insiders\User\prompts\code.instructions.md'),
        $WindowsTerminalSettingsPath,
        $VSCodeSettingsPath
    )

    foreach ($path in $paths) {
        if (Test-Path -LiteralPath $path) {
            Write-Host "path:$path=present"
        } else {
            Write-Host "path:$path=missing"
        }
    }
}

function Backup-ExistingPath {
    param([Parameter(Mandatory)] [string]$Path)

    $backup = "$Path.backup.$([DateTime]::Now.ToString('yyyyMMddHHmmss'))"
    Move-Item -LiteralPath $Path -Destination $backup -Force
    Write-ConfigLog -Level warn -Message "Moved existing $Path to $backup"
}

function Ensure-ParentDirectory {
    param([Parameter(Mandatory)] [string]$Path)

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Ensure-PathLink {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Target,
        [switch]$Directory
    )

    Ensure-ParentDirectory -Path $Target

    if (Test-Path -LiteralPath $Target) {
        $existing = Get-Item -LiteralPath $Target -Force
        if ($existing.LinkType -and $existing.Target) {
            $targets = @($existing.Target | ForEach-Object { $_.ToString() })
            if ($targets -contains $Source) {
                Write-ConfigLog -Level info -Message "Link already in place: $Target"
                return
            }
        }

        if (-not $Directory -and -not $existing.PSIsContainer -and (Test-Path -LiteralPath $Source)) {
            $sourceHash = (Get-FileHash -LiteralPath $Source).Hash
            $targetHash = (Get-FileHash -LiteralPath $Target).Hash
            if ($sourceHash -eq $targetHash) {
                Write-ConfigLog -Level info -Message "File already synchronized: $Target"
                return
            }
        }

        Backup-ExistingPath -Path $Target
    }

    try {
        if ($Directory) {
            New-Item -ItemType Junction -Path $Target -Target $Source -Force | Out-Null
        } else {
            New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
        }
        Write-ConfigLog -Level info -Message "Linked $Target -> $Source"
    } catch {
        if ($Directory) {
            Copy-Item -Path $Source -Destination $Target -Recurse -Force
        } else {
            Copy-Item -Path $Source -Destination $Target -Force
        }
        Write-ConfigLog -Level warn -Message "Link creation failed for $Target; copied content instead."
    }
}

function Copy-IfMissingOrForced {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination,
        [switch]$Force
    )

    Ensure-ParentDirectory -Path $Destination

    if ((Test-Path -LiteralPath $Destination) -and -not $Force) {
        Write-ConfigLog -Level info -Message "Keeping existing $Destination"
        return
    }

    Copy-Item -Path $Source -Destination $Destination -Force
    Write-ConfigLog -Level info -Message "Copied $Source -> $Destination"
}

function Render-Template {
    param(
        [Parameter(Mandatory)] [string]$TemplatePath,
        [hashtable]$Replacements
    )

    $content = Get-Content -LiteralPath $TemplatePath -Raw
    if ($Replacements) {
        foreach ($key in $Replacements.Keys) {
            $content = $content.Replace($key, [string]$Replacements[$key])
        }
    }
    return $content
}

function Write-RenderedTemplate {
    param(
        [Parameter(Mandatory)] [string]$TemplatePath,
        [Parameter(Mandatory)] [string]$DestinationPath,
        [hashtable]$Replacements,
        [switch]$Force
    )

    Ensure-ParentDirectory -Path $DestinationPath
    if ((Test-Path -LiteralPath $DestinationPath) -and -not $Force) {
        Write-ConfigLog -Level info -Message "Keeping existing $DestinationPath"
        return
    }

    $content = Render-Template -TemplatePath $TemplatePath -Replacements $Replacements
    Set-Content -Path $DestinationPath -Value $content -Encoding UTF8
    Write-ConfigLog -Level info -Message "Rendered $TemplatePath -> $DestinationPath"
}

function Write-FileFromTemplateIfMissing {
    param(
        [Parameter(Mandatory)] [string]$TemplatePath,
        [Parameter(Mandatory)] [string]$DestinationPath,
        [string]$WorkGitHost = '<WORK_GIT_HOST>'
    )

    Ensure-ParentDirectory -Path $DestinationPath
    if (Test-Path -LiteralPath $DestinationPath) {
        Write-ConfigLog -Level info -Message "Keeping existing $DestinationPath"
        return
    }

    $content = Get-Content -LiteralPath $TemplatePath -Raw
    $content = $content.Replace('<WORK_GIT_HOST>', $WorkGitHost)
    Set-Content -Path $DestinationPath -Value $content -Encoding UTF8
    Write-ConfigLog -Level info -Message "Created $DestinationPath from $TemplatePath"
}

function Get-ConfigLinuxLocalBinPath {
    param([Parameter(Mandatory)] [string]$HomePath)
    return (Join-Path $HomePath '.local\bin')
}

function Get-ConfigLinuxToolInstallRoot {
    param([Parameter(Mandatory)] [string]$HomePath)
    return (Join-Path $HomePath '.local\opt')
}

function Add-ConfigLinuxPathEntry {
    param([Parameter(Mandatory)] [string]$PathEntry)

    if (-not (Test-Path -LiteralPath $PathEntry)) {
        New-Item -ItemType Directory -Path $PathEntry -Force | Out-Null
    }

    if ($env:Path -notlike "*$PathEntry*") {
        $env:Path = "$PathEntry;$env:Path"
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        [Environment]::SetEnvironmentVariable('Path', $PathEntry, 'User')
    } elseif ($userPath -notlike "*$PathEntry*") {
        [Environment]::SetEnvironmentVariable('Path', "$PathEntry;$userPath", 'User')
    }
}

function Get-GitHubReleaseAssetUrl {
    param(
        [Parameter(Mandatory)] [string]$Repository,
        [Parameter(Mandatory)] [string]$AssetPattern
    )

    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest" -Headers @{ 'User-Agent' = 'configLinux-bootstrap' }
    $asset = $release.assets | Where-Object { $_.name -match $AssetPattern } | Select-Object -First 1
    if (-not $asset) {
        throw "Asset pattern '$AssetPattern' not found for $Repository"
    }
    return $asset.browser_download_url
}

function Download-ConfigLinuxFile {
    param(
        [Parameter(Mandatory)] [string]$Uri,
        [Parameter(Mandatory)] [string]$DestinationPath
    )

    Ensure-ParentDirectory -Path $DestinationPath
    Invoke-WebRequest -Uri $Uri -OutFile $DestinationPath
}

function Install-GitHubPortableArchiveTool {
    param(
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$Repository,
        [Parameter(Mandatory)] [string]$AssetPattern,
        [Parameter(Mandatory)] [string]$ExecutablePattern,
        [Parameter(Mandatory)] [string]$LookupCommand,
        [Parameter(Mandatory)] [string]$Subdirectory
    )

    if (Get-Command $LookupCommand -ErrorAction SilentlyContinue) {
        Write-ConfigLog -Level info -Message "$LookupCommand already available"
        return
    }

    $installRoot = Get-ConfigLinuxToolInstallRoot -HomePath $HomePath
    $installDir = Join-Path $installRoot $Subdirectory
    $downloadDir = Join-Path $env:TEMP ('configlinux-' + $Subdirectory + '-' + [guid]::NewGuid().ToString('N'))
    $archivePath = Join-Path $downloadDir 'tool.zip'
    $extractDir = Join-Path $downloadDir 'extract'

    if (Test-Path -LiteralPath $installDir) {
        Remove-Item -LiteralPath $installDir -Recurse -Force
    }

    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
    Download-ConfigLinuxFile -Uri (Get-GitHubReleaseAssetUrl -Repository $Repository -AssetPattern $AssetPattern) -DestinationPath $archivePath
    Expand-Archive -Path $archivePath -DestinationPath $extractDir -Force

    $exe = Get-ChildItem -Path $extractDir -Recurse -File | Where-Object { $_.FullName -match $ExecutablePattern } | Select-Object -First 1
    if (-not $exe) {
        throw "Could not find executable matching '$ExecutablePattern' for $Repository"
    }

    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Copy-Item -Path (Join-Path $extractDir '*') -Destination $installDir -Recurse -Force

    $installedExe = Get-ChildItem -Path $installDir -Recurse -File | Where-Object { $_.FullName -match $ExecutablePattern } | Select-Object -First 1
    Add-ConfigLinuxPathEntry -PathEntry $installedExe.Directory.FullName
    Write-ConfigLog -Level info -Message "Installed $LookupCommand from $Repository"
}

function Install-GitHubPortableSingleFile {
    param(
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$Repository,
        [Parameter(Mandatory)] [string]$AssetPattern,
        [Parameter(Mandatory)] [string]$CommandName,
        [Parameter(Mandatory)] [string]$LookupCommand,
        [Parameter(Mandatory)] [string]$Subdirectory
    )

    if (Get-Command $LookupCommand -ErrorAction SilentlyContinue) {
        Write-ConfigLog -Level info -Message "$LookupCommand already available"
        return
    }

    $binDir = Get-ConfigLinuxLocalBinPath -HomePath $HomePath
    $installRoot = Get-ConfigLinuxToolInstallRoot -HomePath $HomePath
    $installDir = Join-Path $installRoot $Subdirectory
    Add-ConfigLinuxPathEntry -PathEntry $binDir

    if (-not (Test-Path -LiteralPath $installDir)) {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    }

    $installTarget = Join-Path $installDir $CommandName
    Download-ConfigLinuxFile -Uri (Get-GitHubReleaseAssetUrl -Repository $Repository -AssetPattern $AssetPattern) -DestinationPath $installTarget
    Copy-Item -Path $installTarget -Destination (Join-Path $binDir $CommandName) -Force
    Write-ConfigLog -Level info -Message "Installed $LookupCommand from $Repository"
}

function Install-WindowsPortableGit {
    param([Parameter(Mandatory)] [string]$HomePath)

    Install-GitHubPortableArchiveTool -HomePath $HomePath -Repository 'git-for-windows/git' -AssetPattern 'MinGit-.*-64-bit\.zip$' -ExecutablePattern '[\\/]cmd[\\/]git\.exe$' -LookupCommand 'git' -Subdirectory 'git'
}

function Install-WindowsPortablePowerShell {
    param([Parameter(Mandatory)] [string]$HomePath)

    Install-GitHubPortableArchiveTool -HomePath $HomePath -Repository 'PowerShell/PowerShell' -AssetPattern 'PowerShell-.*-win-x64\.zip$' -ExecutablePattern '[\\/]pwsh\.exe$' -LookupCommand 'pwsh' -Subdirectory 'pwsh'
}

function Install-WindowsPortableGh {
    param([Parameter(Mandatory)] [string]$HomePath)

    Install-GitHubPortableArchiveTool -HomePath $HomePath -Repository 'cli/cli' -AssetPattern 'gh_.*_windows_amd64\.zip$' -ExecutablePattern '[\\/]bin[\\/]gh\.exe$' -LookupCommand 'gh' -Subdirectory 'gh'
}

function Install-WindowsPortableOhMyPosh {
    param([Parameter(Mandatory)] [string]$HomePath)

    Install-GitHubPortableSingleFile -HomePath $HomePath -Repository 'JanDeDobbeleer/oh-my-posh' -AssetPattern 'posh-windows-amd64\.exe$' -CommandName 'oh-my-posh.exe' -LookupCommand 'oh-my-posh' -Subdirectory 'oh-my-posh'
}

function Install-WindowsPortableCliSet {
    param([Parameter(Mandatory)] [string]$HomePath)

    $tools = @(
        @{ Repo = 'BurntSushi/ripgrep'; Asset = 'ripgrep-.*-x86_64-pc-windows-msvc\.zip$'; Exe = '[\\/]rg\.exe$'; Lookup = 'rg'; Subdir = 'rg' },
        @{ Repo = 'sharkdp/fd'; Asset = 'fd-.*-x86_64-pc-windows-msvc\.zip$'; Exe = '[\\/]fd\.exe$'; Lookup = 'fd'; Subdir = 'fd' },
        @{ Repo = 'sharkdp/bat'; Asset = 'bat-.*-x86_64-pc-windows-msvc\.zip$'; Exe = '[\\/]bat\.exe$'; Lookup = 'bat'; Subdir = 'bat' },
        @{ Repo = 'junegunn/fzf'; Asset = 'fzf-.*-windows_amd64\.zip$'; Exe = '[\\/]fzf\.exe$'; Lookup = 'fzf'; Subdir = 'fzf' },
        @{ Repo = 'dandavison/delta'; Asset = 'delta-.*-x86_64-pc-windows-msvc\.zip$'; Exe = '[\\/]delta\.exe$'; Lookup = 'delta'; Subdir = 'delta' }
    )

    foreach ($tool in $tools) {
        Install-GitHubPortableArchiveTool -HomePath $HomePath -Repository $tool.Repo -AssetPattern $tool.Asset -ExecutablePattern $tool.Exe -LookupCommand $tool.Lookup -Subdirectory $tool.Subdir
    }
}

function Install-WindowsPowerShellModules {
    $modules = 'PSReadLine','posh-git','Terminal-Icons'
    try {
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    } catch {
    }

    foreach ($module in $modules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-ConfigLog -Level info -Message "$module already available"
            continue
        }

        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
        Write-ConfigLog -Level info -Message "Installed PowerShell module $module"
    }
}

function Install-WindowsDeveloperToolchain {
    param([Parameter(Mandatory)] [string]$HomePath)

    Install-WindowsPortableGit -HomePath $HomePath
    Install-WindowsPortablePowerShell -HomePath $HomePath
    Install-WindowsPortableGh -HomePath $HomePath
    Install-WindowsPortableOhMyPosh -HomePath $HomePath
    Install-WindowsPortableCliSet -HomePath $HomePath
}

function Resolve-WindowsPwshExecutablePath {
    param([Parameter(Mandatory)] [string]$HomePath)

    $command = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $installRoot = Get-ConfigLinuxToolInstallRoot -HomePath $HomePath
    if (Test-Path -LiteralPath $installRoot) {
        $portable = Get-ChildItem -Path $installRoot -Recurse -File -Filter 'pwsh.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($portable) {
            return $portable.FullName
        }
    }

    return 'pwsh.exe'
}

function Get-JsonEscapedPath {
    param([Parameter(Mandatory)] [string]$Path)
    return ($Path -replace '\\', '\\\\')
}

function Ensure-WindowsGitIdentityTemplates {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$WorkGitHost
    )

    $gitConfigDir = Join-Path $ConfigPath '.gitconfig.d'
    $workDir = Join-Path $gitConfigDir 'work'
    $personalPath = Join-Path $gitConfigDir 'personal-mail.gitconfig'
    $workIdentityPath = Join-Path $workDir 'work-company.gitconfig'
    $workRulesPath = Join-Path $workDir 'work.gitconfig'
    $templateDir = Join-Path $ConfigPath 'templates\git\gitconfig.d'

    New-Item -ItemType Directory -Path $workDir -Force | Out-Null

    Write-FileFromTemplateIfMissing -TemplatePath (Join-Path $templateDir 'personal-mail.gitconfig') -DestinationPath $personalPath -WorkGitHost $WorkGitHost
    Write-FileFromTemplateIfMissing -TemplatePath (Join-Path $templateDir 'work\work-company.gitconfig') -DestinationPath $workIdentityPath -WorkGitHost $WorkGitHost
    Write-FileFromTemplateIfMissing -TemplatePath (Join-Path $templateDir 'work\work.gitconfig') -DestinationPath $workRulesPath -WorkGitHost $WorkGitHost
}

function Install-WindowsGitConfig {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WorkGitHost
    )

    Ensure-WindowsGitIdentityTemplates -ConfigPath $ConfigPath -WorkGitHost $WorkGitHost

    Ensure-PathLink -Source $ConfigPath -Target (Join-Path $HomePath '.configLinux') -Directory
    Ensure-PathLink -Source (Join-Path $ConfigPath '.gitconfig') -Target (Join-Path $HomePath '.gitconfig')
    Ensure-PathLink -Source (Join-Path $ConfigPath '.gitconfig.d') -Target (Join-Path $HomePath '.gitconfig.d') -Directory
    Ensure-PathLink -Source (Join-Path $ConfigPath '.git-template') -Target (Join-Path $HomePath '.git-template') -Directory

    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        & $git.Source config --global init.templateDir '~/.git-template' | Out-Null
    } else {
        Write-ConfigLog -Level warn -Message 'git command not found; skipped init.templateDir update.'
    }
}

function Install-WindowsPowerShellTemplates {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [switch]$Force
    )

    $profileTemplate = Join-Path $ConfigPath 'templates\powershell\profile.ps1'
    $themeTemplate = Join-Path $ConfigPath 'templates\powershell\themes\jandedobbeleer.omp.json'

    Copy-IfMissingOrForced -Source $themeTemplate -Destination (Join-Path $HomePath '.poshthemes\jandedobbeleer.omp.json') -Force:$Force
    Copy-IfMissingOrForced -Source $profileTemplate -Destination (Join-Path $HomePath 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1') -Force:$Force
    Copy-IfMissingOrForced -Source $profileTemplate -Destination (Join-Path $HomePath 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1') -Force:$Force
}

function Install-WindowsTerminalTemplate {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$SettingsPath,
        [switch]$Force
    )

    $pwshPath = Get-JsonEscapedPath -Path (Resolve-WindowsPwshExecutablePath -HomePath $HomePath)
    Write-RenderedTemplate -TemplatePath (Join-Path $ConfigPath 'templates\windows\terminal\settings.json') -DestinationPath $SettingsPath -Replacements @{ '<PWSH_EXE>' = $pwshPath } -Force:$Force
}

function Install-WindowsVSCodeTemplate {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$SettingsPath,
        [switch]$Force
    )

    $pwshPath = Get-JsonEscapedPath -Path (Resolve-WindowsPwshExecutablePath -HomePath $HomePath)
    Write-RenderedTemplate -TemplatePath (Join-Path $ConfigPath 'templates\windows\vscode\settings.json') -DestinationPath $SettingsPath -Replacements @{ '<PWSH_EXE>' = $pwshPath } -Force:$Force
}

function Install-WindowsVSCodeAgentTemplates {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [switch]$Force
    )

    $userPath = Join-Path $HomePath 'AppData\Roaming\Code - Insiders\User'
    $promptsPath = Join-Path $userPath 'prompts'
    $templateRoot = Join-Path $ConfigPath 'templates\vscode'

    Copy-IfMissingOrForced -Source (Join-Path $templateRoot 'mcp.jsonc') -Destination (Join-Path $userPath 'mcp.json') -Force:$Force
    Copy-IfMissingOrForced -Source (Join-Path $templateRoot 'prompts\code.instructions.md') -Destination (Join-Path $promptsPath 'code.instructions.md') -Force:$Force
    Copy-IfMissingOrForced -Source (Join-Path $templateRoot 'prompts\pr-fix.prompt.md') -Destination (Join-Path $promptsPath 'pr-fix.prompt.md') -Force:$Force
    Copy-IfMissingOrForced -Source (Join-Path $templateRoot 'prompts\test-agent.agent.md') -Destination (Join-Path $promptsPath 'test-agent.agent.md') -Force:$Force
    Copy-IfMissingOrForced -Source (Join-Path $templateRoot 'prompts\to-pr.prompt.md') -Destination (Join-Path $promptsPath 'to-pr.prompt.md') -Force:$Force
}

function Install-WindowsSharedConfig {
    param(
        [Parameter(Mandatory)] [string]$ConfigPath,
        [Parameter(Mandatory)] [string]$HomePath,
        [Parameter(Mandatory)] [string]$WorkGitHost,
        [switch]$Force
    )

    Install-WindowsGitConfig -ConfigPath $ConfigPath -HomePath $HomePath -WorkGitHost $WorkGitHost
    Install-WindowsPowerShellTemplates -ConfigPath $ConfigPath -HomePath $HomePath -Force:$Force
}