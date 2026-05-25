---
applyTo: '**'
---

## Memory

- Use persistent memory tools when available.
- Save proactively after significant work.
- After any context reset, recover relevant context before continuing.

## Working rules

- Prefer diagrams only when they genuinely reduce explanation cost and keep them text-based (`mermaid`, `plantuml`, or similar).
- Never kill broad groups of processes such as every `node`, `npm`, or `python` process; identify the concrete PID first.
- When using `gh`, check the configured hosts and prefer the one already configured instead of assuming `github.com`.
- If Jira CLI is installed and the task is Jira-related, prefer it.
- For Jira rich text, format content for Jira and avoid references to local file paths.
- When generating `.pre-commit-config.yaml`, include at least `trailing-whitespace` and `end-of-file-fixer`, then run `pre-commit autoupdate` when possible.
- Research locally first: repository docs/code, then related repos in the same organization, then official external docs.
- Document only what adds value beyond the code; avoid duplication.
- For Azure-related work, prefer Azure tools and their best-practice helpers when they are available.