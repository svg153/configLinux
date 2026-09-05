---
name: pr-description-visual
description: 'Generate a visual, stable PR description (Markdown + Mermaid) that highlights changes, impact, and fit with existing architecture. Avoid volatile metrics like counts/line numbers.'
---

# Visual PR Description

## When to Use
- You already extracted “what changed” from a PR and need to **rewrite or propose** a PR description.
- The description must be **visual** and easy to scan, with diagrams.

## Constraints
- Don’t include line counts, file counts, commit counts, or any numbers likely to change.
- Don’t guess test results.
- Don’t reference local filesystem paths (use repo-relative paths like `src/` or `playbooks/` instead of `/home/user/repo/src/` or `C:\repo\src\` or `~/repo/src/`).

## Recommended Output Structure (Markdown)
1. **Executive summary** (2–5 bullets)
2. **Change map** (table: Area → Paths → Intent)
3. **Behavioral change** (Before/After)
4. **How it fits** (existing architecture + why this place)
5. **Impact** (Ops/Runtime/DevEx)
6. **Risks & mitigations**
7. **Verification** (CI + manual steps)
8. **Follow-ups** (optional)

## Diagrams (Mermaid)
Use at least one diagram. Pick the one that best matches the change.

### A) High-level flow
```mermaid
flowchart TD
  A[Operator runs playbook] --> B[Robot validations]
  B --> C[Raw outputs per host]
  C --> D[Local aggregation]
  D --> E[Jira-friendly report]
```

### B) Component map
```mermaid
graph LR
  subgraph Ansible
    P[Playbook] --> R1[Role: validate_endpoints_robot]
    P --> R2[Role: validate_endpoints_reports]
  end
  R1 --> W[Windows robots]
  R2 --> L[Local report artifacts]
```

## Template
Use (or adapt) this template file:
- [pr-description-template](./assets/pr-description-template.md)
