# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=~/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"
#ZSH_THEME="agnoster"

#ZSH_THEME="powerlevel9k/powerlevel9k"
#POWERLEVEL9K_MODE='awesome-fontconfig'
#POWERLEVEL9K_MODE='awesome-patched'
#POWERLEVEL9K_MODE='flat'
#POWERLEVEL9K_MODE='compatible'

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd/mm/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(textmate lighthouse)
plugins+=(git git-extras gitfast git-flow git-flow-avh github git-hubflow gitignore git-prompt git-remote-branch)
plugins+=(django node ruby perl python spring)
plugins+=(rake rails jsontools)
plugins+=(bundler pip npm bower brew cloudapp)
plugins+=(docker boot2docker docker-compose)
plugins+=(autojump colored-man-pages colorize extract z)
plugins+=(zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-output-highlighting)
autoload -U compinit && compinit

#syntax highlighters for the zsh-syntax-highlighting plugin
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern root)

source $ZSH/oh-my-zsh.sh



# User configuration

# personal configs for plugins
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=white'

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi


# include Z, yo
if [ -f ~/.z.sh ]; then
    . ~/.z.sh
fi

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

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="gedit ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# rvm env
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
[[ -e "$HOME/.rvm/bin" ]] && export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# set PATH if texlive exists
## https://en.wikibooks.org/wiki/LaTeX/Installation#.2ABSD_and_GNU.2FLinux
TEXLIVE_PATH=/usr/local/texlive/2016/
if [ -d $TEXLIVE_PATH ] ; then
    PATH=$PATH:$TEXLIVE_PATH/bin/x86_64-linux
    INFOPATH=$INFOPATH:$TEXLIVE_PATH/texmf-dist/doc/info
    MANPATH=$MANPATH:$TEXLIVE_PATH/texmf-dist/doc/man
    TEXLIVE_LOG=$TEXLIVE_PATH/install-tl.log
fi

