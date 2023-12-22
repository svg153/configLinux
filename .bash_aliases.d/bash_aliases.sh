#!/usr/bin/env bash

alias edit_aliases="nano ~/.aliases && source ~/.aliases"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
cdf() {
    cd $(dirname $1)
}

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias s="source"
alias sa="source .alias"

alias hgrep="grep -rni"
alias hgrepcodews="hgrep $1 * | cut -d ":" -f 1  | sort -u | cut -d "/" -f 1-7 | sort -u"

alias ctar="tar cf"
alias untar="tar xf"

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


#
# TOOLs
#



#
# TOOLs
#

# REPOS

notas() {
    code ~/REPOSITORIOS/0_PERSONAL/notes/
}