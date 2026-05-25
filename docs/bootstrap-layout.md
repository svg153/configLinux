# Bootstrap layout

This repository mixes two concerns:

- dotfiles and hand-maintained config trees
- machine bootstrap / reconfiguration entrypoints

To keep both concerns manageable, the repo now uses this split:

- root entrypoints: `run.sh` and `run.ps1`
- reusable helpers: `SCRIPTS/bootstrap/` (`common.sh`, `linux-core.sh`, domain modules, and Windows helpers)
- authoritative Git config: `/.gitconfig` and `/.gitconfig.d/`
- local identity seed templates: `templates/git/`
- shared shell templates: `templates/powershell/`
- Windows-only templates: `templates/windows/`
- VS Code agent templates: `templates/vscode/`

## Why not move everything to Python or Ansible right now?

For a first-run bootstrap, the safest assumption is that only the native shell exists:

- Bash on Linux
- PowerShell on Windows

During this session we checked the current machine and Python was not available out of the box, so making Python the single entrypoint would introduce a fresh dependency before the setup tool can even start.

That is why the current direction is:

- native entrypoints per platform
- shared repository layout and safety rules
- modular subcommands for partial reconfiguration

The Linux entrypoint now also has stage-oriented modes (`linux-base`, `linux-devtools`, `linux-containers`, `linux-desktop`, `linux-customize`, `linux-ai`) plus a `doctor` mode, so a machine can be reconfigured by slices instead of rerunning the whole bootstrap.

The Windows entrypoint mirrors that idea with safe config modes (`doctor`, `git-only`, `powershell-config-only`, `agent-config-only`, `windows-terminal-only`, `vscode-config-only`, `windows-config-only`) plus install-oriented modes (`windows-tools`, `windows-modules`, `windows-shell`, `windows-full`). Those modes now also route through dedicated stage wrappers in `windows-stages.ps1`, so the one-shot and partial flows reuse the same Git, terminal, VS Code, and shared-config building blocks.

The Linux entrypoint also has a dedicated `agent-config-only` mode so MCP/prompt assets can be refreshed without rerunning the full AI/tooling stage.

The Git identity seed files now come from `templates/git/` on both platforms, while the shared non-secret Git config stays versioned at the repo root. That keeps the include chain authoritative and still avoids embedding placeholder identity content in Bash and PowerShell helpers.

If Python becomes a guaranteed dependency later, it can still be introduced as an internal orchestration layer without changing the repository layout again.
