

alias g="git"

# git gui
alias ggui="g gui &> /dev/null &"
alias gg=ggui

alias gci="g commit"
alias gco="g checkout"
alias gst="g status"
alias gres="g unstage"
alias gunstage="gres"
alias gu="gunstage"
alias gdis="g discart"
alias gdiscart="gdis"
alias glast="g log -1 HEAD"
alias gcbt="g co -t origin"
alias gsave="g stash"
alias gpop="g stash pop"

alias git-update='g stash && git pull && git stash pop'
alias git-update-branch-from-dev="g pull origin develop"

# Needs alias in gitconfig
alias git-st="g st"
alias git-ci="g ci"
alias git-co="g co"
alias git-unstage="g unstage"
alias git-discart="g discart"
alias git-last="g last"


# 
alias gri="g"
alias gti="g"
alias gir="g"