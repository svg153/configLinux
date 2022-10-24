

alias git-clone='git-clone() { fullRepoPath="$1"; repoNameGit=$(basename "$fullRepoPath"); repoName="${repoNameGit%.*}"; mkdir -p ~/REPOSITORIOS/$repoName; git clone "$1"}; git-clone'
alias git-new='git-new() { fullRepoPath="$1"; repoNameGit=$(basename "$fullRepoPath"); repoName="${repoNameGit%.*}"; mkdir -p ~/REPOSITORIOS/$repoName; echo "# $repoName" >> README.md; git init; git add README.md; git commit -m "first commit"; git remote add origin $1; git push -u origin main}; git-new'

# TODO: Check
# new-repo() { fullRepoPath="$1"; repoNameGit=$(basename "$fullRepoPath"); repoName="${repoNameGit%.*}"; mkdir -p ~/REPOSITORIOS/$repoName};

meta_repo_update(){
    meta_repo_action "pull"
}

meta_repo_status(){
    meta_repo_action "status"
}

meta_repo_action(){
    [ "$#" -ne 1 ] && echo "Usage: meta_repo_action <action>" && return 1
    local action=$1
    for repo in ls -d */; do
        if [ -f ${repo}/.git/config ]; then
            echo "Repo: ${repo}"
            cd "${repo}" || continue
            git "${action}"
            cd - > /dev/null || continue
            echo "---"
        fi
    done
}