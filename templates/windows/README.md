# Windows templates

This folder stores Windows-specific templates that are copied by `run.ps1`.

## What lives here

- `terminal/settings.json` — Windows Terminal settings template with a dedicated PowerShell 7 profile placeholder
- `vscode/settings.json` — VS Code user settings template with a dedicated PowerShell 7 terminal profile placeholder

These files are rendered with the detected or expected `pwsh.exe` path before they are copied, and are only copied when missing unless `-Force` is used.
