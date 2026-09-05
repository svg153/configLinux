---
name: pr-review-gh
description: 'Review GitHub PRs with gh CLI: fetch PR metadata, diff, checks, changed files, and produce a stable change summary (no volatile metrics like line counts). Use when the user gives a PR URL.'
---

# PR Review with gh CLI

## When to Use
- User provides a GitHub PR URL and wants a **review-style summary** of what changed.
- Need to gather **ground truth** from the PR (title/body/commits/files/diff/checks) using `gh`.
- GitHub Enterprise (GHE) URLs like `https://$GHE_HOST/<ORG>/<REPO>/pull/<N>`.

## Non‑Negotiable Constraints
- **Never** include volatile metrics (e.g., “$N$ lines changed”, “$N$ files changed”, “$N$ commits”).
- **Never** leak secrets/tokens or paste sensitive env values.
- **Never** claim a check/test passed unless you verified it via `gh pr checks`.
- Prefer **file paths + intent** over raw diff dumps.

## Procedure

### 1) Determine the correct GitHub host
1. Extract the host from the PR URL (domain), or derive it from the repository remote:
   - `export GHE_HOST="${GHE_HOST:-$(git config --get remote.origin.url | sed -E 's#.*@([^/:]+).*#\1#')}"`
2. Prefer running `gh` with a **per-command** host override:
   - `GH_HOST="$GHE_HOST" gh ...`
3. If unsure what hosts are configured, check:
   - `gh auth status`

> Tip: For internal GHE, derive the host with the command above instead of hardcoding it.

### 2) Collect PR metadata (stable facts)
Fetch PR metadata **without** using or reporting additions/deletions:
- Title, body, base/head branches, author, labels, reviews requested
- Files list (paths only)
- Commit messages (for ticket IDs + intent)

Suggested commands (pick what you need):
- View PR:
  - `GH_HOST=<host> gh pr view <PR_URL> --json title,body,baseRefName,headRefName,author,labels,url`
- List commits:
  - `GH_HOST=<host> gh pr view <PR_URL> --json commits`
- List files (paths):
  - `GH_HOST=<host> gh pr diff <PR_URL> --name-only`

### 3) Inspect the diff efficiently
- Start with `--name-only` to find hot spots.
- Then view the patch selectively (by file or by section) to avoid context overload.

Examples:
- Full patch (use sparingly):
  - `GH_HOST=<host> gh pr diff <PR_URL>`
- Focus on a file:
  - Use `gh api` to fetch the raw file from `head` if needed.

### 4) Check CI status / checks
- `GH_HOST=<host> gh pr checks <PR_URL>`

Only report:
- Which checks exist (by name)
- Whether they are passing/failing/neutral
- Actionable failure context

### 5) Detect repo PR template
Look for templates in:
- `.github/pull_request_template.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/pull_request_template/*`

If present, the PR description should **follow it**.

## Output: What you must produce
A stable PR summary (Markdown) that includes:
- What changed (by area/module)
- Why (derived from PR body + commits)
- Impact (runtime/config/ops/dev ergonomics)
- How it fits with existing design
- Risks & rollout
- Verification (based on checks + suggested manual steps)

Avoid volatile counts; prefer “touches X/Y/Z areas” and list the **paths**.

## References
- Command cookbook: [gh-playbook](./assets/gh-playbook.md)
