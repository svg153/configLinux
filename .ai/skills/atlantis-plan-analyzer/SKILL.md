---
name: atlantis-plan-analyzer
description: >
  Extract, merge, and analyze Terraform plans from Atlantis PR comments on GHES.
  Automatically extracts fragmented Atlantis plan comments, merges them into a
  single file, and analyzes the plan to identify resources to create, destroy,
  import, or replace. Use when the user asks to "extract the Atlantis plan",
  "analyze the plan", "compare plans", "what will be created/destroyed", or
  any task related to reviewing Terraform plans posted by Atlantis in GitHub PRs.
---

# Atlantis Plan Analyzer

## When to Use

- User asks to "extract the Atlantis plan" from a PR
- User asks to "analyze the plan" or "what will be created/destroyed"
- User wants to "compare local vs remote plan"
- User asks about Terraform plan actions (imports, creates, destroys, replaces)
- User wants to verify plan safety before applying

## Prerequisites

This skill requires:
- `gh` CLI installed and configured with `GH_HOST=<ghe-host>`
- Atlantis bot posting plans to PR comments (the bot user for your GHES)
- Python 3.8+ for the analyzer script

## Quick Start

```bash
# Derive the GHES host from the repo remote
export GHE_HOST="${GHE_HOST:-$(git config --get remote.origin.url | sed -E 's#.*@([^/:]+).*#\1#')}"

# Extract plan from PR and analyze
python3 .ai/skills/atlantis-plan-analyzer/atlantis_plan_analyzer.py \
  --gh-host "$GHE_HOST" \
  --org <ORG> \
  --repo <repo> \
  --pr 2 \
  --analyze

# Extract latest plan (auto-detect PR)
python3 .ai/skills/atlantis-plan-analyzer/atlantis_plan_analyzer.py \
  --gh-host "$GHE_HOST" \
  --org <ORG> \
  --repo <repo> \
  --analyze

# Analyze existing plan file
python3 .ai/skills/atlantis-plan-analyzer/atlantis_plan_analyzer.py \
  --plan-file atlantis-plan-extraction/atlantis-plan-complete.txt \
  --analyze

# Compare with local plan
python3 .ai/skills/atlantis-plan-analyzer/atlantis_plan_analyzer.py \
  --plan-file atlantis-plan-extraction/atlantis-plan-complete.txt \
  --compare apps/github-as-code/.terraform-logs/arch-local-plan-*.log \
  --analyze
```

## How It Works

### 1. Extract Plan from PR

The script automatically:
- Identifies the latest Atlantis bot comments in the PR
- Merges all fragmented comments into a single file
- Generates a summary with action counts

```bash
# Output files:
# - atlantis-plan-extraction/atlantis-plan-complete.txt  (full merged plan)
# - atlantis-plan-extraction/atlantis-plan-summary.txt   (action counts)
# - atlantis-plan-extraction/PLAN-ANALYSIS.md            (detailed analysis)
```

### 2. Analyze Plan

The script extracts:
- **Action counts**: imports, creates, changes, destroys, replaces
- **Resource types**: grouped by action type with counts
- **Safety verification**: checks for unexpected updates/replaces

### 3. Compare Plans

Compares two plan files (e.g., remote vs local) and highlights differences:

```bash
python3 atlantis_plan_analyzer.py \
  --plan-file remote-plan.txt \
  --compare local-plan.txt
```

## Analysis Patterns

After extracting the plan, use these quick grep patterns for specific analysis:

### Quick Stats
```bash
# Count actions in plan file
PLAN_FILE="atlantis-plan-extraction/atlantis-plan-complete.txt"

echo "Imports:  $(grep -c 'will be imported' $PLAN_FILE)"
echo "Creates:  $(grep -c 'will be created' $PLAN_FILE)"
echo "Changes:  $(grep -c 'will be updated' $PLAN_FILE)"
echo "Destroys: $(grep -c 'will be destroyed' $PLAN_FILE)"
echo "Replaces: $(grep -c 'must be replaced' $PLAN_FILE)"
```

### Resource Types
```bash
# Resource types being created
grep 'will be created' $PLAN_FILE | grep -oP 'module\.[^\[]+' | sort | uniq -c | sort -rn

# Resource types being destroyed
grep 'will be destroyed' $PLAN_FILE | grep -oP 'module\.[^\[]+' | sort | uniq -c | sort -rn

# Resource types being imported
grep 'will be imported' $PLAN_FILE | grep -oP 'module\.[^\[]+' | sort | uniq -c | sort -rn
```

### Safety Checks
```bash
# Check for updates (should be 0 for safety)
grep -c 'will be updated' $PLAN_FILE

# Check vulnerability_alerts
grep 'vulnerability_alerts' $PLAN_FILE | grep -c 'will be created'
grep 'vulnerability_alerts' $PLAN_FILE | grep -c 'will be destroyed'

# Check dependabot_security_updates
grep 'dependabot_security_updates' $PLAN_FILE | grep -c 'will be created'
grep 'dependabot_security_updates' $PLAN_FILE | grep -c 'will be destroyed'
```

## Expected Plan Structure

For the arch-admin project, expect:

| Action | Expected Count | Description |
|--------|---------------|-------------|
| Import | ~7 | Repos, labels, security updates to import |
| Create | ~183 | New team repos, vulnerability alerts, team permissions |
| Change | 0 | No updates expected (YAMLs match GitHub) |
| Destroy | ~233 | Old module structure (arch_repository → team_repository) |
| Replace | ~1 | One resource to recreate |

## Safety Checklist

Before approving a plan:

- [ ] **0 Updates** - No existing resources will be modified
- [ ] **YAMLs match GitHub** - No configuration drift
- [ ] **Destroys are expected** - Old module structure removal
- [ ] **Creates are expected** - New module structure addition
- [ ] **Imports are expected** - Missing resources being imported
- [ ] **Replaces are minimal** - Only expected replacements

## Troubleshooting

### No Atlantis comments found
```bash
# Check if Atlantis bot has posted comments
GH_HOST="$GHE_HOST" gh api repos/<ORG>/<repo>/issues/2/comments \
  --jq '.[] | select(.user.login == "<atlantis-bot>") | {id: .id, created_at}' | tail -10
```

### Plan is split into many comments
The script handles this automatically by merging all Atlantis bot comments.

### Plan file too large
The script outputs a summary file with action counts for quick review:
```bash
cat atlantis-plan-extraction/atlantis-plan-summary.txt
```

## Companion Skills

- `ghes-terraform-pr-review` - Review PRs touching Terraform/YAML files
- `pr-review-gh` - Generic PR review (metadata, diff, checks)
- `ads-arch-drift-triage` - Classify and fix Terraform drift

## Companion Docs

- `arch-admin/docs/adr-0001-atlantis-execution-model.md` - Atlantis execution model
- `arch-admin/docs/terraform-apply-guardrails.md` - Terraform apply guardrails
- `arch-admin/docs/terraform-state-import-pilot-runbook.md` - State import runbook
- `arch-admin/docs/go-live-checklist.md` - Go-live checklist
