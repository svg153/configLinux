alias c="code ."

codepr(){
    declare -a files
    # open all the file added and modified in the current branch in vscode
    while IFS= read -r line; do
        files+=("$(git rev-parse --show-toplevel)/${line}")
    done < <(git diff --name-only origin/main...HEAD)
    code "${files[@]}"    
}

codefolder(){
    f=$1
    if [ -d ~/REPOSITORIOS/0_PERSONAL/${f}/ ]; then
        code ~/REPOSITORIOS/0_PERSONAL/${f}/
    elif [ -d ~/REPOSITORIOS/${f}/ ]; then
        code ~/REPOSITORIOS/${f}/
    elif [ -d ~/${f}/ ]; then
        code ~/${f}/
    else
        echo "No ${f} directory found"
    fi
}

alias conli="codefolder configLinux"
alias notes="codefolder notes"
alias work="codefolder work"