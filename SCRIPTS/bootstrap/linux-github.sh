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

    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
    ssh-keyscan -t ecdsa-sha2-nistp256 github.com >> ~/.ssh/known_hosts
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
}

function install_gh_extensions(){
    gh_extension=(
        github/gh-copilot
        github/gh-projects
        dlvhdr/gh-dash
        rsese/gh-actions-status
        meiji163/gh-notify
        seachicken/gh-poi
        redraw/gh-install
    )

    local fork_repo="${GH_CLONE_ORG_FORK_REPO:-}"

    if gh auth status; then
        for ext in "${gh_extension[@]}"; do
            install_gh_ext "${ext}"
        done

        if ! gh extension list | grep "matt-bartel/gh-clone-org"; then
            install_gh_ext "matt-bartel/gh-clone-org"
            if [[ -d ~/.local/share/gh/extensions/gh-clone-org-matt ]]; then
                mv ~/.local/share/gh/extensions/gh-clone-org{,-matt}
                mv ~/.local/share/gh/extensions/gh-clone-org-matt/gh-clone-org{,-matt}
            fi
        fi

        if [[ -n "${fork_repo}" ]] && ! gh extension list | grep "${fork_repo}"; then
            local custom_repo_dir="${REPOS_PATH}/gh-clone-org-custom"
            local custom_ext_link="${HOME}/.local/share/gh/extensions/gh-clone-org-custom"
            local active_ext_link="${HOME}/.local/share/gh/extensions/gh-clone-org"

            if [[ ! -d "${custom_repo_dir}" ]]; then
                gh repo clone "${fork_repo}" "${custom_repo_dir}"
            fi

            mkdir -p "${HOME}/.local/share/gh/extensions"
            [[ -L "${custom_ext_link}" ]] || ln -s "${custom_repo_dir}" "${custom_ext_link}"
            [[ -L "${active_ext_link}" ]] && unlink "${active_ext_link}"
            ln -s "${custom_ext_link}" "${active_ext_link}"
            log info "gh-clone-org override linked from GH_CLONE_ORG_FORK_REPO"
        fi
    else
        log warn "gh_extensions: gh is not authenticated"
    fi
}

function install_gh_ext()
{
    local ext=$1
    [[ $# -ne 1 ]] && echo "Usage: install_gh_extensions <extension>" && return 1
    [[ -z "${ext}" ]] && echo "install_gh_extensions: extension is empty" && return 1

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

    sudo npm install -g npm
    sudo npm install -g @githubnext/github-copilot-cli

    github-copilot-cli auth
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