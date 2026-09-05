---
name: ticket-context-jira-github
description: 'Enrich PR summaries using Jira tickets (e.g., PROJ-123) or GitHub Issues/refs. Detect IDs from PR title/body/commits, then fetch objective/context via jira CLI or gh CLI. Use when PR references a ticket/issue.'
---

# Ticket Context (Jira + GitHub)

## When to Use
- PR title/body/branch/commit messages include Jira keys like `PROJ-123`.
- PR references GitHub issues like `#123` or `owner/repo#123`.

## Constraints
- If you cannot access Jira/issue data, **do not invent**. Ask for the ticket summary or acceptance criteria.
- Do not paste confidential ticket content if the user didn’t request it; summarize minimally.

## Procedure

### 1) Detect IDs
Search in:
- PR title/body
- Commit messages

Suggested patterns:
- Jira: `\b[A-Z][A-Z0-9]+-\d+\b`
- GitHub issue: `#\d+` or `owner/repo#\d+`

### 2) Jira lookup (preferred: jira CLI)
1. Check if the CLI exists:
   - `jira --help`
2. If available and configured, try viewing the issue:
   - `jira issue view <KEY> --plain`
   - If it supports fields selection, request: summary, description, acceptance criteria.

If Jira CLI is not installed or not configured:
- If Atlassian MCP tools are available/configured, use them.
- Otherwise, ask the user to paste:
  - Ticket summary
  - Goal / acceptance criteria

### 3) GitHub issue lookup (gh)
- `GH_HOST=<host> gh issue view <number> -R <owner>/<repo>`

## Output
Provide 2–6 bullets:
- Goal of the ticket/issue
- Why the PR’s approach matches the goal
- Any implied constraints (e.g., rollout, compatibility)

Avoid quoting long descriptions verbatim.
