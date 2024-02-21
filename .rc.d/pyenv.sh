# pyenv
# https://github.com/pyenv/pyenv
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    command -v pyenv 1>/dev/null 2>&1 || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi