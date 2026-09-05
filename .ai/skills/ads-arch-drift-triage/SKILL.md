---
name: ads-arch-drift-triage
description: >
  Classify and fix Terraform drift in governance repos (arch-admin, ads-admin,
  n8n-admin, and other team repos). Covers the full triage loop: reading large
  plan output efficiently, classifying drift by root cause family, routing fixes
  to the correct ownership layer, validating locally, and producing an
  evidence-backed summary. Use when the user reports unexpected Terraform plan
  changes, asks about drift, or needs to run imports/state-adoption analysis.
---

# ADS/ARCH Drift Triage

## When to Use

- User reports that `terraform plan` (Atlantis or local) shows unexpected changes.
- User asks "why is X drifting?" or "what's wrong with my plan?".
- User needs to run state-adoption imports or regenerate import blocks.
- User wants to diagnose a large plan file for a team repo.
- Atlantis PR plan comment shows destroys, replaces, or unexpected mass creates.

## Non-Negotiable Safety Rules

- **Never** run `terraform apply` or `terraform import` locally unless explicitly requested.
- **Never** patch many YAML files as a workaround before ruling out shared-layer causes.
- Always use `GH_HOST=$GHE_HOST` for `gh` commands (derived from the repo remote).
- Always prefer `make init/validate/plan/diff` in `arch-admin` over raw `terraform` calls.
- Read large plan files by anchor/pattern first — never end-to-end on the first pass.

---

## Step 1 — Identify the target repo and ownership layer

Which repo owns this drift?

| Repo | Owns |
|---|---|
| `arch-admin` | ARCH team inventory, family routing, repo-local overlays |
| `ads-admin` | ADS team inventory, family routing, repo-local overlays |
| `n8n-admin` | n8n team inventory, workflow-specific behavior |
| `team-admin` | Shared schema, module passthrough, common defaults |
| `org-admin` | Org-wide policy, organization rulesets |
| `x-admin-template` | Shared scripts, scratch-plan tooling |

**Red flag:** If the fix involves changing shared module logic, the change belongs in `team-admin`, not in the consumer repo.

---

## Step 2 — Read the plan efficiently

For large plan files (Atlantis PR comments, log files, JSON outputs):

```bash
# 1. Get size/shape first
wc -l apps/github-as-code/.terraform-logs/latest-local-plan.txt
grep -c 'will be' apps/github-as-code/.terraform-logs/latest-local-plan.txt

# 2. Find the top-level summary first
grep -E '^(Plan:|No changes|  # .* will be )' apps/github-as-code/.terraform-logs/latest-local-plan.txt

# 3. Focus on a specific resource type
grep -A 10 'github_branch_default' apps/github-as-code/.terraform-logs/latest-local-plan.txt

# 4. Use make shortcuts in arch-admin
cd arch-admin && make diff        # shows Plan: summary + "will be" lines only
cd arch-admin && make show-plan   # full plan text
```

For JSON-format plan analysis (scratch plans):

```bash
python3 x-admin-template/scripts/analyze_terraform_plan.py \
  --plan-json /path/to/tfplan.json \
  --md-out /path/to/analysis.md
```

**Rule:** If the same change appears across 5+ repos, assume a systemic cause first.

---

## Step 3 — Classify drift into a root cause family

For each unexpected plan change, assign one class:

| Class | Signal | Key indicator |
|---|---|---|
| **A: YAML/input wrong** | Single or a few repos, specific field | Field value in plan differs from YAML intent |
| **B: Passthrough broken** | Many repos, same field type | Module not forwarding a YAML field to provider; check `team-admin` module |
| **C: Inventory duplicate** | `replace` on `github_branch_default` | Two YAML files declare the same repo name |
| **D: Provider/default noise** | Empty-string vs null, boolean API default | Field semantically no-op; provider default materializing as diff |
| **E: Structural create (state adoption)** | Large batch of `create` on already-existing resources | Import blocks missing; expected during initial adoption wave |
| **F: Import/state mismatch** | `create` on a resource that should already be imported | Address mismatch or import block pointing to wrong resource ID |

**Decision tree:**

```
Mass drift (>5 repos, same resource type)?
  → Yes → Class B (passthrough) or C (duplicate); check team-admin module first.
  → No  ↓

Replace on github_branch_default?
  → Yes → Class C (inventory duplicate); search for duplicate repo name in YAML.

Provider showing empty string vs null diff with no logical change?
  → Yes → Class D (noise); do not add override fields; suppress or accept.

Large batch of creates on resources that visibly exist in GitHub?
  → Yes → Class E (state adoption); check if import blocks are present.

Creates or deletes on a single repo, field semantically wrong?
  → Yes → Class A (YAML input); fix the YAML field.
```

---

## Step 4 — Route the fix to the correct layer

| Root cause class | Where to fix | What to change |
|---|---|---|
| A — YAML wrong | Team repo (`.github/repos/*.yml`) | Fix the incorrect field value |
| B — Passthrough broken | `team-admin/modules/_internal/*` or root module | Add/fix the variable passthrough chain |
| C — Inventory duplicate | Team repo (`.github/repos/`) | Remove the duplicate YAML file |
| D — Provider noise | Nowhere (suppress) or `team-admin` defaults | Only fix if semantically incorrect; do not add workaround overrides |
| E — State adoption | Team repo (`apps/github-as-code/atlantis-import-*.tf`) | Add/regenerate import blocks |
| F — Import mismatch | Team repo (import block file) | Fix the resource address or import ID |

**Key module path to check for Class B (passthrough):**

```
team-admin/
  main.tf                        ← team_admin_repository: public entrypoint
  modules/_internal/
    platform_defaults/           ← merge engine (platform_* + unprefixed)
    repository/                  ← provider-level engine
    team_repository/             ← team-oriented composition
  modules/yaml_repository_interface/  ← YAML adapter (public)
```

Trace: `yaml_repository_interface` → `locals.tf` (consumer) → `repositories.tf` → family wrapper → `team_admin_repository` → `_internal/platform_defaults` → `_internal/repository`.

---

## Step 5 — Apply the fix and validate

### Local validation (always run after changes)

```bash
# Quick static check (no backend, no credentials needed)
cd arch-admin
make init       # prepare scratch + terraform init -backend=false
make validate   # terraform validate in scratch

# Or directly in a Terraform root:
terraform init -backend=false -input=false -no-color
TF_VAR_github_token=dummy-token-for-validation terraform validate -no-color
terraform fmt -check -recursive
```

### Regenerate imports (run when inventory or family routing changed)

```bash
# From the team repo root (arch-admin, ads-admin, etc.)
python3 ../x-admin-template/scripts/generate_state_adoption_imports.py --layout arch
# Or for ads-admin:
python3 ../x-admin-template/scripts/generate_state_adoption_imports.py --layout ads
```

Must be run from the repo root so `Path.cwd()` resolves correctly.

### Full scratch plan (run when shared contract or routing changed)

```bash
python3 x-admin-template/scripts/run_scratch_plan_and_analyze.py \
  /abs/path/to/<team-admin-repo> \
  --copy-sibling team-admin \
  --rewrite-team-admin-sources \
  --init-log-out /tmp/init.log \
  --plan-log-out /tmp/plan.log \
  --json-out /tmp/analysis.json \
  --md-out /tmp/analysis.md
```

---

## Step 6 — Verify the plan delta

After applying the fix, re-run and compare:

```bash
cd arch-admin && make diff     # shows only Plan: summary + "will be" lines
```

Check:
- [ ] Unexpected destroys gone.
- [ ] Unexpected replaces (especially `github_branch_default`) gone.
- [ ] Remaining plan matches expected structural creates (adoption batch) or is `No changes`.
- [ ] Any remaining diff is classified and explained (structural vs actionable).

---

## Step 7 — Document the outcome

Every completed triage must produce a brief summary with:

1. **Root cause class** (A–F from Step 3).
2. **Layer fixed** (which repo/module was changed).
3. **Files changed** (paths only, no line counts).
4. **Plan delta** — what was reduced and what remains structural.
5. **Evidence** — log/scratch-plan paths if generated.

Example:
> Root cause: Class B (passthrough broken). Fixed `team-admin/modules/_internal/platform_defaults/main.tf`
> to forward `autolinks` variable. Validation: `make validate` passed in `arch-admin`.
> Plan: 47 unexpected creates reduced to 0 actionable; 8 structural creates remain (state adoption for new repos).

---

## Known Patterns and Gotchas

| Pattern | Description |
|---|---|
| `github_branch_default` replace | Almost always inventory duplicate. Search for repos with same `name:` in `.github/repos/`. |
| `github_issue_labels` mass create | Usually baseline labels from `team-admin`; expected during first state adoption wave. |
| `homepage` field drift | Explicit YAML `homepage` must win over module-calculated value; check passthrough in wrapper. |
| YAML `null` override | Analyzer may show null/empty-string as drift when it is a provider default; classify as noise (Class D). |
| `?ref=main` on module sources | Bootstrap-only; triggers new fetch on every `init`; pin to tag/SHA when first module release is cut. |
| Mass creates on existing repos | Verify import blocks exist; if not, run `generate_state_adoption_imports.py`. |

---

## Companion Scripts (`x-admin-template/scripts/`)

| Script | Purpose |
|---|---|
| `run_scratch_plan_and_analyze.py` | Full scratch plan + JSON/MD analysis output |
| `analyze_terraform_plan.py` | Parse existing plan JSON to categorize changes |
| `generate_state_adoption_imports.py` | Regenerate import blocks from current inventory |
| `extract_terraform_alignment_candidates.py` | Find resources that need alignment patches |
| `generate_repo_yaml_alignment_patches.py` | Generate YAML patch suggestions from alignment analysis |

---

## Companion Docs

- Governance instructions: [`.ai/instructions/ads-arch-governance.instructions.md`](.ai/instructions/ads-arch-governance.instructions.md)
- Drift triage instructions: [`.ai/instructions/arch-admin-drift-triage.instructions.md`](.ai/instructions/arch-admin-drift-triage.instructions.md)
- Module catalog: [`arch-admin/docs/MODULE-CATALOG.md`](arch-admin/docs/MODULE-CATALOG.md)
- Import runbook: [`arch-admin/docs/terraform-state-import-pilot-runbook.md`](arch-admin/docs/terraform-state-import-pilot-runbook.md)
- Apply guardrails: [`arch-admin/docs/terraform-apply-guardrails.md`](arch-admin/docs/terraform-apply-guardrails.md)
- File classification: [`arch-admin/docs/FILE-CLASSIFICATION.md`](arch-admin/docs/FILE-CLASSIFICATION.md)

## Related Skills

- `ghes-terraform-pr-review` — Review a governance PR on GHES (checks Atlantis plan, layer routing, YAML contract).
- `admin-governance-workflow` — Broader governance workflow including scratch plans and state adoption.
