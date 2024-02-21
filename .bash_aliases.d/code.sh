alias c="code ."

codepr(){
    declare -a files
    # open all the file added and modified in the current branch in vscode
    while IFS= read -r line; do
        files+=("$(git rev-parse --show-toplevel)/${line}")
    done < <(git diff --name-only origin/main...HEAD)
    code "${files[@]}"    
}

alias conli="codeconfig"
codeconfig(){
    if [ -d ~/REPOSITORIOS/configLinux/ ]; then
        code ~/REPOSITORIOS/configLinux/
    elif [ -d ~/configLinux/ ]; then
        code ~/configLinux/
    else
        echo "No configLinux directory found"
    fi
}