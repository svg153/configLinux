alias c="code ."

codepr(){
    declare -a files
    # open all the file added and modified in the current branch in vscode
    while IFS= read -r line; do
        files+=("$(git rev-parse --show-toplevel)/${line}")
    done < <(git diff --name-only origin/main...HEAD)
    code "${files[@]}"    
}

codeconfig(){
    code ~/configLinux
}