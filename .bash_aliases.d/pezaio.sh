pezaio-new-us-from-us(){
    # """
    # Create a new user story from an existing user story
    #
    # Args:
    #     us_id (str): The id of the user story to copy
    #     us_title (str): The title of the new user story
    #     us_type (str): The type of work item to create. Defaults to "User Story"
    #
    # Returns:
    #     str: The id of the new user story
    # """
    
    local us_id="$1"
    local us_title="$2"
    local us_type="${3:-User Story}"
    
    local assigned_to_me="$(az ad signed-in-user show --query mail)"
    local feature_id="$(azdo-item-parent-id "${us_id}")"
    
    # create a new user story
    local wi_id="$(azdo-item-create \
        "${us_type}" \
        "${us_title}" \
        "${assigned_to_me}" \
        "${feature_id}" \
    )"
    
    local wi_url="$(azdo-item-url "" "${wi_id}")"
    
    echo "${wi_id} - ${wi_url}"
}

pezaio-open-us(){
    local us_id="$1"
    
    azdo-item-open "${us_id}"
}

pezaio-new-branch(){
    local wi_id="$1"
    local wi_title="$(azdo-item-title "${wi_id}")"
    
    git sw -c "AB-${wi_id}_${wi_title}"
}