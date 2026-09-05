# Skill: CI Workflow Analyzer

**Purpose**: Analyze GitHub Actions workflows to compare job configurations and identify environment differences

**When to use**:
- Builds succeed in one environment but fail in another
- Need to compare staging vs production workflows
- Investigating CI/CD pipeline inconsistencies

## Steps

### 1. Identify Repository Workflows
```bash
# Find workflow files
find .github/workflows -name "*.yml" -o -name "*.yaml"

# For reusable workflows, check dependencies
grep "uses:.*/.github/workflows/" .github/workflows/*.yaml
```

### 2. Map Job Flow
```bash
# Extract job names and dependencies
yq eval '.jobs | keys' .github/workflows/main.yaml

# Show job relationships
yq eval '.jobs.*.needs' .github/workflows/main.yaml
```

### 3. Compare Job Configurations

**Key Differences to Check**:
```yaml
# Runner environment
runs-on: [self-hosted vs ubuntu-latest]

# Docker setup
- Docker version/driver
- BuildX configuration
- Network settings

# Actions versions
uses: action@v1 vs action@v2

# Environment variables
env:
  VAR: value

# Secrets/credentials
with:
  token: ${{ secrets.TOKEN }}
```

### 4. Analyze Reusable Workflows

If workflow uses `workflow_call`:
```bash
# Locate the reusable workflow
REUSABLE_PATH=$(grep -oP "uses: \K[^@]+" .github/workflows/main.yaml)

# Read and compare
cat "path/to/${REUSABLE_PATH}"
```

### 5. Extract Build Commands

For semantic-release or similar:
```bash
# Check if different tools are used per environment
grep -A 10 "semantic-release\|docker.*build\|buildx" workflow.yaml
```

### 6. Generate Comparison Table

| Aspect | Environment A | Environment B |
|--------|---------------|---------------|
| Workflow file | container_stage.yaml | container_build.yaml |
| Build method | Docker action | Semantic release |
| BuildX setup | Explicit | Implicit |
| Network config | Driver-level | Command-level |

## Output Format

```markdown
## Workflow Comparison: [ENV_A] vs [ENV_B]

### Key Differences
- **[Aspect]**: ENV_A uses X, ENV_B uses Y
- **Impact**: Why this matters

### Environment Details
ENV_A: [runner, docker, buildx versions]
ENV_B: [runner, docker, buildx versions]

### Recommendation
[What to investigate or change next]
```

## Related Skills
- `docker-env-debugger.skill`
- `github-actions-log-analyzer.skill`
