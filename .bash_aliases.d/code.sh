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

alias notes="codenotes"
codenotes(){
    if [ -d ~/REPOSITORIOS/0_PERSONAL/notes/ ]; then
        code ~/REPOSITORIOS/0_PERSONAL/notes/
    elif [ -d ~/REPOSITORIOS/notes/ ]; then
        code ~/REPOSITORIOS/notes/
    elif [ -d ~/notes/ ]; then
        code ~/notes/
    else
        echo "No notes directory found"
    fi
}