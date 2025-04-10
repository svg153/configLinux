__GH_BROWSER=""
get_gh_browser(){
    isWSL=$(uname -a | grep WSL | wc -l)
    if [ ${isWSL} ]; then
         __GH_BROWSER=explorer.exe
    fi
}
export GH_BROWSER="${__GH_BROWSER}"

github-clone-all(){
    user="$1"
    
    gh repos-name-all "${user}" | xargs -I '%' gh clo "${user}" %
    # OR
    # gh clone-org -p "${user}" -y "${user}"
}

alias prcrwi=github-prcrwi
github-prcrwi(){
    set -x
    root_dir=$(git rev-parse --show-toplevel)
    branch_name=$(gh __branch-name)
    wi_id=$(echo ${branch_name} | awk -F'_' '{print $1}')
    wi_title=$(echo ${branch_name} | awk -F'_' '{print $2}')

    wi_id_azdo=$(echo ${wi_id} | tr '-' '#')
    wi_id_azdo_num=$(echo ${wi_id_azdo} | awk -F'#' '{print $2}')
    wi_title_azdo=$(echo ${wi_title} | tr '-' ' ')

    pr_title="${wi_id_azdo} ${wi_title_azdo}"

    # if there is pull_request_template.md file in the .github folder, use it as pr body
    # pr_tmpl=${root_dir}/.github/pull_request_template.md
    # Force not enter
    pr_tmpl=${root_dir}/.github/pull_request_template.md
    pr_body_temp_file=$(mktemp -t pr_body_XXXXX.md)
    chmod 666 ${pr_body_temp_file}
    #trap "rm -f ${pr_body_temp_file}\" EXIT

    if [ -f "${pr_tmpl}" ]; then
        # Modify the template using sed
        modified_template=$(cat "${pr_tmpl}")
        modified_template=$(echo "${modified_template}" | sed '/<!--/,/-->/d')
        modified_template=$(echo "${modified_template}" | sed "s@### User Stories/Bugs affected@### User Stories/Bugs affected\\n\\nRelated ${wi_id_azdo}@")
        modified_template=$(echo "${modified_template}" | sed 's@### Other systems impacted@### Other systems impacted\\n\\n- N/A@')
        modified_template=$(echo "${modified_template}" | sed 's@- \\[ \\] No@- [x] No@')
        # Remplace double empty lines with one empty line
        modified_template=$(echo "${modified_template}" | sed ':L;N;s/^\\\\n$//;t L')
        echo "${modified_template}" > ${pr_body_temp_file}
        
        pr_body="${pr_body_temp_file}"
    else
        pr_body="${wi_id_azdo}"
    fi

    # TODO: Remove next line when https://github.com/cli/cli/issues/1718 is fixed
    git push -u origin HEAD

    bash -c "gh prcr \
        --title \"${pr_title}\" \
        --body-file \"${pr_body_temp_file}\" \
        --draft"
}
