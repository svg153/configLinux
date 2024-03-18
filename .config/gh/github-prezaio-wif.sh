#!/bin/bash

function github-prezaio-wif() {
    # wif: "!(\n    project=PaymentPlatform\n    IterationPath=\"${project}\\Sprint $(date +%Y-%V)"\n    azdo_web=\"https://dev.azure.com/pezaio\"\n    az boards query --org ${azdo_web} --project ${project} \\\n        --wiql \"SELECT [System.Id] FROM workitems WHERE [System.WorkItemType] = 'User Story' AND ([System.State] = 'ToDo' OR [System.State] = 'Active') AND [System.IterationPath] = \\\"${IterationPath}\\\"\"  \\\n        --query '[*].{id:id}' \\\n        --output tsv \\\n    | xargs --max-args 1 --max-procs 8 -I '%' sh -c \\\n        \"az boards work-item show --id '%' --org ${azdo_web} --output json | jq -r '.fields | {id: .\\\"System.Id\\\", title: .\\\"System.Title\\\", state: .\\\"System.State\\\", assigned: .\\\"System.AssignedTo.displayName\\\" } | [.id, .title, .state, .assigned] | @tsv'\" \\\n    | fzf --delimiter '\\t' \\\n        --preview \"az boards work-item show --id {1} --org ${azdo_web} --output json | jq -r '.fields.\\\"System.Description\\\"' | w3m -dump -T text/html\" \\\n    | awk '{print $1}'\n    \n    # | xargs gh pezaio-new-branch\n)"
    project=PaymentPlatform
    IterationPath="${project}\Sprint $(date +%Y-%V)"
    azdo_web="https://dev.azure.com/pezaio"
    az boards query --org ${azdo_web} --project ${project} \
        --wiql "SELECT [System.Id] FROM workitems WHERE [System.WorkItemType] = 'User Story' AND ([System.State] = 'ToDo' OR [System.State] = 'Active') AND [System.IterationPath] = "  \"${IterationPath}\""  \
        --query '[*].{id:id}' \
        --output tsv \
    | xargs --max-args 1 --max-procs 8 -I '%' sh -c \
        "az boards work-item show --id '%' --org ${azdo_web} --output json | jq -r '.fields | {id: ."  System.Id"  , title: ."  System.Title"  , state: ."  System.State"  , assigned: ."  System.AssignedTo.displayName"   } | [.id, .title, .state, .assigned] | @tsv'" \
    | fzf --delimiter '\t' \
        --preview "az boards work-item show --id {1} --org ${azdo_web} --output json | jq -r '.fields."System.Description"  ' | w3m -dump -T text/html" \
    | awk '{print $1}'
    # | xargs gh pezaio-new-branch\n)"   
}