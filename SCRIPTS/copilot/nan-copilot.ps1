#Requires -Version 7.0
[CmdletBinding()]
param(
  [string]$Model = 'deepseek-v4-flash'
)

$copilotCommand = Get-Command copilot -CommandType Application -ErrorAction SilentlyContinue
if (-not $copilotCommand) {
  throw "No se encuentra Copilot CLI. Instálalo con: winget install GitHub.Copilot"
}

$secureKey = Read-Host 'Pega tu clave API de NaN' -AsSecureString
if ($secureKey.Length -eq 0) {
  $secureKey.Dispose()
  throw 'La clave API de NaN no puede estar vacía.'
}

$environmentNames = @(
  'COPILOT_PROVIDER_BASE_URL',
  'COPILOT_PROVIDER_TYPE',
  'COPILOT_PROVIDER_API_KEY',
  'COPILOT_PROVIDER_MODEL_ID',
  'COPILOT_PROVIDER_WIRE_MODEL',
  'COPILOT_MODEL'
)
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
  $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

$keyPointer = [IntPtr]::Zero
$apiKey = $null
$copilotExitCode = 0
try {
  $keyPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
  $apiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPointer)

  $env:COPILOT_PROVIDER_BASE_URL = 'https://api.nan.builders/v1'
  $env:COPILOT_PROVIDER_TYPE = 'openai'
  $env:COPILOT_PROVIDER_API_KEY = $apiKey
  $env:COPILOT_PROVIDER_MODEL_ID = $Model
  $env:COPILOT_PROVIDER_WIRE_MODEL = $Model
  $env:COPILOT_MODEL = $Model

  & $copilotCommand.Source
  $copilotExitCode = $LASTEXITCODE
} finally {
  if ($keyPointer -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPointer)
  }
  $secureKey.Dispose()
  $apiKey = $null

  foreach ($name in $environmentNames) {
    [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process')
  }
}

$global:LASTEXITCODE = $copilotExitCode
