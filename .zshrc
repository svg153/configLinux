### Added by Codeium. These lines cannot be automatically removed if modified
if command -v termium > /dev/null 2>&1; then
  eval "$(termium shell-hook show pre)"
fi
### End of Codeium integration
#
# -> VARS
#

export P10K_ENABLED=false

#
# <- VARS
#

if $P10K_ENABLED; then
    # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
    # Initialization code that may require console input (password prompts, [y/n]
    # confirmations, etc.) must go above this block; everything else may go below.
    if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
    fi
fi

#
# -> functions
#

source ~/.include_d
# export -f include_d TODO: check to do in zsh

#
# <- functions
#



#
# -> ZSH configuration
#

# Path to your oh-my-zsh installation.
export ZSH="/home/svg153/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"
#ZSH_THEME="svg153"

#ZSH_THEME="powerlevel9k/powerlevel9k"
#POWERLEVEL9K_MODE='awesome-fontconfig'
#POWERLEVEL9K_MODE='awesome-patched'
#POWERLEVEL9K_MODE='flat'
#POWERLEVEL9K_MODE='compatible'

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )



# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup
# TO Check all the alias: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/<PLUGIN>
plugins=(gnu-utils history)
plugins+=(colored-man-pages colorize extract)
plugins+=(git git-auto-fetch git-extras git-prompt)
# plugins+=(gitignore) # install alias gi, but i do not use it
plugins+=(gh github) # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gh
plugins+=(perl jsontools)
# plugins+=(java spring mvn)
# plugins+=(node npm)
# plugins+=(ruby rails rake)
plugins+=(python pip)
plugins+=(golang)
plugins+=(docker docker-compose kubectl helm minikube) # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kubectl
plugins+=(azcli) # https://github.com/dmakeienko/azcli
plugins+=(zsh-terraform) # https://github.com/ptavares/zsh-terraform
plugins+=(httpie)
plugins+=(jq) # https://github.com/reegnz/jq-zsh-plugin

# include Z
plugins+=(z)
if [ -f ${ZSH}/plugins/z/z.sh ]; then
    . ${ZSH}/plugins/z/z.sh
fi


# sudo apt-get isntall autojump
plugins+=(autojump)

# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# plugins+=(zsh-autosuggestions)
# https://github.com/zsh-users/zsh-autosuggestions#configuration
# export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=white'

# git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
plugins+=(zsh-syntax-highlighting)
# syntax highlighters for the zsh-syntax-highlighting plugin
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern root)

# git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
plugins+=(zsh-history-substring-search)
# git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
plugins+=(zsh-completions)
# git clone https://github.com/djui/alias-tips.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/alias-tips
plugins+=(alias-tips)
# git clone https://github.com/chrissicool/zsh-256color ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-256color
plugins+=(zsh-256color)

autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases

#
# <- ZSH configuration
#



#
# -> My configuration
#

alias zshconfig="vi ~/.zshrc"
alias ohmyzsh="vi ~/.oh-my-zsh"
if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

if [ -f ~/.rc ]; then
    source ~/.rc
fi

# fonts
# https://github.com/gabrielelana/awesome-terminal-fonts
# TODO: fix "not matches found"
# if [ -f ~/.fonts/*.sh ]; then
#     source ~/.fonts/*.sh
# fi

# starship
# TODO: move to .include_d and modify the include_d to take the shell and pass as a parameter to the function or take automatically from the current shell
# https://github.com/starship/starship
if [ -f "$HOME/.config/starship.toml" ]; then
    eval "$(starship init zsh)"
fi

# powerlevel10k
if $P10K_ENABLED; then
    # https://github.com/romkatv/powerlevel10k
    if [ -d ~/powerlevel10k ]; then
        source ~/powerlevel10k/powerlevel10k.zsh-theme
    fi
    # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
fi

# fzf
# https://github.com/junegunn/fzf?tab=readme-ov-file#upgrading-fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#
# <- My configuration
#

### Added by Codeium. These lines cannot be automatically removed if modified
if command -v termium > /dev/null 2>&1; then
  eval "$(termium shell-hook show post)"
fi
### End of Codeium integration