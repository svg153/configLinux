# gh PR review cookbook (stable facts)

> Use per-command host override for GHE (derive host from the repo remote):
> `GHE_HOST="${GHE_HOST:-$(git config --get remote.origin.url | sed -E 's#.*@([^/:]+).*#\1#')}"`
> `GH_HOST="$GHE_HOST" gh ...`

## Quick auth / host sanity
- `gh auth status`

## PR metadata
- `gh pr view <PR_URL> --json title,body,baseRefName,headRefName,author,labels,url`

## Files touched (no counts)
- `gh pr diff <PR_URL> --name-only`

## Checks
- `gh pr checks <PR_URL>`

## Commits (for intent and ticket IDs)
- `gh pr view <PR_URL> --json commits`

## If you need raw API access
- Repo from PR URL: owner/repo
- PR number: parse from URL
- Then:
  - `gh api repos/<owner>/<repo>/pulls/<number>`
  - `gh api repos/<owner>/<repo>/pulls/<number>/files`

## Notes
- Don’t report additions/deletions or file counts in the final narrative.
- Prefer grouping by folder (e.g., `ansible/roles/...`, `docs/...`, `.github/...`).
