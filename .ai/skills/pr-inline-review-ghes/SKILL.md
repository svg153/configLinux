---
name: pr-inline-review-ghes
description: "Create GitHub PR inline review comments on exact changed lines with optional suggested diffs using gh CLI on GHES. Use when user asks to comment specific points directly on PR lines."
---

# PR Inline Review on GHES (with Suggested Changes)

## When to use
- User asks to leave comments **on exact PR lines** (not only general PR comments).
- User wants **suggested diff blocks** (` ```suggestion `) in review comments.
- PR is in GitHub Enterprise Server (custom GHES host).

## Goals
1. Anchor each comment to the correct file and line in the PR.
2. Optionally include a one-click `suggestion` patch.
3. Publish everything as a single review event (`COMMENT`) for traceability.

## Required inputs
- PR number or PR URL
- Repository (`owner/repo`)
- Target points to comment (e.g., point 5/6/9)

## Standard workflow

### 1) Ensure GH host context
- Confirm authenticated host with `gh auth status`.
- For GHES, set host in session before commands:
  - `export GH_HOST=<ghe-host>`

### 2) Get PR head commit
Use `gh pr view` and capture `headRefOid` (or from commits JSON).
- Needed by the reviews API as `commit_id`.

### 3) Resolve exact file + line for each point
For each target issue:
- Read file content at PR head ref (`contents/...?...ref=<commit>`) and show numbered lines (`cat -n`).
- Confirm exact anchor line and side (`RIGHT` for new code in PR).

Tip:
- Never guess line numbers from memory.
- If uncertain, inspect the patch around the candidate line.

### 4) Build review payload JSON
Create one JSON payload with:
- `commit_id`
- `event: "COMMENT"`
- `comments[]` with objects:
  - `path`
  - `line`
  - `side: "RIGHT"`
  - `body`

For comment body style:
- First line: issue summary.
- Then rationale.
- Optional ` ```suggestion ` code block when replacement is small and precise.

### 5) Submit inline review
POST review payload to:
- `repos/<owner>/<repo>/pulls/<pr>/reviews`

### 6) Verify publication
- Check returned `html_url` for review URL.
- Optionally fetch review comments and verify each anchor exists.

## Templates

### A) Single inline comment (no suggestion)
```json
{
  "commit_id": "<head-commit-sha>",
  "event": "COMMENT",
  "comments": [
    {
      "path": "path/to/file.yml",
      "line": 42,
      "side": "RIGHT",
      "body": "Clear explanation of the issue and recommendation."
    }
  ]
}
```

### B) Inline comment with suggested change
```json
{
  "commit_id": "<head-commit-sha>",
  "event": "COMMENT",
  "comments": [
    {
      "path": "path/to/file.yml",
      "line": 42,
      "side": "RIGHT",
      "body": "Why this should change.\n\n```suggestion\n      required: false\n```"
    }
  ]
}
```

## Good practices checklist
- Use PR-template language: actionable, respectful, concise.
- Keep each comment scoped to one issue.
- Prefer suggestion blocks for tiny deterministic edits.
- For larger refactors, comment guidance without huge patches.
- Avoid volatile metrics (file counts, LOC deltas).
- Do not claim checks passed unless verified.

## Common pitfalls
- Wrong line anchors due to using local file instead of PR head commit.
- Suggestion block indentation mismatch in YAML.
- Using general `gh pr comment` instead of review API when inline comments are required.
- Missing GHES host context and posting to wrong host.

## Quick execution map
1. Resolve host/auth
2. Collect head SHA
3. Locate line numbers
4. Build JSON payload
5. Submit review
6. Validate review URL + anchors
