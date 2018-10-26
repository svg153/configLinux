# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -f ~/.bash_profile ]; then
    . ~/.bash_profile
fi

#
# -> functions
#

# extraer () {
#     if [ $# -gt 0 ] ; then
#         if [ -f $1 ] ; then
#             case $1 in
#                 *.tar.bz2)   tar xvf $1        ;;
#                 *.tar.gz)    tar xvf $1     ;;
#                 *.tar.xz)    tar xvf $1     ;;
#                 *.tar.lzma)  tar xvf $1     ;;
#                 *.xz)        xz -d $1     ;;
#                 *.ar)        tar xvf $1     ;;
#                 *.lzma)      tar xvf $1     ;;
#                 *.tar.7z)    tar xvf $1     ;;
#                 *.cbz)       tar xvf $1     ;;
#                 *.bz2)       bunzip2 $1       ;;
#                 *.rar)       unar $1     ;;
#                 *.gz)        gunzip $1     ;;
#                 *.tar)       tar xvf $1        ;;
#                 *.tbz2)      tar xvf $1      ;;
#                 *.tgz)       tar xvf $1       ;;
#                 *.zip)       unzip $1     ;;
#                 *.Z)         uncompress $1  ;;
#                 *.7z)        7z x $1    ;;
#                 *)           echo "No se como descrimir este formato de fichero '$1'..." ;;
#             esac
#         else
#             echo "'$1' no es un fichero valido"
#         fi
#    else
#         echo "se necesita un fichero para estraer: extraer /home/ficheoComprimido.ext | ext = {extension fichero comprimido}"
#    fi
# }

extract () {
	local remove_archive
	local success
	local extract_dir
	if (( $# == 0 )) || [[ "$1" = "-h" ]] || [[ "$1" = "--help" ]]
	then
		cat <<'EOF' >&2
Usage: extract [-option] [file ...]

Extension:
    *.tar.bz2|*.tbz|*.tbz2|*.tar.xz|*.txz|*.tar.zma|*.tlz|*.tar|*.gz|*.bz2|*.xz|*.lzma|*.Z|*.zip|*.war|*.jar|*.sublime-package|*.ipsw|*.xpi|*.apk|*.rar|*.7z|*.deb

Options:
    -h, --help      Print this.
    -r, --remove    Remove archive.
EOF
	fi
	remove_archive=1
	if [[ "$1" = "-r" ]] || [[ "$1" = "--remove" ]]
	then
		remove_archive=0
		shift
	fi
	while (( $# > 0 ))
	do
		if [[ ! -f "$1" ]]
		then
			echo "extract: '$1' is not a valid file" >&2
			shift
			continue
		fi
		success=0
		extract_dir="${1:t:r}"
		case "$1" in
			(*.tar.gz|*.tgz) (( $+commands[pigz] )) && {
					pigz -dc "$1" | tar xv
				} || tar zxvf "$1" ;;
			(*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$1" ;;
			(*.tar.xz|*.txz) tar --xz --help &> /dev/null && tar --xz -xvf "$1" || xzcat "$1" | tar xvf - ;;
			(*.tar.zma|*.tlz) tar --lzma --help &> /dev/null && tar --lzma -xvf "$1" || lzcat "$1" | tar xvf - ;;
			(*.tar) tar xvf "$1" ;;
			(*.gz) (( $+commands[pigz] )) && pigz -d "$1" || gunzip "$1" ;;
			(*.bz2) bunzip2 "$1" ;;
			(*.xz) unxz "$1" ;;
			(*.lzma) unlzma "$1" ;;
			(*.Z) uncompress "$1" ;;
			(*.zip|*.war|*.jar|*.sublime-package|*.ipsw|*.xpi|*.apk) unzip "$1" -d $extract_dir ;;
			(*.rar) unrar x -ad "$1" ;;
			(*.7z) 7za x "$1" ;;
			(*.deb) mkdir -p "$extract_dir/control"
				mkdir -p "$extract_dir/data"
				cd "$extract_dir"
				ar vx "../${1}" > /dev/null
				cd control
				tar xzvf ../control.tar.gz
				cd ../data
				extract ../data.tar.*
				cd ..
				rm *.tar.* debian-binary
				cd .. ;;
			(*) echo "extract: '$1' cannot be extracted" >&2
				success=1  ;;
		esac
		(( success = $success > 0 ? $success : $? ))
		(( $success == 0 )) && (( $remove_archive == 0 )) && rm "$1"
		shift
	done
}





#
# <- functions
#



# rvm env
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

[[ -e "$HOME/.rvm/bin" ]] && export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
