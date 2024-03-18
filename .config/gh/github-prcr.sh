#!/bin/bash

function github-__prcr() {
    # !(\n    root_dir=$(git rev-parse --show-toplevel)\n    branch_name=$(gh __branch-name)\n    title=$(echo ${branch_name} | tr '-' ' ')\n    \n    pr_title=\"${1:-${title}}\"\n    pr_body=\"${2:-${title}}\"\n    \n    # TODO: Remove next line when https://github.com/cli/cli/issues/1718 is fixed\n    git push -u origin HEAD\n    gh prcr \\\n        --title \"${pr_title}\" \\\n        --body \"${pr_body}\" \\\n        --draft\n)"
    branch_name=$(gh __branch-name)
    title=$(echo ${branch_name} | tr '-' ' ')
    
    pr_title="${1:-${title}}"
    pr_body="${2:-${title}}"
    
    # TODO: Remove next line when https://github.com/cli/cli/issues/1718 is fixed
    git push -u origin HEAD
    gh prcr --title "${pr_title}" --body "${pr_body}" --draft
}