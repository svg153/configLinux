#!/bin/bash

function github-wif() {
    gh wif-simple
}

function github-wif-simple() {
    gh azdo-get-active-wi-info \
    | fzf --delimiter '\t' \
    | awk '{print $1}' \
    | xargs -I '%' gh plain-new-branch '%'
}

function github-wif-prev() {
    gh azdo-get-active-wi-info \
    | fzf --delimiter '\t' \
        --preview "az boards work-item show --id {1} --output json | jq -r '.fields.\"System.Description\"  ' | w3m -dump -T text/html" \
    | awk '{print $1}' \
    | xargs -I '%' gh plain-new-branch '%'
}

function azdo-get-active-wi-ids() {
    az boards query  \
        --wiql "SELECT [System.Id] FROM workitems WHERE [System.WorkItemType] = 'User Story' AND ([System.State] = 'ToDo' OR [System.State] = 'Active')" \
        --query "[*].id" \
        --output tsv
}

function azdo-get-active-wi-info() {
    gh azdo-get-active-wi-ids \
    | xargs --max-procs 8 -I '%' sh -c \
        "az boards work-item show --id '%' --output json | jq -r '.fields | {id: .\"System.Id\"  , title: .\"System.Title\"  , state: .\"System.State\"  , assigned: .\"System.AssignedTo.displayName\"   } | [.id, .title, .state, .assigned] | @tsv'"
}

####

function github-wif-all() {
    # NOTE: BUCKUP
    # take project and azdo_web default configured
    # az devops configure --defaults organization=https://dev.azure.com/ZZZZ project="XXXX"
    az boards query  \
        --wiql "SELECT [System.Id] FROM workitems WHERE [System.WorkItemType] = 'User Story' AND ([System.State] = 'ToDo' OR [System.State] = 'Active')" \
        --query "[*].id" \
        --output tsv \
    | xargs --max-procs 8 -I '%' sh -c \
        "az boards work-item show --id '%' --output json | jq -r '.fields | {id: .\"System.Id\"  , title: .\"System.Title\"  , state: .\"System.State\"  , assigned: .\"System.AssignedTo.displayName\"   } | [.id, .title, .state, .assigned] | @tsv'" \
    | fzf --delimiter '\t' \
        --preview "az boards work-item show --id {1} --output json | jq -r '.fields.\"System.Description\"  ' | w3m -dump -T text/html" \
    | awk '{print $1}' \
    | xargs -I '%' gh plain-new-branch '%'
}