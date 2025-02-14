# needs az and az azure-devops extension installed
# needs az devops login and configure with default organization
azdo-item-title(){
    # """
    # Get the title of a work item
    #
    # Args:
    #     wi_id (str): The id of the work item
    #
    # Returns:
    #     str: The title of the work item
    # """

    local wi_id="$1"

    if [ "$#" -ne 1 ]; then
        echo "Illegal number of parameters" >&2
        return 1
    fi

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
    # """
    # Get the status of a work item
    #
    # Args:
    #     wi_id (str): The id of the work item
    #
    # Returns:
    #     str: The status of the work item
    # """

    local wi_id="$1"

    if [ "$#" -ne 1 ]; then
        echo "Illegal number of parameters" >&2
        return 1
    fi

    az boards work-item show \
        --id "${wi_id}" \
        --output json \
        --query 'fields."System.Status"'
}
azdo-branch-title(){
    # """
    # Get the title of a work item
    #
    # Args:
    #     wi_id (str): The id of the work item
    #
    # Returns:
    #     str: The title of the work item
    # """

    local wi_id="$1"

    if [ "$#" -ne 1 ]; then
        echo "Illegal number of parameters" >&2
        return 1
    fi

    local wi_title="$(azdo-item-title "${wi_id}")"

    echo "AB-${wi_id}_${wi_title}"
}

azdo-new-branch(){
    # """
    # Create a new branch from a work item
    #
    # Args:
    #     wi_id (str): The id of the work item
    #
    # Returns:
    #     str: The title of the work item
    # """

    azdo-branch-title "$1" | xargs git sw -c
}

azdo-item-parent-id(){
    # """
    # Get the parent id of a work item
    #
    # Args:
    #     wi_id (str): The id of the work item
    #
    # Returns:
    #     str: The id of the parent work item
    # """

    local wi_id="$1"

    if [ "$#" -ne 1 ]; then
        echo "Illegal number of parameters" >&2
        return 1
    fi

    az boards work-item show \
        --id "${wi_id}" \
        --output json \
        --query 'fields."System.Parent"'
}


azdo-item-create(){
    # """
    # Create a new work item
    #
    # Args:
    #     wi_type (str): The type of work item to create
    #     wi_title (str): The title of the new work item
    #     wi_assigned_to (str): The id of the user to assign the new work item
    #     wi_parent_id (str): The id of the parent work item
    #
    # Returns:
    #     str: The id of the new work item
    # """

    local wi_type="$1"
    local wi_title="$2"
    local wi_assigned_to="$3"
    local wi_parent_id="$4"

    if [ "$#" -ne 4 ]; then
        echo "Illegal number of parameters" >&2
        return 1
    fi

    wi_id=$(az boards work-item create \
        --type "${wi_type}" \
        --title "${wi_title}" \
        --output json \
        --query 'id' \
    )
    # TODO:
    # --assigned-to "${wi_assigned_to}" \

    if [[ "${wi_id}" == *"error"* ]]; then
        echo "Error creating work item" >&2
        return 1
    fi

    az boards work-item relation add \
        --id "${wi_id}" \
        --relation-type parent \
        --target-id "${wi_parent_id}" \
    > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "Error adding parent relation" >&2
        return 1
    fi

    echo "${wi_id}"
    # az boards work-item update --id 1 --fields "System.Title=My updated work item title" "System.Description=My updated work item description" --output json | jq .id
    # az boards work-item relation add --id 1 --relation-type "System.LinkTypes.Hierarchy-Reverse" --target-id 2 --output json | jq .id
}

azdo-item-url(){
    # """
    # Get the url to a work item
    #
    # Args:
    #     wi_id (str): The id of the work item
    #
    # Returns:
    #     str: The url to the work item
    # """

    local wi_id="$1"

    if [ "$#" -ne 1 ]; then
        echo "Illegal number of parameters" >&2
        return 1
    fi

    local org_url="$(az devops configure --list | grep "organization" | cut -d' ' -f3)"
    local project="$(az devops configure --list | grep "project" | cut -d' ' -f3)"
    local wi_url="${org_url}/${project}/_workitems/edit/${wi_id}"

    echo "${wi_url}"
}

azdo-item-open(){
    local wi_id="$1"

    if [ "$#" -ne 1 ]; then
        echo "Illegal number of parameters" >&2
        return 1
    fi

    az boards work-item show \
        --id "${wi_id}" \
        --open \
    > /dev/null
}

azdo-prs(){
    # """
    # Get all PRs from the repository
    #
    # Returns:
    #     str: The url to the work item
    # """

    az repos pr list --output json \
        | jq -r '.[] | "\(.pullRequestId) - \(.title)"' \
        | fzf
}

azdo-prcrwi(){
    # """
    # Create a PR from a work item taken from the current branch name
    #
    # """

    echo "implented in gh alias"
}