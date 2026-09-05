# Prompt: Investigate CI Environment Differences

**Goal**: Systematically investigate why a build succeeds in one CI environment but fails in another

---

## Context Template

When invoking this investigation, provide:

```
Build Status:
- Environment A (e.g., staging): [SUCCESS/FAILURE]
- Environment B (e.g., production): [SUCCESS/FAILURE]

Error Message:
```
[Paste error from CI logs]
```

Technologies:
- CI Platform: [GitHub Actions/GitLab/Jenkins]
- Build Tool: [Docker/BuildX/npm/Maven]
- Key Dependencies: [semantic-release, plugins, etc.]

Repository:
- Path: [/path/to/repo]
- Workflows: [.github/workflows/*.yaml]
```

---

## Investigation Flow

### Phase 1: Gather Information
```
Use skills:
1. @ci-workflow-analyzer.skill
   - Locate workflow files
   - Map job dependencies
   - Compare configurations

2. Extract CI logs:
   ```bash
   gh run view <run-id> --log > ci-full.log
   gh run view <run-id> --log-failed > ci-errors.log
   ```
```

### Phase 2: Compare Environments
```
For each environment, document:

| Metric | Environment A | Environment B |
|--------|---------------|---------------|
| Workflow file | | |
| Runner type | | |
| Docker version | | |
| Build method | | |
| Key actions | | |
| Network config | | |
| Environment vars | | |

Skills to use:
- @docker-buildx-debugger.skill (if Docker-related)
- @ci-workflow-analyzer.skill

Commands to run:
```bash
# In CI logs, search for:
grep "Docker version\|docker --version" ci-full.log
grep -i "buildx\|builder" ci-full.log
grep "Set up job" ci-full.log -A 20
```
```

### Phase 3: Identify Root Cause
```
Common patterns to check:

□ Different runner types (self-hosted vs cloud)
□ Different Docker drivers (docker vs docker-container)
□ Different tool versions
□ Direct tool invocation vs plugin/wrapper
□ Network/security restrictions
□ Different authentication methods
□ Missing/different environment variables

For plugin-related issues:
- Use @npm-plugin-source-investigator.skill
- Check for hardcoded defaults
- Review plugin CHANGELOG for breaking changes
```

### Phase 4: Reproduce Locally
```
Try to replicate the issue:

```bash
# Test similar to working environment
docker buildx build [working-flags] -t test:working .

# Test similar to failing environment  
docker buildx build [failing-flags] -t test:failing .

# Test different network modes
for net in host default none; do
  echo "Testing --network=$net"
  docker buildx build --network=$net [other-flags] -t test:$net . 2>&1 | grep -i error || echo "✓ Success"
done
```
```

### Phase 5: Document & Fix
```
Create structured documentation:

1. Investigation report:
   - File: INVESTIGATION_PROCESS.md
   - Include: Timeline, findings, tests, solution

2. Update configuration:
   - Apply fix
   - Test locally
   - Create PR with detailed description

3. Future reference:
   - Add troubleshooting to project README
   - Create reusable skill if applicable
   - Document in team wiki/confluence
```

---

## Expected Output

```markdown
## Investigation Summary: [Issue Title]

### Root Cause
[One-sentence description]

### Key Differences Found
1. [Difference 1]: Impact and why it matters
2. [Difference 2]: Impact and why it matters

### Solution Applied
[What was changed and why]

### Validation
- [ ] Tested locally
- [ ] Tested in failing environment
- [ ] Verified in working environment still works

### Related Issues
- [Upstream issue links]
- [Similar cases]

### Lessons Learned
1. [Key insight 1]
2. [Key insight 2]
```

---

## Skills Required

- `ci-workflow-analyzer.skill`
- `docker-buildx-debugger.skill`
- `npm-plugin-source-investigator.skill`
- `github-actions-log-analyzer.skill` (if not exists, create it)

---

## Example Invocation

```
@investigate-ci-environment-difference.prompt

Build succeeds in staging but fails in production with error:
"docker: 'buildx' is not a docker command OR unknown flag: --network"

Repo: /path/to/project
Workflow: .github/workflows/docker.yaml (uses reusable workflows)
Key tool: semantic-release with @codedependant/semantic-release-docker
```

---

## Follow-up Actions

After investigation:
1. Create PR with fix
2. Update skills if new patterns found
3. Contribute to upstream if plugin issue
4. Share findings with team
