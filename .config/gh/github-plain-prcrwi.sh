#!/bin/sh

github_plain_prcrwi() {
    # Usage: gh plain-prcrwim [pr_title]

    branch_name=$(gh __branch-name)
    
    issue_id=$(echo "${branch_name}" | awk -F'_' '{print $1}')
    branch_issue_title=$(echo "${branch_name}" | awk -F'_' '{print $2}')
    
    wi_id="${issue_id}"
    # if the issue id is in the format of AB-1234, then remove the prefix
    case "${wi_id}" in
        AB-*) 
            wi_id_azdo="${wi_id#AB-}" # remove the prefix
            pr_body='#'"${wi_id_azdo}"
            ;;
        *)
            wi_id_azdo=${wi_id}
            pr_body="${wi_id_azdo}"
            ;;
    esac
    
    wi_title="${branch_issue_title}"
    wi_title_azdo=$(echo "${wi_title}" | tr '-' ' ')
    
    pr_title="${wi_id_azdo} ${wi_title_azdo}"
    
    default_branch="main"
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

    git push -u origin HEAD
    
    az repos pr create \
        --title "${pr_title}" \
        --description "${pr_body}" \
        --source-branch "${branch_name}" \
        --target-branch "${default_branch}" \
        --work-items "${wi_id_azdo}"
}

function __get_default_branch_git() {
    default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d':' -f2 | xargs)
    echo "${default_branch}"
}

function __get_default_branch_azdo() {
    # get the default branch of the repository from az devops
    repository_name=$(git remote get-url origin | awk -F'/' '{print $3}')
    repository_name_decoded=$(echo "${repository_name}" | sed 's/%20/ /g' | sed 's/%2F/\//g')
    default_branch_long=$(az repos show --repository "${repository_name_decoded}" --query "defaultBranch" -o tsv)
    default_branch=$(echo "${default_branch_long}" | sed 's/refs\/heads\///')
    
}