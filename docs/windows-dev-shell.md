# Windows developer shell

This repository can now bootstrap the Windows terminal/editor shell stack in two layers:

- safe config-only modes
- install-oriented developer-tooling modes

## Safe config-only modes

These do not fetch packages unless you ask them to overwrite files explicitly with `-Force`:

```powershell
.\run.ps1 doctor
.\run.ps1 git-only
.\run.ps1 powershell-config-only
.\run.ps1 agent-config-only
.\run.ps1 windows-terminal-only
.\run.ps1 vscode-config-only
.\run.ps1 windows-config-only
```

## Install-oriented modes

These are the Windows equivalents of the Linux stage modes:

```powershell
.\run.ps1 windows-tools
.\run.ps1 windows-modules
.\run.ps1 windows-shell
.\run.ps1 windows-full -Yes
```

What they cover:

- portable `git`
- portable `gh`
- portable `pwsh`
- portable `oh-my-posh`
- portable CLI tools: `rg`, `fd`, `bat`, `fzf`, `delta`
- PowerShell modules: `PSReadLine`, `posh-git`, `Terminal-Icons`
- shared PowerShell profile loader for both PowerShell 5.1 and 7
- VS Code MCP + prompt templates
- Windows Terminal default profile pointing at PowerShell 7
- VS Code terminal profile pointing at PowerShell 7

## Profile layout

The shared profile body lives in:

- `templates/powershell/Copilot.DevProfile.ps1`

The bootstrap writes the thin loader template to:

- `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- `Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

That way the real profile logic stays versioned in the repo and both shells reuse the same body through `~/.configLinux`.
