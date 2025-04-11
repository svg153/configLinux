#!/bin/bash

function usage() {
  echo "Usage: $0 <JIRA_ISSUE_KEY>"
  echo "Example: $0 ADS-1234"
}

# Check if jq is installed
if ! command -v jq &>/dev/null; then
  echo "jq could not be found. Please install jq to run this script."
  exit 1
fi

# Check if git is installed
if ! command -v git &>/dev/null; then
  echo "git could not be found. Please install git to run this script."
  exit 1
fi

# Check if jira-cli is installed
if ! command -v jira &>/dev/null; then
  echo "jira-cli could not be found. Please install jira-cli (https://github.com/ankitpokhrel/jira-cli) to run this script."
  exit 1
fi

# Check if Jira issue key is provided
if [ -z "$1" ]; then
  usage
  exit 1
fi

# Check if the provided argument is a valid Jira issue key
JIRA_ISSUE_KEY=$1
# JIRA_API_URL="https://your-jira-instance.atlassian.net/rest/api/2/issue/$JIRA_ISSUE_KEY"
# JIRA_USERNAME="your-jira-username"
# JIRA_API_TOKEN="your-jira-api-token"
# response=$(curl -s -u $JIRA_USERNAME:$JIRA_API_TOKEN -X GET -H "Content-Type: application/json" $JIRA_API_URL)

# Fetch issue details from Jira
#
response=$(jira issue view $JIRA_ISSUE_KEY --raw)

# Extract issue title
issue_title=$(echo $response | jq -r '.fields.summary')
if [ -z "$issue_title" ]; then
  echo "Error: Unable to fetch issue title for $JIRA_ISSUE_KEY."
  exit 1
fi

# Convert title to lowercase and replace spaces with hyphens
branch_title=$(echo $issue_title | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# Create branch name
branch_name="${JIRA_ISSUE_KEY}_${branch_title}"

# Create the branch
git checkout -b $branch_name

echo "Branch '$branch_name' created successfully."
