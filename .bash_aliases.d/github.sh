
github-clone-all(){
    user="$1"
    
    gh repos-name-all "${user}" | xargs -I '%' gh clo "${user}" %
    # OR
    # gh clone-org -p "${user}" -y "${user}"
}

# check if the command is being installed, if so, install the alias
# otherwise, run the command
command -v github-copilot-cli >/dev/null 2>&1
if [ $? -eq 0 ]; then
    eval "$(github-copilot-cli alias -- "$0")"
fi