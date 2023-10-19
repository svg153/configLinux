# copy a branch from one repo to other
# usage: copy-branch.sh <branch> <from-repo> <to-repo>

if [ $# -ne 3 ]; then
    echo "usage: copy-branch.sh <from-repo> <to-repo>"
    exit 1
fi

branch=$1
from=$2
to=$3
base_branch=main

cd $from
gh prco
branch=$(gh pr view --json headRefName | jq -r '.headRefName')
# get the pr diff from default branch to the branch we want to copy
pr_diff=$(gh pr diff)
# get pr information
pr_info=$(gh pr view --json title,body)
cd ..

cd $to
# create a new branch from default branch
git checkout -b $branch origin/${base_branch}
# apply the pr diff
echo "$pr_diff" | git apply -
git add .
git commit -m "copy $branch from $from"
git push origin $branch
# create a new pr
pr_title=$(echo "$pr_info" | jq -r '.title')
pr_body=$(echo "$pr_info" | jq -r '.body')
gh pr create \
    --title "$pr_title" \
    --body "$pr_body" \
    --base ${base_branch}
cd ..

# clean up
rm -rf $from $to

# clean up
cd ..
rm -rf $from
rm -rf $to
