---
agent: agent
---

Review the comments of the PR associated with the current branch.

Constraints:

- do not perform Git write operations
- do not commit, push, stage, unstage, or rewrite branch history
- only inspect the comments and identify which suggestions make sense to implement
- separate missing regressions from optional style-only feedback