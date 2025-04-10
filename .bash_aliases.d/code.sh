alias c="code ."

__get_eddited_files_in_current_branch(){
    declare -a files
    # open all the file added and modified in the current branch in vscode
    while IFS= read -r line; do
        files+=("$(git rev-parse --show-toplevel)/${line}")
    done < <(git diff --name-only origin/main...HEAD)
    echo "${files[@]}"
}

alias cprf="codeprfiles"
alias ccodeprf="codeprfiles"
codeprfiles(){
    declare -a files
    files=( $(__get_eddited_files_in_current_branch) )
    echo "Files added and modified in the current branch:"
    echo "----------------------------------------"
    for file in "${files[@]}"; do
        echo - "$file"
    done
}

alias cpr="codeprfiles"
codepr(){
    declare -a files
    files=( $(__get_eddited_files_in_current_branch) )
    if [ ${#files[@]} -gt 0 ]; then
        echo "Opening ${#files[@]} files in vscode"
        code "${files[@]}"
    else
        echo "No files to open."
    fi
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