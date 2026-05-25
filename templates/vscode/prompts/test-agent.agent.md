---
agent: agent
---

If the task will end in a PR, ask for the ticket ID when it is required and not already known.

Suggested PR flow:

- create a branch from the repository default branch
- add only the files relevant to the requested change
- create a descriptive commit, ideally using `<type>(<ticket>): short-summary` when a ticket exists
- push and create the PR with `gh` when available
- update the PR description with the relevant context
- wait for workflows and review their status before declaring the work done