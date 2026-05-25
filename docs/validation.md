# Validation

This repo now ships a small validation helper for the safe entrypoint modes.

## Validate the non-destructive paths

From Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\SCRIPTS\bootstrap\validate-entrypoints.ps1
```

What it checks:

- PowerShell parse checks:
  - `run.ps1`
  - `SCRIPTS/bootstrap/Windows.ps1`
  - `SCRIPTS/bootstrap/windows-stages.ps1`
- `bash -n run.sh`
- safe Bash modes:
  - `list-modes`
  - `doctor`
  - `shared-config-only`
  - `git-only`
  - `dotfiles-links-only`
  - `powershell-config-only`
  - `agent-config-only`
- safe PowerShell modes:
  - `list-modes`
  - `doctor`
  - `shared-config-only`
  - `git-only`
  - `windows-terminal-only`
  - `vscode-config-only`
  - `powershell-config-only`
  - `agent-config-only`
  - `windows-config-only`
  - `windows-shell`
- working-tree scans for sensitive strings and stale template references

The validator uses temporary repo copies and temporary home folders so it does not need to touch your real machine state.

If Git Bash is not available, the Bash-specific checks are reported as `SKIP` instead of failing the whole validation pass.
