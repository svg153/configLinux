# Linux machine setup notes

This `docs/` folder contains step-by-step guides and architecture notes to reproduce the SSH signing + per-remote Git identity setup and the current bootstrap layout on new machines.

Files of interest:

- `linux-ssh-signing.md` — the how-to and a quick copy-paste section
- `bootstrap-layout.md` — the current cross-platform bootstrap structure and rationale
- `agent-tooling.md` — audit and bootstrap notes for MCPs, prompts, and agent assets
- `validation.md` — how to validate the safe entrypoints and hygiene scans
- `windows-dev-shell.md` — Windows developer shell/tooling bootstrap notes
- `../.gitconfig` / `../.gitconfig.d/` — shared Git config linked into the user home
- `../templates/git/` — ignored local identity seed templates
- `../templates/powershell/` — shared PowerShell prompt/profile templates
- `../SCRIPTS/linux-generate-signing-keys.sh` — helper script to generate keys and allowed_signers

Usage: copy the templates to the new machine, or run one of the modular entrypoints (`./run.sh shared-config-only`, `./run.sh agent-config-only`, `.\run.ps1 shared-config-only`, or `.\run.ps1 agent-config-only`), then follow the upload steps described in the guide.
