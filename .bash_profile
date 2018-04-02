

# BASED:
#     * https://www.cyberciti.biz/tips/howto-linux-unix-bash-shell-setup-prompt.html
#     * https://coderwall.com/p/fasnya/add-git-branch-name-to-bash-prompt
#     * https://github.com/PeterCrozier/dot-files/blob/master/.bash_profile
#     *

# Return the current git branch, if any
# Must be exported as it is used in PS1.
function GetGitBranch
{
    ref=$(git symbolic-ref HEAD 2>/dev/null) || return
    echo " ["${ref#refs/heads/}"]"
}
export -f GetGitBranch


# console escape sequences must be included in \[ and \] to avoid moving the cursor
RED="\[$(tput setaf 1)\]"
GRN="\[$(tput setaf 2)\]"
LGRN="\[\033[01;32m\]"
BLU="\[$(tput setaf 4)\]"
LBLU="\[\033[01;34m\]"
RST="\[$(tput sgr0)\]"
export PS1="$LGRN\u@\h:$LBLU\w$RED\$(GetGitBranch) $BLU\$(date +%H:%M:%S)$RST\n $ "
export SUDO_PS1="$RED\w $BLU\u$RST # "
