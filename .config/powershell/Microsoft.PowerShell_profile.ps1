# configLinux PowerShell loader

$candidatePaths = @(
    (Join-Path $HOME '.configLinux/templates/powershell/Copilot.DevProfile.ps1'),
    (Join-Path $PSScriptRoot 'Copilot.DevProfile.ps1')
)

foreach ($candidate in $candidatePaths) {
    if (Test-Path -LiteralPath $candidate) {
        . $candidate
        return
    }
}

Write-Warning 'configLinux shared PowerShell profile not found. Expected Copilot.DevProfile.ps1.'