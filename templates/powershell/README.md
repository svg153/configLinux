# PowerShell templates

Shared PowerShell templates used by both Linux (`pwsh`) and Windows.

## Files

- `Copilot.DevProfile.ps1` — shared developer profile with UTF-8, PSReadLine, prompt/theme, aliases, and helper functions.
- `profile.ps1` — thin loader installed into the platform profile path that dot-sources `Copilot.DevProfile.ps1` from `~/.configLinux`.
- `themes/jandedobbeleer.omp.json` — minimal example theme.

These templates are installed by:

- `./run.sh powershell-config-only`
- `./run.ps1 powershell-config-only`
- the broader shared config modes on both platforms

On Windows the same loader is written to both PowerShell 7 and Windows PowerShell 5.1 profile locations so both shells share the same profile body.
