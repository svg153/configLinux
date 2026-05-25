# Bootstrap entrypoints

This folder contains the reusable bootstrap helpers used by the repo entrypoints:

- `common.sh` — shared Bash helpers used by `run.sh`
- `linux-core.sh` — package manager, OS detection, and core Linux bootstrap helpers shared by Bash modules
- `linux-base.sh` — base filesystem layout and foundational shell/git helpers for Linux
- `linux-shells.sh` — zsh, fonts, and shell-adjacent Linux setup helpers
- `linux-system.sh` — Linux host/driver provisioning helpers used by the base stage
- `linux-repos.sh` — reusable repository-cloning helpers for Linux cleanup/bootstrap tasks
- `linux-devtools.sh` — language runtimes and general CLI developer tooling for Linux
- `linux-cloud.sh` — Azure and Terraform/IaC tooling for Linux
- `linux-containers.sh` — Docker, Minikube, and Kubernetes helper tooling for Linux
- `linux-desktop.sh` — Linux desktop application installers used by the desktop stage
- `linux-github.sh` — GitHub/gh-related Bash helpers used by the Linux bootstrap
- `linux-ai.sh` — AI, MCP, skills, and VS Code agent asset helpers for Linux
- `Windows.ps1` — shared PowerShell helpers used by `run.ps1`
- `windows-stages.ps1` — Windows stage orchestration wrappers used by `run.ps1`

The idea is to keep the root entrypoints small and expose modular commands while reusing the same repository structure, templates, and safety rules across Linux and Windows.
