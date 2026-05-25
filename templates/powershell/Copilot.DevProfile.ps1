$ErrorActionPreference = 'SilentlyContinue'

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

$localBin = Join-Path $HOME '.local/bin'
if (Test-Path $localBin -and ($env:Path -notlike "*$localBin*")) {
    $env:Path = "$localBin;$env:Path"
}

function Set-ConfigLinuxAlias {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$Value
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Set-Alias -Name $Name -Value $Value -Scope Global
    }
}

function Invoke-ConfigLinuxTouch {
    param([Parameter(Mandatory)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        (Get-Item -LiteralPath $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
}

function Invoke-ConfigLinuxMkcd {
    param([Parameter(Mandatory)][string]$Path)

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location -Path $Path
}

function Invoke-ConfigLinuxReloadProfile {
    if ($PROFILE -and (Test-Path -LiteralPath $PROFILE)) {
        . $PROFILE
    }
}

function Invoke-ConfigLinuxWhich {
    param([Parameter(Mandatory, ValueFromRemainingArguments = $true)][string[]]$Name)

    Get-Command @Name | Select-Object Name, CommandType, Source
}

function Enable-ConfigLinuxPSReadLine {
    if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
        return
    }

    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -EditMode Windows -BellStyle None -HistoryNoDuplicates -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Key Tab -Function Complete -ErrorAction SilentlyContinue
}

Enable-ConfigLinuxPSReadLine

if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git -ErrorAction SilentlyContinue
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}

$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
$theme = Join-Path $HOME '.poshthemes/jandedobbeleer.omp.json'
if ($omp -and (Test-Path -LiteralPath $theme)) {
    (& $omp.Source init pwsh --config $theme) -join [Environment]::NewLine | Invoke-Expression
}

if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        (& gh completion -s powershell) -join [Environment]::NewLine | Invoke-Expression
    } catch {
    }
}

Set-ConfigLinuxAlias -Name l -Value Get-ChildItem
Set-ConfigLinuxAlias -Name ll -Value Get-ChildItem
Set-ConfigLinuxAlias -Name la -Value Get-ChildItem

function ll {
    Get-ChildItem -Force
}

function la {
    Get-ChildItem -Force
}

Set-Alias -Name touch -Value Invoke-ConfigLinuxTouch -Scope Global
Set-Alias -Name mkcd -Value Invoke-ConfigLinuxMkcd -Scope Global
Set-Alias -Name reload-profile -Value Invoke-ConfigLinuxReloadProfile -Scope Global
Set-Alias -Name which -Value Invoke-ConfigLinuxWhich -Scope Global