
# THANKS: https://seb.jambor.dev/posts/improving-shell-workflows-with-fzf/

# function create-branch() {
#   # The function expectes that username and password are stored using secret-tool.
#   # To store these, use
#   # secret-tool store --label="JIRA username" jira username
#   # secret-tool store --label="JIRA password" jira password

#   local jq_template query username password branch_name

#   jq_template='"'\
# '\(.key). \(.fields.summary)'\
# '\t'\
# 'Reporter: \(.fields.reporter.displayName)\n'\
# 'Created: \(.fields.created)\n'\
# 'Updated: \(.fields.updated)\n\n'\
# '\(.fields.description)'\
# '"'
#   query='project=BLOG AND status="In Progress" AND assignee=currentUser()'
#   username=$(secret-tool lookup jira username)
#   password=$(secret-tool lookup jira password)

#   branch_name=$(
#     curl \
#       --data-urlencode "jql=$query" \
#       --get \
#       --user "$username:$password" \
#       --silent \
#       --compressed \
#       'https://jira.example.com/rest/api/2/search' |
#     jq ".issues[] | $jq_template" |
#     sed -e 's/"\(.*\)"/\1/' -e 's/\\t/\t/' |
#     fzf \
#       --with-nth=1 \
#       --delimiter='\t' \
#       --preview='echo -e {2}' \
#       --preview-window=top:wrap |
#     cut -f1 |
#     sed -e 's/\. /\t/' -e 's/[^a-zA-Z0-9\t]/-/g' |
#     awk '{printf "%s/%s", $1, tolower($2)}'
#   )

#   if [ -n "$branch_name" ]; then
#     git checkout -b "$branch_name"
#   fi
# }

function create-branch() {
    set -x

  local jq_template query branch_name

  jq_template='"'\
'\(.key). \(.fields.summary)'\
'\t'\
'Reporter: \(.fields.reporter.displayName)\n'\
'Created: \(.fields.created)\n'\
'Updated: \(.fields.updated)\n\n'\
'\(.fields.description)'\
'"'
  query='status!="Closed" AND assignee=currentUser()'
  selected_issue=$(
    jira issue list --plain -q "$query" --order-by updatedDate \
    | sed -e 's/"\(.*\)"/\1/' -e 's/\\t/\t/' \
    | fzf \
        --delimiter '\t' \
        --header-lines 1 \
        --preview "jira issue view {2} --plain" \
        --preview-window=top:wrap \
    | cut -f1
  )
  
  branch_name=$(
    echo "$selected_issue" |
    sed -e 's/\. /\t/' -e 's/[^a-zA-Z0-9\t]/-/g' |
    awk '{printf "%s/%s", $1, tolower($2)}'
  )

  if [ -n "$branch_name" ]; then
    git checkout -b "$branch_name"
    echo "git push -u origin \"$branch_name\""
  fi
}