#!/usr/bin/env bash

alias edit_aliases="nano ~/.aliases && source ~/.aliases"

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias s="source"


alias hgrep="grep -rni"
alias hgrepcodews="hgrep $1 * | cut -d ":" -f 1  | sort -u | cut -d "/" -f 1-7 | sort -u"

alias ctar="tar cf"
alias untar="tar xf"

alias shellcheck='docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'


alias s="source"

alias hgrep="grep -rni"
alias hgrepcodews="hgrep $1 * | cut -d ":" -f 1  | sort -u | cut -d "/" -f 1-7 | sort -u"
docker_enter()
{
  docker run -it "$1" /bin/bash
}

alias ctar="tar cf"
alias untar="tar xf"

alias docker_rm_c_exited="docker ps --filter \"status=exited\" --format \"{{.ID}}\" | awk \'{print \$1}\' | xargs --no-run-if-empty docker rm"

alias shellcheck='docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable'
