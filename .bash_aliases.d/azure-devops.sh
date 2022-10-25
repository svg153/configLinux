# needs az and az azure-devops extension installed
# needs az devops login and configure with default organization 
azdo-item-title(){
    local wi_id="$1"

    az boards work-item show \
        --id "${wi_id}" \
        --output json \
        --query 'fields."System.Title"' \
        | tr '[:upper:]' '[:lower:]' \
        | tr -d '!"#$%&'"'"'()*+,./:;<=>?@[\\]^_`{|}~-' \
        | sed -e 's/[ \t]*$//' \
        | tr ' ' '-'
}
azdo-item-status(){
    local wi_id="$1"

    az boards work-item show \
        --id "${wi_id}" \
        --output json \
        --query 'fields."System.Status"'
}
azdo-branch-title(){
    local wi_id="$1"
    local wi_title="$(azdo-item-title "${wi_id}")"
    
    echo "AB-${wi_id}_${wi_title}"
}

azdo-new-branch(){
    azdo-branch-title "$1" | xargs git sw -c
}