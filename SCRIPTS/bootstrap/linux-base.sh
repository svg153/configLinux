#!/usr/bin/env bash
# ===========================================
# Helper functions for configLinux
# ===========================================

create_symlink() {
    local target="${1}"
    local dest="${2}"
    if [[ ! -e "${target}" ]]; then
        echo "   ⚠️  Skipped (target no existe): ${dest} → ${target}"
        return 0
    fi
    if [[ -L "${dest}" ]] && [[ "$(readlink -f "${dest}")" == "$(readlink -f "${target}")" ]]; then
        echo "   ✅ Already linked: ${dest} → ${target}"
        return 0
    fi
    if [[ -e "${dest}" ]] || [[ -d "${dest}" ]]; then
        local backup="${dest}.bak-$(date +%Y%m%d%H%M%S)"
        mv "${dest}" "${backup}" 2>/dev/null || true
        echo "   ⚠️  Backed up: ${dest} → ${backup}"
    fi
    ln -sfn "${target}" "${dest}"
    echo "   🔗 Created: ${dest} → ${target}"
}


function make_folder_structure()
{
    mkdir -p ${PROGRAMAS_PATH}
    mkdir -p ${WORK_REPOS_PATH}
    mkdir -p ${PERSONAL_REPOS_PATH}
    mkdir -p ~/.fonts
    mkdir -p ~/.icons

    create_symlink ${CONFIG_PATH}/.include_d ~/.include_d
    create_symlink ${CONFIG_PATH}/.aliases ~/.aliases
    create_symlink ${CONFIG_PATH}/.bashrc ~/.bashrc
    create_symlink ${CONFIG_PATH}/.bash_prompt ~/.bash_prompt
    create_symlink ${CONFIG_PATH}/.bash_aliases ~/.bash_aliases
    create_symlink ${CONFIG_PATH}/.bash_aliases.d ~/.bash_aliases.d
    create_symlink ${CONFIG_PATH}/.bash_completion ~/.bash_completion
    create_symlink ${CONFIG_PATH}/.bash_completion.d ~/.bash_completion.d
    create_symlink ${CONFIG_PATH}/.rc ~/.rc
    create_symlink ${CONFIG_PATH}/.rc.d ~/.rc.d
    create_symlink ${CONFIG_PATH}/.profile ~/.profile
    create_symlink ${CONFIG_PATH}/SCRIPTS ~/SCRIPTS
    create_symlink ${CONFIG_PATH}/.env.paths.env ~/.env.paths.env

    create_symlink ${CONFIG_PATH}/.config ~/.config
}

function install_bash_tools()
{
    git clone https://github.com/rupa/z ~/.z.tmp
    mv ~/.z.tmp/z.sh ~/.z
    rm -rf ~/.z.tmp
}

function install_git()
{
    sudo apt update \
    && install_by_pgkmanager git
}
