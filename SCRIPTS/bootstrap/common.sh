#!/usr/bin/env bash

function log() {
    local level=$1
    local msg=$2
    local color

    case $level in
        info)
            color="\e[32m"
            ;;
        warning | warn)
            color="\e[33m"
            ;;
        error)
            color="\e[31m"
            ;;
        *)
            color="\e[0m"
            ;;
    esac

    echo -e "${color}[${level}] ${msg}\e[0m"
}

function print_usage()
{
    cat <<EOF
Usage:
  ${SCRIPT_NAME} help
    ${SCRIPT_NAME} list-modes
    ${SCRIPT_NAME} doctor
  ${SCRIPT_NAME} ${MODE_GIT_CONFIG_ONLY}
  ${SCRIPT_NAME} ${MODE_GIT_ONLY}
  ${SCRIPT_NAME} ${MODE_POWERSHELL_CONFIG_ONLY}
    ${SCRIPT_NAME} ${MODE_AGENT_CONFIG_ONLY}
  ${SCRIPT_NAME} ${MODE_DOTFILES_LINKS_ONLY}
  ${SCRIPT_NAME} ${MODE_SHARED_CONFIG_ONLY}
    ${SCRIPT_NAME} ${MODE_LINUX_BASE}
    ${SCRIPT_NAME} ${MODE_LINUX_SHELLS}
    ${SCRIPT_NAME} ${MODE_LINUX_DEVTOOLS}
    ${SCRIPT_NAME} ${MODE_LINUX_CONTAINERS}
    ${SCRIPT_NAME} ${MODE_LINUX_DESKTOP}
    ${SCRIPT_NAME} ${MODE_LINUX_CUSTOMIZE}
    ${SCRIPT_NAME} ${MODE_LINUX_AI}
  ${SCRIPT_NAME} ${MODE_DESKTOP} --yes
  ${SCRIPT_NAME} ${MODE_LAPTOP} --yes

Modes:
    list-modes                    Show the available modes.
    doctor                        Print a non-destructive environment/config report.
  ${MODE_GIT_CONFIG_ONLY}       Backward-compatible alias for the shared base config flow.
  ${MODE_GIT_ONLY}              Refresh only Git config links and ignored identity templates.
    ${MODE_POWERSHELL_CONFIG_ONLY} Refresh only PowerShell / Oh My Posh templates.
    ${MODE_AGENT_CONFIG_ONLY}    Refresh VS Code MCP/prompts agent templates only.
  ${MODE_DOTFILES_LINKS_ONLY}   Refresh Linux dotfile links and folder structure only.
  ${MODE_SHARED_CONFIG_ONLY}    Refresh the cross-platform base config (Git + PowerShell templates).
    ${MODE_LINUX_BASE}            Run Linux system/base setup only.
    ${MODE_LINUX_SHELLS}          Run Linux shell setup only.
    ${MODE_LINUX_DEVTOOLS}        Run Linux developer tooling setup only.
    ${MODE_LINUX_CONTAINERS}      Run Linux container/Kubernetes tooling setup only.
    ${MODE_LINUX_DESKTOP}         Run Linux desktop application setup only.
    ${MODE_LINUX_CUSTOMIZE}       Run Linux desktop customization only.
    ${MODE_LINUX_AI}              Run AI tooling setup only.
  ${MODE_DESKTOP}               Run the full desktop bootstrap (explicit confirmation required).
  ${MODE_LAPTOP}                Run the full laptop bootstrap (explicit confirmation required).

Environment variables:
  CONFIG_REPO_URL   Repository URL used only when CONFIG_PATH does not exist.
  WORK_GIT_HOST     Host used in generated work includeIf rules.
  COMMON_REPOS      Optional space-separated list in the form folder;org/repo.

Notes:
  - Running without a mode shows this help instead of bootstrapping the machine.
  - Full bootstrap modes require --yes (or CONFIGLINUX_ASSUME_YES=true).
  - The shared templates live under templates/git, templates/powershell, and templates/windows.
EOF
}

function require_full_bootstrap_confirmation()
{
    if [[ "${ASSUME_YES}" == "true" ]]; then
        return 0
    fi

    log warn "Full bootstrap mode '${MODE}' is intentionally gated because it installs packages and rewires local config."
    echo "Re-run with: ${SCRIPT_NAME} ${MODE} --yes"
    exit 1
}

function backup_existing_path()
{
    local target_file=$1
    local backup_file="${target_file}.backup.$(date +%Y%m%d%H%M%S)"

    mv "${target_file}" "${backup_file}"
    log warn "Moved existing ${target_file} to ${backup_file}"
}

function copy_if_missing()
{
    if [[ $# -ne 2 ]]; then
        echo "Usage: copy_if_missing <source_file> <target_file>"
        return 1
    fi

    local source_file=$1
    local target_file=$2

    source_file=$(eval echo "${source_file}")
    target_file=$(eval echo "${target_file}")

    mkdir -p "$(dirname "${target_file}")"

    if [[ -e "${target_file}" ]]; then
        log info "Keeping existing ${target_file}"
        return 0
    fi

    cp "${source_file}" "${target_file}"
    log info "Copied ${source_file} -> ${target_file}"
}

function write_file_from_template_if_missing()
{
    if [[ $# -ne 2 ]]; then
        echo "Usage: write_file_from_template_if_missing <template_file> <target_file>"
        return 1
    fi

    local template_file=$1
    local target_file=$2

    template_file=$(eval echo "${template_file}")
    target_file=$(eval echo "${target_file}")

    mkdir -p "$(dirname "${target_file}")"

    if [[ -e "${target_file}" ]]; then
        log info "Keeping existing ${target_file}"
        return 0
    fi

    if [[ ! -f "${template_file}" ]]; then
        log error "Template not found: ${template_file}"
        return 1
    fi

    sed "s|<WORK_GIT_HOST>|${WORK_GIT_HOST}|g" "${template_file}" > "${target_file}"
    log info "Created ${target_file} from ${template_file}"
}

function create_symlink()
{
    if [[ $# -ne 2 ]]; then
        echo "Usage: create_symlink <source_file> <target_file>"
        return 1
    fi

    local source_file=$1
    local target_file=$2

    target_file=$(echo "${target_file}" | sed 's/\/\//\//g')
    source_file=$(eval echo "${source_file}")
    target_file=$(eval echo "${target_file}")

    mkdir -p "$(dirname "${target_file}")"

    if [[ -L "${target_file}" ]]; then
        current_link=$(readlink "${target_file}" || true)
        if [[ "${current_link}" == "${source_file}" ]]; then
            log info "Symlink already in place: ${target_file}"
            return 0
        fi
        unlink "${target_file}"
    elif [[ -e "${target_file}" ]]; then
        backup_existing_path "${target_file}"
    fi

    ln -s "${source_file}" "${target_file}"
    log info "Linked ${target_file} -> ${source_file}"
}

function ensure_git_identity_templates()
{
    local personal_mail_gitconfig="${CONFIG_PATH}/.gitconfig.d/personal-mail.gitconfig"
    local work_dir="${CONFIG_PATH}/.gitconfig.d/work"
    local work_mail_gitconfig="${work_dir}/work-company.gitconfig"
    local work_gitconfig="${work_dir}/work.gitconfig"
    local git_template_dir="${CONFIG_PATH}/templates/git/gitconfig.d"

    mkdir -p "${work_dir}"

    write_file_from_template_if_missing "${git_template_dir}/personal-mail.gitconfig" "${personal_mail_gitconfig}"
    write_file_from_template_if_missing "${git_template_dir}/work/work-company.gitconfig" "${work_mail_gitconfig}"
    write_file_from_template_if_missing "${git_template_dir}/work/work.gitconfig" "${work_gitconfig}"
}

function should_skip_repo_sync()
{
    case "${MODE}" in
        "${MODE_HELP}"|"${MODE_LIST}"|"${MODE_DOCTOR}")
            return 0
            ;;
        *-only)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function sync_config_repo()
{
    if [[ -d "${SCRIPT_DIR}/.git" ]] && [[ "${CONFIG_PATH}" == "${SCRIPT_DIR}" ]]; then
        log info "Using current repository checkout at ${CONFIG_PATH}"
        return 0
    fi

    if [[ -d "${CONFIG_PATH}/.git" ]]; then
        if should_skip_repo_sync && [[ "${CONFIGLINUX_FORCE_PULL:-false}" != "true" ]]; then
            log info "Skipping git pull for existing config repo in ${MODE} mode"
            return 0
        fi
        git -C "${CONFIG_PATH}" pull
    else
        if [[ -z "${CONFIG_REPO_URL}" ]]; then
            log error "CONFIG_REPO_URL is required when ${CONFIG_PATH} does not exist"
            return 1
        fi
        git clone "${CONFIG_REPO_URL}" "${CONFIG_PATH}"
    fi
}

function configure_git()
{
    log info "git"
    ensure_git_identity_templates
    create_symlink "${CONFIG_PATH}" ~/.configLinux
    create_symlink "${CONFIG_PATH}/.gitconfig" ~/.gitconfig
    create_symlink "${CONFIG_PATH}/.gitconfig.d" ~/.gitconfig.d
    create_symlink "${CONFIG_PATH}/.git-template" ~/.git-template
    git config --global init.templateDir ~/.git-template
}

function install_powershell_templates()
{
    if [[ -d "${CONFIG_PATH}/templates/powershell" ]]; then
        mkdir -p ~/.poshthemes
        mkdir -p ~/.config/powershell

        if [[ -f "${CONFIG_PATH}/templates/powershell/themes/jandedobbeleer.omp.json" ]]; then
            copy_if_missing "${CONFIG_PATH}/templates/powershell/themes/jandedobbeleer.omp.json" ~/.poshthemes/jandedobbeleer.omp.json
        fi

        if [[ -f "${CONFIG_PATH}/templates/powershell/profile.ps1" ]]; then
            copy_if_missing "${CONFIG_PATH}/templates/powershell/profile.ps1" ~/.config/powershell/Microsoft.PowerShell_profile.ps1
        fi
    fi
}

function configure_shared_base()
{
    configure_git
    install_powershell_templates
}