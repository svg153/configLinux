#!/usr/bin/env bash

set -euo pipefail

# RUN BEFORE:
# 1º) user must be in sudoers
#         * su && apt-get install sudo && adduser ${USER} sudo && exit
#         * reboot
# 2º) sudo apt-get install git && mkdir ~/REPOSITORIOS && git clone <CONFIG_REPO_URL> ~/REPOSITORIOS/configLinux/

# TODO: check this lines, only for debian
# configure the /etc/apt/sources.list
# sudo mv /etc/apt/sources.list /etc/apt/sources.list.OLD
# sudo cp ./sources.list /etc/apt/
# sudo sed -i 's/main/main contrib non-free/g' /etc/apt/sources.list


#
# VARS
#

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename -- "$0")"

MODE=${1:-help}
MODE_DESKTOP="desktop"
MODE_LAPTOP="laptop"
MODE_GIT_CONFIG_ONLY="git-config-only"
MODE_GIT_ONLY="git-only"
MODE_POWERSHELL_CONFIG_ONLY="powershell-config-only"
MODE_AGENT_CONFIG_ONLY="agent-config-only"
MODE_DOTFILES_LINKS_ONLY="dotfiles-links-only"
MODE_SHARED_CONFIG_ONLY="shared-config-only"
MODE_LIST="list-modes"
MODE_DOCTOR="doctor"
MODE_LINUX_BASE="linux-base"
MODE_LINUX_SHELLS="linux-shells"
MODE_LINUX_DEVTOOLS="linux-devtools"
MODE_LINUX_CONTAINERS="linux-containers"
MODE_LINUX_DESKTOP="linux-desktop"
MODE_LINUX_CUSTOMIZE="linux-customize"
MODE_LINUX_AI="linux-ai"
MODE_HELP="help"
CONFIG_REPO_URL=${CONFIG_REPO_URL:-}
WORK_GIT_HOST=${WORK_GIT_HOST:-<WORK_GIT_HOST>}
ASSUME_YES="false"

if [[ "${2:-}" == "--yes" ]] || [[ "${2:-}" == "-y" ]] || [[ "${CONFIGLINUX_ASSUME_YES:-false}" == "true" ]]; then
    ASSUME_YES="true"
elif [[ -n "${2:-}" ]]; then
    echo "Unknown option: ${2}"
    echo "Use '${SCRIPT_NAME} help' to see the available modes."
    exit 1
fi

# env paths
if [[ -z "${CONFIG_PATH:-}" ]]; then
    export CONFIG_PATH="${SCRIPT_DIR}"
fi

source "${SCRIPT_DIR}/SCRIPTS/bootstrap/common.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-core.sh"

. "${SCRIPT_DIR}/.env.paths.env"

require_configlinux_env_paths

isWSL="$(detect_wsl_environment)"


#
# VARS
#



#
# FUNCTIONS
#
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-base.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-shells.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-system.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-repos.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-github.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-ai.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-devtools.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-cloud.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-containers.sh"
source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-desktop.sh"

source "${SCRIPT_DIR}/SCRIPTS/bootstrap/linux-stages.sh"



#
# MAIN
#

case "${MODE}" in
    "${MODE_HELP}"|"${MODE_LIST}"|-h|--help)
        print_usage
        exit 0
        ;;
    "${MODE_DOCTOR}")
        ;;
    "${MODE_GIT_CONFIG_ONLY}"|"${MODE_GIT_ONLY}"|"${MODE_POWERSHELL_CONFIG_ONLY}"|"${MODE_AGENT_CONFIG_ONLY}"|"${MODE_DOTFILES_LINKS_ONLY}"|"${MODE_SHARED_CONFIG_ONLY}"|"${MODE_LINUX_BASE}"|"${MODE_LINUX_SHELLS}"|"${MODE_LINUX_DEVTOOLS}"|"${MODE_LINUX_CONTAINERS}"|"${MODE_LINUX_DESKTOP}"|"${MODE_LINUX_CUSTOMIZE}"|"${MODE_LINUX_AI}")
        ;;
    "${MODE_DESKTOP}"|"${MODE_LAPTOP}")
        require_full_bootstrap_confirmation
        ;;
    *)
        log error "Unknown mode: ${MODE}"
        print_usage
        exit 1
        ;;
esac

mkdir -p ~/bin

sync_config_repo

if [[ "${MODE}" == "${MODE_DOCTOR}" ]]; then
    print_doctor_report
    exit 0
fi

if [[ "${MODE}" == "${MODE_GIT_CONFIG_ONLY}" ]] || [[ "${MODE}" == "${MODE_SHARED_CONFIG_ONLY}" ]]; then
    configure_shared_base
    log info "shared-config-only mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_GIT_ONLY}" ]]; then
    configure_git
    log info "git-only mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_POWERSHELL_CONFIG_ONLY}" ]]; then
    install_powershell_templates
    log info "powershell-config-only mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_AGENT_CONFIG_ONLY}" ]]; then
    install_vscode_agent_templates_linux
    log info "agent-config-only mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_DOTFILES_LINKS_ONLY}" ]]; then
    make_folder_structure
    log info "dotfiles-links-only mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_LINUX_BASE}" ]]; then
    run_linux_stage_base
    log info "linux-base mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_LINUX_SHELLS}" ]]; then
    run_linux_stage_shells
    log info "linux-shells mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_LINUX_DEVTOOLS}" ]]; then
    run_linux_stage_devtools
    log info "linux-devtools mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_LINUX_CONTAINERS}" ]]; then
    run_linux_stage_containers
    log info "linux-containers mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_LINUX_DESKTOP}" ]]; then
    run_linux_stage_desktop
    log info "linux-desktop mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_LINUX_CUSTOMIZE}" ]]; then
    run_linux_stage_customization
    log info "linux-customize mode complete"
    exit 0
fi

if [[ "${MODE}" == "${MODE_LINUX_AI}" ]]; then
    run_linux_stage_ai
    log info "linux-ai mode complete"
    exit 0
fi

run_linux_full_bootstrap
