#!/bin/bash -x

# List active Jira work items assigned to current user (or all not-done if none assigned),
# show a preview of the description, and create a branch from the selected issue.
if ! command -v "jira" &> /dev/null; then
    echo "jira cli not found, please install https://github.com/ankitpokhrel/jira-cli"
    exit 1
fi

# JQL to prefer issues assigned to current user, falling back to any not-done issue.
JQL_ASSIGNED='assignee = currentUser() AND statusCategory != Done ORDER BY updated DESC'
JQL_ANY='statusCategory != Done ORDER BY updated DESC'

# Try to get JSON output first; fallback to plain list if --output isn't supported.
issues_json=""
echo jira issue list --jql "$JQL_ASSIGNED" --output json 2>/dev/null
issues_json=$(jira issue list --jql "$JQL_ASSIGNED" --output json 2>/dev/null) || true
if [ -z "$issues_json" ]; then
    issues_json=$(jira issue list --jql "$JQL_ASSIGNED" 2>/dev/null) || true
fi
if [ -z "$issues_json" ]; then
    # try any not-done issues
    issues_json=$(jira issue list --jql "$JQL_ANY" --output json 2>/dev/null) || true
    if [ -z "$issues_json" ]; then
        issues_json=$(jira issue list --jql "$JQL_ANY" 2>/dev/null) || true
    fi
fi

if [ -z "$issues_json" ]; then
    echo "No Jira issues found for the queries."
    exit 0
fi

# Parse JSON batches that may use either {"issues": [...]} or a top-level array.
echo "$issues_json" \
    | jq -r '
        if type == "object" and has("issues") then .issues[]
        else .[]
        end
        | [.key, .fields.summary, (.fields.status.name // .fields.status // "-"), (.fields.assignee.displayName // "Unassigned")] | @tsv'

# Pipe to fzf with preview, then create branch from chosen issue key.
echo "$issues_json" \
    | jq -r '
        if type == "object" and has("issues") then .issues[]
        else .[]
        end
        | [.key, .fields.summary, (.fields.status.name // .fields.status // "-"), (.fields.assignee.displayName // "Unassigned")] | @tsv' \
    | fzf --delimiter $'\t' \
        --preview "jira issue get {1} --output json 2>/dev/null | jq -r '.fields.description // .renderedFields.description // "(no description)"' | w3m -dump -T text/html" \
    | awk '{print $1}' \
    | xargs -r -I '%' gh plain-new-branch '%'