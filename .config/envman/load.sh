# Generated for envman. Do not edit.
# shellcheck disable=SC1090

touch -a ~/.config/envman/PATH.env
touch -a ~/.config/envman/ENV.env
touch -a ~/.config/envman/alias.env
touch -a ~/.config/envman/function.sh

# ENV first because we may use it in PATH
test -z "${ENVMAN_LOAD:-}" && . ~/.config/envman/ENV.env
test -z "${ENVMAN_LOAD:-}" && . ~/.config/envman/PATH.env

export ENVMAN_LOAD='loaded'

# function first because we may use it in alias
test -z "${g_envman_load_sh:-}" && . ~/.config/envman/function.sh
test -z "${g_envman_load_sh:-}" && . ~/.config/envman/alias.env

g_envman_load_sh='loaded'
