alias g="git"

alias dw="g pull"
alias pu="g push"

alias gswm="g switch main"
alias gps="g push"
alias gplp="g pull --prune"
alias gci="g commit"
alias gco="git-checkout-scm"
alias gst="g status"
alias gres="g unstage"
alias gunstage="gres"
alias gdis="g discart"
alias gdiscart="gdis"
alias glast="g log -1 HEAD"
alias gcbt="g co -t origin"

# Stash
alias gsave="g stash"
alias gsv="gsave"
alias gpop="g stash pop"

alias git-update='g stash && g pull && g stash pop'
alias gu='git-update'
alias git-update-branch-from-main="g pull origin main"
alias git-update-branch-from-dev="g pull origin develop"

alias mas="g stash && g switch main && g pull && g stash pop"
# alias mas=s"git stash && git sw main && git pull && git sw - && git rebase main && git stash pop"

# git gui
alias ggui="g gui &> /dev/null &"

# Needs alias in gitconfig
alias git-st="g st"
alias git-branch-name="g branch-name"
alias git-ci="g ci"
alias git-co="g co"
alias git-unstage="g unstage"
alias git-discart="g discart"
alias git-last="g last"

# Typos
alias gi="g"
alias gri="g"
alias gti="g"
alias gir="g"
alias igt="g"

git-checkout-scm(){
    # """
    # checkout a branch or list all branches to select one
    #
    # Args:
    #     branch_name (str): The name of the branch
    #
    # Returns:
    #     str: The name of the branch
    # """
    
    local branch_name="$1"
    if [ "$#" -eq 1 ]; then        # list all branches to select one
        g co "$branch_name"
    else
        # list all branches local and remotes to select one
        branch_selected=$(g branch -a | fzf)
        if [ -z "$branch_selected" ]; then
            echo "No branch selected" >&2
            return 1
        fi
        if [[ "$branch_selected" =~ ^remotes/ ]]; then
            branch_selected=$(echo "$branch_selected" | awk -F'/' '{print $3}')
        fi
        g co "$branch_selected"
    fi
}

git-checkout-prs(){
    # """
    # checkout PRs
    # """
    
    # Get all PRs from the repository depending of the SCM that is being used
    # get remote URL to determine the SCM
    remote_url=$(g remote get-url origin)
    case "$remote_url" in
        *github.com*)
            prs=$(gh pr list -s all | fzf)
            ;;
        *dev.azure.com*)
            prs=$(azdo-prs)
            ;;
        *)
            prs=$(g pr list -s all | fzf)
            ;;
    esac
    # list all branches local and remotes to select one
    branch_selected=$(g branch -a | fzf)
    if [ -z "$branch_selected" ]; then
        echo "No branch selected" >&2
        return 1
    fi
    if [[ "$branch_selected" =~ ^remotes/ ]]; then
        branch_selected=$(echo "$branch_selected" | awk -F'/' '{print $3}')
    fi
    g co "$branch_selected"
}

get-my-commits(){
    if [ "$#" -lt 2 ]; then
        echo "Usage: get-my-commits AUTHOR_NAME FOLDER_PATH [OUTPUT_FILE]"
        return 1
    fi
    
    local AUTHOR_NAME="${1}"
    local FOLDER_PATH="${2}"
    local OUTPUT_FILE="${3:-commits.json}"

    echo "[" > "$OUTPUT_FILE"

    for folder in $(ls -d "$FOLDER_PATH"/*/); do
        cd "$folder" || continue
        git log \
            --author="$AUTHOR_NAME" \
            --pretty=format:'{%n  "commit": "%H",%n  "title": "%s",%n  "message": "%b",%n  "repository": "'$folder'"%n},' \
            >> "../$OUTPUT_FILE"
        
        cd ..
    done

    sed -i '' -e '$ s/,$//' "$OUTPUT_FILE"
    echo "]" >> "$OUTPUT_FILE"
    echo "Commits are saved in $OUTPUT_FILE"
}
