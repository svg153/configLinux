#!/bin/bash

function github-pezaio-prcrwi() {
    # prcrwi: "!(\n      set -x\n    root_dir=$(git rev-parse --show-toplevel)\n    branch_name=$(gh __branch-name)\n    wi_id=$(echo ${branch_name} | awk -F'_' '{print $1}')\n    wi_title=$(echo ${branch_name} | awk -F'_' '{print $2}')\n\n    wi_id_azdo=$(echo ${wi_id} | tr '-' '#')\n    wi_title_azdo=$(echo ${wi_title} | tr '-' ' ')\n\n    pr_title=\"${wi_id_azdo} ${wi_title_azdo}\"\n    \n    # if there is pull_request_template.md file in the .github folder, use it as pr body\n    # pr_tmpl=${root_dir}/.github/pull_request_template.md\n    # Force not enter\n    pr_tmpl=${root_dir}/.github/pull_request_template.md\n    if [ -f \"${pr_tmpl}\" ]; then\n        pr_body_temp_file=$(mktemp)\n        # trap \"rm -f ${pr_body_temp_file}\" EXIT\n        \n        pr_body=$(sed '/<!--/,/-->/d' ${pr_tmpl} > ${pr_body_temp_file})\n        sed -i \"s/### User Stories\\/Bugs affected\\n\\n/### User Stories\\/Bugs affected\\n\\nAB#${wi_id_azdo}\\n/\" ${pr_body_temp_file}\n        \n        pr_body_arg=\"--body-file ${pr_body_temp_file}\"\n    else\n        pr_body=\"${wi_id_azdo}\"\n        pr_body_arg=\"--body ${pr_body}\"\n    fi\n    \n    # Remove next line when https://github.com/cli/cli/issues/1718 is fixed\n    git push -u origin HEAD\n    \n    echo gh prcr \\\n        --title \"${pr_title}\" \\\n        ${pr_body_arg} \\\n        --draft\n)"
    # prcrwi: "!(\n    # set -x\n    root_dir=$(git rev-parse --show-toplevel)\n    branch_name=$(gh __branch-name)\n    wi_id=$(echo ${branch_name} | awk -F'_' '{print $1}')\n    wi_title=$(echo ${branch_name} | awk -F'_' '{print $2}')\n\n    wi_id_azdo=$(echo ${wi_id} | tr '-' '#')\n    wi_id_azdo_num=$(echo ${wi_id_azdo} | awk -F'#' '{print $2}')\n    wi_title_azdo=$(echo ${wi_title} | tr '-' ' ')\n\n    pr_title=\"${wi_id_azdo} ${wi_title_azdo}\"\n    \n    # if there is pull_request_template.md file in the .github folder, use it as pr body\n    # pr_tmpl=${root_dir}/.github/pull_request_template.md\n    # Force not enter\n    pr_tmpl=${root_dir}/.github/pull_request_template.md\n    pr_body_temp_file=$(mktemp -t pr_body_XXXXX.md)\n    chmod 666 ${pr_body_temp_file}\n    #trap \"rm -f ${pr_body_temp_file}\" EXIT\n\n    if [ -f \"${pr_tmpl}\" ]; then\n        # Modify the template using sed\n        modified_template=$(cat \"${pr_tmpl}\")\n        modified_template=$(echo \"${modified_template}\" | sed '/<!--/,/-->/d')\n        modified_template=$(echo \"${modified_template}\" | sed \"s@### User Stories/Bugs affected@### User Stories/Bugs affected\\n\\nRelated ${wi_id_azdo}@\")\n        modified_template=$(echo \"${modified_template}\" | sed 's@### Other systems impacted@### Other systems impacted\\n\\n- N/A@')\n        modified_template=$(echo \"${modified_template}\" | sed 's@- \\[ \\] No@- [x] No@')\n        # Remplace double empty lines with one empty line\n        modified_template=$(echo \"${modified_template}\" | sed ':L;N;s/^\\n$//;t L')\n        echo \"${modified_template}\" > ${pr_body_temp_file}\n        \n        pr_body=\"${pr_body_temp_file}\"\n    else\n        pr_body=\"${wi_id_azdo}\"\n    fi\n    \n    # TODO: Remove next line when https://github.com/cli/cli/issues/1718 is fixed\n    git push -u origin HEAD\n\n    bash -c \"gh prcr \\\n        --title \\\"${pr_title}\\\" \\\n        --body-file \\\"${pr_body_temp_file}\\\" \\\n        --draft\"\n)"
    

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
        --body-file \"${pr_body}\" \
        --draft"
}