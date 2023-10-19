

alias g="git"

alias gswm="g switch main"
alias gps="g push"
alias gplp="g pull --prune"
alias gci="g commit"
alias gco="g checkout"
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

alias mas="gswm"
alias mas="g stash && gswm && g pull && g stash pop"
# "git stash && git sw main && git pull && git sw - && git rebase main && git stash pop"

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