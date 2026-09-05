# Skill: Docker BuildX Debugger

**Purpose**: Diagnose Docker BuildX issues in CI/CD environments

**When to use**:
- BuildX builds fail with "unknown flag" errors
- Multi-platform builds work locally but fail in CI
- Network or driver-related build failures

## Quick Diagnostics

### 1. Check BuildX Installation
```bash
docker buildx version
docker buildx ls
```

**Output to analyze**:
- Active builder (marked with `*`)
- Driver type: `docker` vs `docker-container` vs `kubernetes`
- BuildKit version
- Supported platforms

### 2. Inspect Active Builder
```bash
docker buildx inspect --bootstrap
```

**Key fields**:
- Driver: Type and options
- Platforms: What architectures are available
- Endpoint: Docker daemon connection

### 3. Test Network Flags

```bash
# Test different network modes
docker buildx build --network=host --platform linux/amd64 -t test:host .
docker buildx build --network=default --platform linux/amd64 -t test:default .
docker buildx build --network=none --platform linux/amd64 -t test:none .
```

### 4. Check CI Environment

**In CI logs, look for**:
```bash
# Docker versions
docker version | grep -E "Client|Server|Version"

# BuildX setup
grep -i "buildx\|buildkit" ci-logs.txt

# Container context (Docker-in-Docker?)
docker info | grep -i "operating system\|docker root dir"
```

### 5. Compare Local vs CI

| Metric | Local | CI |
|--------|-------|-----|
| Docker Client | `docker version \| grep Client` | Check CI logs |
| Docker Server | `docker version \| grep Server` | Check CI logs |
| BuildX version | `docker buildx version` | Search CI logs |
| Active Builder | `docker buildx ls \| grep '*'` | Check setup step |
| Network mode | Test all 3 modes | Check error logs |

## Common Issues & Solutions

### Issue 1: `unknown flag: --network`
**Cause**: Builder driver doesn't support network flag  
**Solution**: Use `network=host` in driver-opts OR remove --network flag

**Driver-level config** (preferred):
```yaml
- uses: docker/setup-buildx-action@v3
  with:
    driver-opts: |
      network=host
```

**Command-level workaround**:
```bash
# Avoid --network flag altogether
docker buildx build --platform linux/amd64 -t image:tag .
```

### Issue 2: Multi-platform fails in CI
**Cause**: Wrong builder driver or missing emulation  
**Solution**:
```yaml
- uses: docker/setup-qemu-action@v3
- uses: docker/setup-buildx-action@v3
  with:
    driver: docker-container
```

### Issue 3: `--load` incompatible with multi-platform
**Cause**: Can't load multiple architectures to local Docker  
**Solution**: Use `--push` instead, or build single platform

## BuildX Driver Comparison

| Driver | Use Case | --network Support | Multi-platform |
|--------|----------|-------------------|----------------|
| `docker` | Local dev | ✅ All modes | ❌ Limited |
| `docker-container` | CI/CD | ⚠️ Driver-level only | ✅ Full |
| `kubernetes` | K8s clusters | ⚠️ Varies | ✅ Full |

## Debug Checklist

- [ ] Verify BuildX is installed and active
- [ ] Check builder driver type
- [ ] Test network modes locally
- [ ] Compare local vs CI Docker versions
- [ ] Review CI logs for BuildX setup step
- [ ] Identify hardcoded flags in build commands
- [ ] Test with driver-level network config

## Related Skills
- `ci-workflow-analyzer.skill`
- `plugin-source-investigator.skill`
