#!/usr/bin/env bash

fzfp() {
    local file
    file=$(fzf --preview 'bat --color=always --style=header,grid --line-range :500 {}') &&
        echo $file
}

fzfcd() {
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune \
        -o -type d -print 2> /dev/null | fzf +m) &&
        cd "$dir"
}