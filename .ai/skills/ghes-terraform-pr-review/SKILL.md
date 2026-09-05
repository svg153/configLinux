---
name: ghes-terraform-pr-review
description: >
  Review PRs in governance repos (arch-admin, ads-admin, n8n-admin, org-admin, etc.)
  that touch Terraform or YAML inventory files on GHES. Produces a layer-correct
  review checklist, classifies drift risk, and emits inline comments when requested.
  Use when a user gives a GHES PR URL for a governance/IaC repo.
---

# GHES Terraform PR Review — Governance Repos

## When to Use

- User provides a GHES PR URL (`https://$GHE_HOST/...`)  **and** the PR touches any of:
  - `apps/github-as-code/**/*.tf`
  - `.github/repos/*.yml`
  - `.github/team-settings.yml`
  - `atlantis.yaml`
  - shared module files in `team-admin/`, `org-admin/`, `x-admin-template/`
- User asks "can you review this PR?" or "what changed here?" for a governance repo.

## Non-Negotiable Constraints

- **Never** run `terraform apply` or `terraform import` locally unless explicitly requested.
- **Never** suggest merging before Atlantis plan is visible and reviewed.
- **Never** include volatile metrics (line counts, file counts).
- **Always** use `GH_HOST=$GHE_HOST` for all `gh` commands (host derived from the repo remote).
- **Always** classify changes by ownership layer before suggesting fixes.

---

## Procedure

### 0) Resolve host and PR identity

```bash
# Derive the GHES host from the repository remote (filters out user/repo from the URL)
export GHE_HOST="${GHE_HOST:-$(git config --get remote.origin.url | sed -E 's#.*@([^/:]+).*#\1#')}"
export GH_HOST="$GHE_HOST"

# From a URL like https://$GHE_HOST/<ORG>/<REPO>/pull/42
# Extract: owner=<ORG>, repo=<REPO>, pr=42
GH_HOST="$GHE_HOST" gh pr view "https://$GHE_HOST/<ORG>/<REPO>/pull/42" \
  --json title,body,baseRefName,headRefName,author,labels,url
```

### 1) Identify changed files and target layer

```bash
GH_HOST="$GHE_HOST" gh pr diff <PR_URL> --name-only
```

Route each changed path to its ownership layer using this table:

| Path pattern | Ownership layer | Key concern |
|---|---|---|
| `.github/repos/*.yml` | Team repo (arch-admin / ads-admin) | YAML contract compliance, family routing |
| `.github/team-settings.yml` | Team repo | Team name, org-level settings passthrough |
| `apps/github-as-code/*.tf` | Team repo (root/locals/repos) | Routing changes, import blocks, variable use |
| `apps/github-as-code/modules/**` | Team repo (family wrappers) | Layer boundary: should not duplicate `team-admin` internals |
| `atlantis.yaml` | Team repo | Autoplan scope, project config |
| `team-admin/modules/**` | `team-admin` (shared internal) | Breaking-change risk; any edit must be backward compatible |
| `org-admin/apps/org-governance/**` | `org-admin` | Org-scoped rulesets/governance; not a team-repo concern |

**Red flag**: If a PR edits `team-admin` or `org-admin` but is opened against `arch-admin`, it's almost certainly in the wrong repo.

### 2) YAML inventory review (`.github/repos/*.yml`)

For each changed YAML file check:

- [ ] Required top-level keys present: `repository`, `classification`.
- [ ] `repository.name` matches filename (`arch-foo.yml` → `name: arch-foo`).
- [ ] `classification.family` is one of: `admin`, `hld`, `coe_design`, `deck`, `poc`, `generic`.
- [ ] No fields that belong in module defaults (e.g., repeating branch protection that the `hld` family already enforces).
- [ ] No raw API dump values (boolean API defaults should be absent unless overriding).
- [ ] Only allowed top-level keys: `repository`, `classification`, `teams`, `branches`, `branch_protection`, `pages`, `labels`, `variables`.

Quick schema reference: `team-admin/docs/schemas/repository-yaml-common.schema.json`

### 3) Terraform code review (`.tf` files)

For Terraform changes, check:

- [ ] **Layer correctness**: does the change belong here (team repo) or in `team-admin` / `org-admin`?
- [ ] **Module boundary**: team wrappers must not re-declare logic owned by `team-admin/_internal/*`.
- [ ] **Import blocks**: new import blocks (`import { ... }`) must be in dedicated adoption files (e.g., `atlantis-import-*.tf`) and removed in a follow-up cleanup PR after state is adopted.
- [ ] **Pinning**: remote module sources (`git::ssh://git@$GHE_HOST/<ORG>/team-admin.git//...`) must use `?ref=<tag-or-sha>`, not `?ref=main`.
- [ ] **Backend/credentials**: no inline secrets; backend config only through `backend.hcl` (never committed); credentials via Vault/Atlantis env.
- [ ] **`terraform fmt`**: run `terraform fmt -check -recursive` mentally or verify CI output.

### 4) Atlantis plan signal

```bash
GH_HOST="$GHE_HOST" gh pr checks <PR_URL>
```

Interpret Atlantis check results:

- `atlantis/plan` passing → plan ran; look at PR comment for plan body.
- `atlantis/plan` failing → block merge; classify failure (backend missing, provider auth, code error).
- `atlantis/apply` pending approval → apply gate working as expected; do not merge without plan review.
- No Atlantis check → autoplan may be misconfigured; review `atlantis.yaml` scope.

**Always** read the Atlantis plan comment in the PR before recommending merge:
- Look for: unexpected `destroy` operations, `replace` on `github_branch_default`, massive creates (>10 resources) that are not explained by a new inventory batch.

### 5) Drift classification (when plan shows unexpected changes)

Classify each unexpected plan change into one of:

| Class | Signal | Recommended action |
|---|---|---|
| YAML missing/wrong | Single-repo changes across expected resource types | Fix YAML field |
| Passthrough broken | Same field drifting across many repos | Check `team-admin` module passthrough; check locals routing |
| Inventory duplicate | Unexpected `replace` on `github_branch_default` | Remove duplicate YAML entry |
| Provider/default noise | Empty-string vs null diff with no semantic change | Suppress or accept; do not create unnecessary `override` fields |
| Structural (state adoption) | Large create batches on already-existing resources | Expected during import waves; verify import blocks present |

If drift appears in mass (>5 repos), assume systemic cause first.

### 6) Go-live gates checklist (for final merge approval)

Use this before recommending approve:

- [ ] Atlantis plan reviewed; no unexpected destroys or replaces.
- [ ] YAML files pass schema shape (required keys, allowed family values).
- [ ] Module boundaries respected (no duplicated internal logic).
- [ ] Action/module versions pinned (no `@main` or `?ref=main` in long-term code).
- [ ] Backend/credentials modeled for Atlantis (no local-only setup).
- [ ] PR description explains what changed, what family/repos are affected, and how to roll back.
- [ ] Import blocks (if present) have a linked follow-up task/issue to remove them after apply.

### 7) Output: what to produce

Produce a **review summary** (Markdown) with these sections:

1. **Layer map** — which paths changed, which layer owns them.
2. **YAML findings** — per-file issues or ✅ if clean.
3. **Terraform findings** — module boundary, pinning, import correctness or ✅ if clean.
4. **Atlantis signal** — plan status, plan body highlights (no line counts), any blocking concerns.
5. **Drift classification** — if plan shows unexpected changes, classify each.
6. **Recommendation** — one of: `APPROVE`, `REQUEST CHANGES`, or `NEEDS PLAN FIRST`.

Avoid volatile metrics; prefer describing the *type* and *scope* of change.

---

## Quick Decision Tree

```
Is the PR touching .github/repos/*.yml?
  → Yes → Run YAML checklist (§2) first.

Is the PR touching .tf files in team-admin or org-admin but opened in arch-admin?
  → Yes → Flag layer mismatch immediately.

Does Atlantis plan show destroy operations?
  → Yes → Block; require human plan review before approve.

Does Atlantis plan show >10 unexpected creates on existing resources?
  → Yes → Likely state adoption wave; verify import blocks present.
```

---

## Companion docs (read if deeper context needed)

- Layer ownership: [`arch-admin/docs/repository-layout.md`](arch-admin/docs/repository-layout.md)
- Inventory YAML contract: [`arch-admin/docs/inventory-contract.md`](arch-admin/docs/inventory-contract.md)
- Module catalog: [`arch-admin/docs/MODULE-CATALOG.md`](arch-admin/docs/MODULE-CATALOG.md)
- Atlantis guardrails: [`arch-admin/docs/terraform-apply-guardrails.md`](arch-admin/docs/terraform-apply-guardrails.md)
- Go-live checklist: [`arch-admin/docs/go-live-checklist.md`](arch-admin/docs/go-live-checklist.md)
- State import runbook: [`arch-admin/docs/terraform-state-import-pilot-runbook.md`](arch-admin/docs/terraform-state-import-pilot-runbook.md)
- File classification: [`arch-admin/docs/FILE-CLASSIFICATION.md`](arch-admin/docs/FILE-CLASSIFICATION.md)
- ADR-0001 Atlantis execution: [`arch-admin/docs/adr-0001-atlantis-execution-model.md`](arch-admin/docs/adr-0001-atlantis-execution-model.md)

## Related skills

- `pr-review-gh` — generic PR review (metadata, diff, checks summary).
- `pr-inline-review-ghes` — post inline review comments to GHES PR lines.
- `admin-governance-workflow` — broader governance workflow (scratch plans, state adoption, imports).
