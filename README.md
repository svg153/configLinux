# configLinux

## Quick modes

- `./run.sh` — show help instead of changing the machine
- `./run.sh doctor` — show a non-destructive diagnostics report
- `./run.sh git-config-only` — backward-compatible alias for the shared base config flow
- `./run.sh git-only` — only refresh Git config links and local identity templates
- `./run.sh powershell-config-only` — only refresh PowerShell / Oh My Posh templates
- `./run.sh agent-config-only` — only refresh VS Code MCP/prompts agent templates
- `./run.sh dotfiles-links-only` — only refresh Linux dotfile links and folder structure
- `./run.sh shared-config-only` — refresh the cross-platform base config (Git + PowerShell templates)
- `./run.sh linux-base|linux-shells|linux-devtools|linux-containers|linux-desktop|linux-customize|linux-ai` — run only one Linux provisioning stage
- `./run.sh desktop --yes` — full desktop bootstrap
- `./run.sh laptop --yes` — full laptop bootstrap
- `.\run.ps1 doctor` — show a non-destructive diagnostics report on Windows
- `.\run.ps1 agent-config-only` — refresh VS Code MCP/prompts agent templates on Windows
- `.\run.ps1 windows-tools` — install/update the Windows portable CLI toolchain
- `.\run.ps1 windows-modules` — install/update shared PowerShell modules
- `.\run.ps1 windows-shell` — refresh the Windows shell/editor integration
- `.\run.ps1 windows-config-only` — refresh the Windows base config (Git + PowerShell + terminal templates)
- `.\run.ps1 windows-full -Yes` — full Windows developer bootstrap
- `.\run.ps1 shared-config-only` — refresh the cross-platform base config on Windows

Internally, both entrypoints now route most modes through stage wrappers, so the full and partial flows share the same implementation paths instead of duplicating dispatch logic. On Windows that now also includes dedicated wrappers for Git-only, Windows Terminal, and VS Code template refresh flows.

### Environment variables

- `CONFIG_REPO_URL` — repo URL to clone when `CONFIG_PATH` does not exist
- `WORK_GIT_HOST` — host used in generated work `includeIf hasconfig:remote.*.url` rules; if omitted the template keeps `<WORK_GIT_HOST>` as a local placeholder
- `COMMON_REPOS` — optional space-separated list in the format `folder;org/repo`

The bootstrap installs two `gh-clone-org` flavors: the upstream `matt-bartel/gh-clone-org` as `gh clone-org-matt`, and the personal fork `svg153/gh-clone-org` as the default `gh clone-org`.

The script now uses the repository checkout it is being run from by default, so the Git and prompt assets can be installed from any clone location without hardcoding a personal folder layout.

### GitHub Copilot CLI with NaN on Windows

`SCRIPTS\copilot\nan-copilot.ps1` starts GitHub Copilot CLI with the NaN OpenAI-compatible API. It prompts for the NaN API key without echoing it and does not save it. The default model is `deepseek-v4-flash`.

Run it from PowerShell 7 in the repository root:

```powershell
pwsh -File .\SCRIPTS\copilot\nan-copilot.ps1
```

To start with a different NaN model, pass its model ID:

```powershell
pwsh -File .\SCRIPTS\copilot\nan-copilot.ps1 -Model glm5.3-flash
```

Install PowerShell 7 and GitHub Copilot CLI first if they are not already installed:

```powershell
winget install --id Microsoft.PowerShell --source winget
winget install --id GitHub.Copilot --source winget
```

## Layout

- `run.sh` / `run.ps1` — platform entrypoints
- `SCRIPTS/bootstrap/` — reusable helper functions for each shell
- `.gitconfig` / `.gitconfig.d/` — authoritative shared Git config linked into the home directory
- `templates/git/` — local ignored Git identity seed templates
- `templates/powershell/` — shared PowerShell / Oh My Posh templates
- `templates/windows/` — Windows-specific editor and terminal templates
- `templates/vscode/` — VS Code MCP and prompt templates

See `docs/bootstrap-layout.md` for the rationale behind the current hybrid design.

## Validation

You can validate the safe entrypoint flows with:

- `powershell -ExecutionPolicy Bypass -File .\SCRIPTS\bootstrap\validate-entrypoints.ps1`

That validator now also parses the PowerShell entrypoints/helpers and degrades Bash-specific checks to `SKIP` when Git Bash is unavailable.

See `docs/validation.md` for details.

## Thanks

- <https://linuxpanda.wordpress.com/2016/12/31/things-to-do-after-installing-debian-stretch/>
- <https://www.youtube.com/watch?v=BWBHJmAmZgk>
- <https://www.youtube.com/watch?v=c60x3nd7cag>
- <https://www.youtube.com/watch?v=GR2y0xOIIdI>
- <https://www.adictosaltrabajo.com/2017/11/21/como-tener-un-terminal/>
- <https://github.com/fakewaffle/shell-config>

### oh-my-zsh

- <https://github.com/unixorn/awesome-zsh-plugins>

### Docker

- <https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9>
