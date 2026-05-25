#!/usr/bin/env bash

function clone_common_repos() {
    local -a dw_repos=()

    if [[ -n "${COMMON_REPOS:-}" ]]; then
        read -r -a dw_repos <<< "${COMMON_REPOS}"
    fi

    [[ ${#dw_repos[@]} -eq 0 ]] && return 0

    for repo in "${dw_repos[@]}"; do
        folder=$(echo ${repo} | cut -d';' -f1)
        repo=$(echo ${repo} | cut -d';' -f2)
        repo_name=$(echo ${repo} | cut -d'/' -f2)

        [[ -d "${REPOS_PATH}/${folder}" ]] || mkdir -p "${REPOS_PATH}/${folder}"
        [[ -d "${REPOS_PATH}/${folder}/${repo_name}" ]] && continue

        folder_to_clone="${REPOS_PATH}/${folder}/${repo_name}"
        if [[ -x "$(command -v gh)" ]] && gh auth status; then
            gh repo clone ${repo} ${folder_to_clone}
        else
            git clone git@github.com:${repo}.git ${folder_to_clone}
        fi
    done
}