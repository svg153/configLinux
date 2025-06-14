# SCRIPT_DIR

# source ./gh-fzf/ghf.bash

# Set GH_BROWSER to explorer.exe only if running in WSL
isWSL=$(uname -a | grep WSL | wc -l)
if [ $isWSL -gt 0 ]; then
    export GH_BROWSER=explorer.exe
fi