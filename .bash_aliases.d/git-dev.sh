

alias git-clone='git-clone() { fullRepoPath="$1"; repoNameGit=$(basename "$fullRepoPath"); repoName="${repoNameGit%.*}"; mkdir -p ~/REPOSITORIOS/$repoName; git clone "$1"}; git-clone'
alias git-new='git-new() { fullRepoPath="$1"; repoNameGit=$(basename "$fullRepoPath"); repoName="${repoNameGit%.*}"; mkdir -p ~/REPOSITORIOS/$repoName; echo "# $repoName" >> README.md; git init; git add README.md; git commit -m "first commit"; git remote add origin $1; git push -u origin master}; git-new'

# TODO: Check
# new-repo() { fullRepoPath="$1"; repoNameGit=$(basename "$fullRepoPath"); repoName="${repoNameGit%.*}"; mkdir -p ~/REPOSITORIOS/$repoName};