# ================================
# Copilot.DevProfile.ps1 — merged profile
# configLinux shared PowerShell profile (Windows + Linux)
# ================================
# Best of both:
#   - Copilot base: UTF-8 encoding, .local/bin PATH, helpers, posh-git, gh completion
#   - Ours: advanced PSReadLine, UNIX aliases, navigation, functions, git config,
#     zoxide, Starship, catppuccin-mocha OMP theme, welcome message
# ================================

$PSDefaultParameterValues['Cmdlet:*'] = @{ 'ErrorAction' = 'SilentlyContinue' }

# --------------------
# 0. UTF-8 encoding (Copilot)
# --------------------
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

# --------------------
# 1. PATH setup (Both)
# --------------------
# .local/bin (Copilot — portable toolchain)
$localBin = Join-Path $HOME '.local/bin'
$hasLocalBin = Test-Path -LiteralPath $localBin -ErrorAction SilentlyContinue
if ($hasLocalBin -and $env:PATH -notlike "*$localBin*") {
    $env:PATH = "$localBin;$env:PATH"
}

# Scoop shims (ours — Windows native)
$scoopShims = "C:\Users\svg15\scoop\shims"
if ($env:PATH -notlike "*$scoopShims*") {
    $env:PATH = "$scoopShims;$env:PATH"
}

# Starship (ours — standalone prompt)
$starshipPath = "C:\Users\svg15\scoop\apps\starship\current"
$hasStarship = Test-Path -LiteralPath "$starshipPath\starship.exe" -ErrorAction SilentlyContinue
if ($hasStarship -and $env:PATH -notlike "*$starshipPath*") {
    $env:PATH = "$starshipPath;$env:PATH"
}

# --------------------
# 2. Helper functions (Copilot)
# --------------------
function Set-ConfigLinuxAlias {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
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
    param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Name)
    Get-Command @Name | Select-Object Name, CommandType, Source
}

# --------------------
# 3. PSReadLine (ours — advanced)
# --------------------
try {
    Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
    Set-PSReadLineOption -PredictionSource Plugin -ErrorAction Stop
    Set-PSReadLineOption -EditMode Windows -ErrorAction Stop
    Set-PSReadLineKeyHandler -Key Tab -Function Complete -ErrorAction Stop
    Set-PSReadLineKeyHandler -Key '^d' -Function DeleteChar -ErrorAction Stop
    Set-PSReadLineKeyHandler -Key '^z' -Function Undo -ErrorAction Stop
    Set-PSReadLineKeyHandler -Key Shift+Insert -Function Paste -ErrorAction Stop
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward -ErrorAction Stop
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward -ErrorAction Stop
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd -ErrorAction Stop
    Set-PSReadLineOption -MaximumHistoryCount 10000 -ErrorAction Stop
} catch {}

# --------------------
# 4. Optional modules (Copilot)
# --------------------
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
}
if (Get-Module -ListAvailable -Name posh-git) {
    Import-Module posh-git -ErrorAction SilentlyContinue
}
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}

# --------------------
# 5. UNIX aliases (ours)
# --------------------
Set-Alias -Name cat Get-Content -Option AllScope -Force
Set-Alias -Name grep Select-String -Option AllScope -Force
Set-Alias -Name find Where-Object -Option AllScope -Force
Set-Alias -Name cp Copy-Item -Option AllScope -Force
Set-Alias -Name mv Move-Item -Option AllScope -Force
Set-Alias -Name rm Remove-Item -Option AllScope -Force
Set-Alias -Name vim nvim -Option AllScope -Force
Set-Alias -Name vi nvim -Option AllScope -Force
Set-Alias -Name less more -Option AllScope -Force
Set-Alias -Name tree tree.exe -Option AllScope -Force
Set-Alias -Name code code.cmd -Option AllScope -Force
Set-Alias -Name j Set-Location -Option AllScope -Force
Set-Alias -Name ep nvim -Option AllScope -Force

# Aliases from Copilot (minimal)
Set-Alias -Name l Get-ChildItem -Option AllScope -Force
Set-ConfigLinuxAlias -Name l Get-ChildItem
Set-ConfigLinuxAlias -Name ll Get-ChildItem
Set-ConfigLinuxAlias -Name la Get-ChildItem

# --------------------
# 6. Navigation (ours)
# --------------------
function oh { explorer.exe "$env:USERPROFILE" }
function od { explorer.exe "$env:USERPROFILE\Desktop" }
function odw { explorer.exe "$env:USERPROFILE\Downloads" }
function odo { explorer.exe "$env:USERPROFILE\Documents" }
function edit-profile { nvim $PROFILE }

# --------------------
# 7. Utility functions (ours)
# --------------------
function ll { Get-ChildItem -Force @args }
function la { Get-ChildItem -Force -Hidden @args }
function mkdir { param([string]$Path); New-Item -ItemType Directory -Path $Path -ErrorAction SilentlyContinue }
function head { param([string]$Path, [int]$Count=10); Get-Content -Path $Path -Head $Count }
function tail { param([string]$Path, [int]$Count=10); Get-Content -Path $Path -Tail $Count }

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Aliases from Copilot (helpers)
Set-Alias -Name touch Invoke-ConfigLinuxTouch -Scope Global
Set-Alias -Name mkcd Invoke-ConfigLinuxMkcd -Scope Global
Set-Alias -Name reload-profile Invoke-ConfigLinuxReloadProfile -Scope Global
Set-Alias -Name which Invoke-ConfigLinuxWhich -Scope Global

# --------------------
# 8. GitHub CLI completions (Copilot)
# --------------------
if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        (& gh completion -s powershell) -join [Environment]::NewLine | Invoke-Expression
    } catch {}
}

# --------------------
# 9. Prompt: Oh-My-Posh (catppuccin-mocha), fallback Starship
# --------------------
# Only one prompt engine may own the prompt: initializing both made OMP win
# silently and wasted startup time.
try {
    if (Get-Command oh-my-posh -ErrorAction Stop) {
        # Use configLinux theme if available, fallback to local catppuccin
        $ompTheme = Join-Path $HOME '.poshthemes\catppuccin-mocha.omp.json'
        if (-not (Test-Path $ompTheme)) {
            $ompTheme = Join-Path $HOME '.poshthemes\jandedobbeleer.omp.json'
        }
        if (Test-Path $ompTheme) {
            oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
        } else {
            # Fallback: inline theme init
            oh-my-posh init pwsh | Invoke-Expression
        }
    } elseif (Get-Command starship -ErrorAction Stop) {
        Invoke-Expression (&starship init powershell | Out-String)
    }
} catch {}

# --------------------
# 11. Git config (ours — diff-so-fancy + aliases)
# --------------------
# diff-so-fancy for git
if (Get-Command diff-so-fancy -ErrorAction SilentlyContinue) {
    git config --global core.pager diff-so-fancy 2>$null
    git config --global pager.diff diff-so-fancy 2>$null
    git config --global interactive.diffFilter "diff-so-fancy --colorOnly" 2>$null
    git config --global diff.colorMoved default 2>$null
}

# Git core config (Windows)
# git is a native command: never pass -ErrorAction to it (it reaches git as an
# extra argument and fails with "wrong number of arguments"). Use 2>$null.
if (Get-Command git -ErrorAction SilentlyContinue) {
    git config --global core.autocrlf true 2>$null
    git config --global core.longpaths true 2>$null
    $gitAliases = @{ st = 'status'; co = 'checkout'; br = 'branch'; ci = 'commit'; df = 'diff' }
    $gitAliases.GetEnumerator() | ForEach-Object {
        if (-not (git config --get "alias.$($_.Key)" 2>$null)) {
            git config --global "alias.$($_.Key)" $($_.Value) 2>$null
        }
    }
    if (-not (git config --get alias.lg 2>$null)) {
        git config --global alias.lg "log --oneline --graph --decorate --all" 2>$null
    }
}

# --------------------
# 12. Welcome message (ours — first run only)
# --------------------
$welcomeFile = "$env:USERPROFILE\.pwsh-welcome-seen"
if (-not (Test-Path $welcomeFile)) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  🚀 PowerShell merged profile — configLinux         ║" -ForegroundColor Green
    Write-Host "║  ⌨  Ctrl+Z = Undo | Shift+Insert = Paste            ║" -ForegroundColor Cyan
    Write-Host "║  📖 cat grep find cp mv rm vim tree which            ║" -ForegroundColor Cyan
    Write-Host "║  🎨 Starship / Oh-My-Posh (catppuccin-mocha)         ║" -ForegroundColor Yellow
    Write-Host "║  📦 zoxide | bat | fd | rg | jq | fzf              ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Set-Content -Path $welcomeFile -Value (Get-Date).ToString("yyyy-MM-dd")
}

# --------------------
# 13. Git user warning (both — combined)
# --------------------
try {
    $email = git config --get user.email 2>$null
    if (-not $email) {
        Write-Host "`n⚠️  Git no configurado:" -ForegroundColor Yellow
        Write-Host "   git config --global user.name 'Tu Nombre'" -ForegroundColor Gray
        Write-Host "   git config --global user.email 'tu@email.com'" -ForegroundColor Gray
    }
} catch {}

# --------------------
# 14. Zoxide init (ours — cd intelligent, go last)
# --------------------
try {
    if (Get-Command zoxide -ErrorAction Stop) {
        # Try zoxide init powershell first, fallback if --no-cmd not supported
        try {
            Invoke-Expression (& zoxide init powershell --no-cmd none 2>$null | Out-String)
        } catch {
            # Fallback for older zoxide versions
            Invoke-Expression (& zoxide init powershell 2>$null | Out-String)
        }
    }
} catch {}