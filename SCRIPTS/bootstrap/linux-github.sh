#!/usr/bin/env bash

function install_gh()
{
    if [[ -x "$(command -v gh)" ]]; then
        gh --version
        return 0
    fi

    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    update
    install gh

    if ! gh auth status; then
        gh auth login
    fi

    for key_type in ed25519 ecdsa-sha2-nistp256 rsa; do ssh-keyscan -t "${key_type}" github.com >> ~/.ssh/known_hosts; done
}

function install_gh_extensions(){
    gh_extension=(
        github/gh-projects
        dlvhdr/gh-dash
        meiji163/gh-notify
        seachicken/gh-poi
        redraw/gh-install
    )

    if gh auth status; then
        for ext in "${gh_extension[@]}"; do
            install_gh_ext "${ext}"
        done

        install_gh_clone_org_matt
        install_gh_clone_org_fork
    else
        log warn "gh_extensions: gh is not authenticated"
    fi
}

function install_gh_clone_org_matt()
{
    local extensions_dir="${HOME}/.local/share/gh/extensions"
    local installed_dir="${extensions_dir}/gh-clone-org"
    local renamed_dir="${extensions_dir}/gh-clone-org-matt"

    if [[ -d "${renamed_dir}" ]]; then
        log info "install_gh_clone_org_matt: already installed as 'gh clone-org-matt'"
        return 0
    fi

    # Install under the default name (gh-clone-org), then rename so the command
    # becomes 'gh clone-org-matt' and frees the 'gh clone-org' name for the fork.
    install_gh_ext "matt-bartel/gh-clone-org"

    [[ -d "${installed_dir}" ]] || {
        log error "install_gh_clone_org_matt: ${installed_dir} not found after install"
        return 1
    }

    mv "${installed_dir}" "${renamed_dir}"
    if [[ -f "${renamed_dir}/gh-clone-org" ]]; then
        mv "${renamed_dir}/gh-clone-org" "${renamed_dir}/gh-clone-org-matt"
        chmod +x "${renamed_dir}/gh-clone-org-matt" 2>/dev/null || true
    fi
    log info "install_gh_clone_org_matt: registered as 'gh clone-org-matt'"
}

function install_gh_clone_org_fork()
{
    local extensions_dir="${HOME}/.local/share/gh/extensions"
    local custom_repo_dir="${REPOS_PATH}/gh-clone-org-custom"
    local active_link="${extensions_dir}/gh-clone-org"
    local fork_repo="svg153/gh-clone-org"

    if [[ ! -d "${custom_repo_dir}" ]]; then
        gh repo clone "${fork_repo}" "${custom_repo_dir}" || {
            log error "install_gh_clone_org_fork: failed to clone ${fork_repo}"
            return 1
        }
    fi

    mkdir -p "${extensions_dir}"
    # Replace whatever currently holds the 'gh clone-org' command name
    # (a plain dir from a previous install, or a stale symlink).
    if [[ -e "${active_link}" ]] || [[ -L "${active_link}" ]]; then
        rm -rf "${active_link}"
    fi
    ln -s "${custom_repo_dir}" "${active_link}"
    chmod +x "${custom_repo_dir}/gh-clone-org" 2>/dev/null || true
    log info "install_gh_clone_org_fork: 'gh clone-org' -> ${fork_repo} (${custom_repo_dir})"
}

function install_gh_ext()
{
    local ext=$1
    [[ $# -ne 1 ]] && echo "Usage: install_gh_ext <extension>" && return 1
    [[ -z "${ext}" ]] && echo "install_gh_ext: extension is empty" && return 1

    gh extension install "${ext}" || true
    gh extension list | grep "${ext}" || {
        log error "install_gh_ext: gh extension ${ext} not installed"
        return 1
    }
    log info "install_gh_ext: gh extension ${ext} installed"
}

function install_gh_copilot()
{
    if [[ -x "$(command -v github-copilot-cli)" ]]; then
        github-copilot-cli --version
        return 0
    fi

    [[ -x "$(command -v node)" ]] || install_node
    node_version=$(node -v | cut -d'.' -f1 | cut -d'v' -f2)
    [[ ${node_version} -lt 18 ]] && install_node

    if ! command -v npm &> /dev/null; then
        sudo apt install -y npm
    fi

    sudo npm install npm 2>/dev/null || true
    npm install -g @githubnext/github-copilot-cli 2>/dev/null || true

    log info "github-copilot-cli installed - run: github-copilot-cli auth"
}

function install_github_tools()
{
    go install github.com/gabrie30/ghorg@latest || true
}

function install_by_gh()
{
    local p=$1
    [[ $# -ne 1 ]] && echo "Usage: install_by_gh <github_org_repo>" && return 1
    [[ -z "${p}" ]] && echo "install_by_gh: github_org_repo is empty" && return 1
    gh install "${p}"
}