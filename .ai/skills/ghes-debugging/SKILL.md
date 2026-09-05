---
name: ghes-debugging
description: 'Debug GitHub Enterprise Server issues end-to-end (auth, GH_HOST, SSH keys/config, API access, CI/checks visibility, TLS/network, and repo remote mismatches). Use when users report gh/ssh/git failures against a custom GHES host or other GHES domains.'
---

# GHES Debugging (GitHub Enterprise Server)

## Purpose
Provide a repeatable, low-risk workflow to diagnose and unblock GitHub Enterprise Server issues using `gh`, `ssh`, and `git`.

## When to Use
- `gh` commands fail on internal GitHub hosts (custom GHES domains).
- PR/issue queries fail due to host mismatch or missing auth.
- SSH clone/push fails with key, host alias, or policy errors.
- API/checks/PR metadata is unavailable despite repo access.

## Core Principles
- Prefer **read-only diagnosis first**.
- Use **per-command host selection** with `GH_HOST=<host>`.
- Never expose secrets/tokens in output.
- Avoid broad destructive process actions; operate on specific targets only.

## Workflow

### 1) Identify the effective GitHub host
1. Extract host from the repository remote (e.g. `git config --get remote.origin.url | sed -E 's#.*@([^/:]+).*#\1#'`).
2. Validate configured hosts and active login:
   - `gh auth status`
3. Use host-scoped command style for all diagnostics:
   - `GH_HOST=<host> gh <command>`

### 2) Validate `gh` authentication and API reachability
Run lightweight checks:
- `GH_HOST=<host> gh api user`
- `GH_HOST=<host> gh repo view <owner>/<repo>`
- `GH_HOST=<host> gh pr view <pr_number_or_url> --json title,url,state`

If failing, classify quickly:
- 401/403 → auth/permissions/scope issue
- 404 on known repo → host mismatch or visibility restriction
- timeout/TLS errors → network/proxy/cert chain

### 3) Validate SSH configuration and key selection
Inspect SSH config and key mapping:
- `~/.ssh/config` host blocks (`Host`, `HostName`, `User`, `IdentityFile`)
- test key/route without modifying:
  - `ssh -T git@<host>`
  - `ssh -vT git@<host>` (only when needed)

Common pitfalls:
- Alias used in Git remote but no matching `Host` block.
- Wrong `IdentityFile` for GHES host.
- Using `github.com` key for GHES host or vice versa.

### 4) Validate Git remote consistency
Check remote host used by repository:
- `git remote -v`

Ensure remotes and `GH_HOST` point to the same GHES host.

### 5) Validate PR/checks access
For PR-related incidents:
- `GH_HOST=<host> gh pr view <pr_url_or_number> --json title,baseRefName,headRefName,author`
- `GH_HOST=<host> gh pr checks <pr_url_or_number>`

Only report checks as passing/failing if verified.

### 6) Triage matrix (fast classification)
- **Auth issue**: `gh auth status` shows not logged in for host, or API 401/403.
- **Host issue**: URL/remote host differs from `GH_HOST` or SSH `HostName`.
- **SSH issue**: `ssh -T` denied/publickey/permission problems.
- **Network/TLS issue**: timeouts, cert validation failures, proxy blocks.
- **Repo permission issue**: user authenticated but cannot view target repo/PR.

## Output Template (stable, actionable)
1. **Observed failure** (exact command + high-level error type)
2. **Host in use** (`GH_HOST`, remote host, SSH HostName)
3. **What worked** (API user, repo view, SSH handshake, PR checks)
4. **Root cause class** (auth/host/ssh/network/permissions)
5. **Minimal fix** (smallest safe change)
6. **Verification** (commands rerun and result)

## Safety Notes
- Do not print tokens, cookies, or private keys.
- Prefer temporary env scoping (`GH_HOST=<host>`) over global mutations.
- Keep changes minimal and reversible (single SSH host block or identity correction).

## Generic Log Paths and Service Commands

Use these paths/commands as a baseline in GHES investigations:

- `ghe-service-list` (service health snapshot)
- `/var/log/haproxy.log` (frontend routing and status codes)
- `/var/log/babeld/babeld.log` (Git protocol/backend bridge)
- `journalctl -u ssh -u sshd` (admin SSH acceptance and auth path)

Recommended read-only checks:

- `hostname`
- `date -Is`
- `ghe-service-list`
- `journalctl -u ssh -u sshd -n 100 --no-pager`

## Reusable Scripts (Generic)

Skill-local reusable scripts:

- `scripts/haproxy_git_refs_status_summary.sh`
   - Purpose: summarize `info/refs` status mix (`200`, `401`, `503`, `5xx`) from HAProxy logs.
   - Usage:
      - `./scripts/haproxy_git_refs_status_summary.sh /var/log/haproxy.log`
      - `./scripts/haproxy_git_refs_status_summary.sh /var/log/haproxy.log "16/Mar/2026:1[89]:\\|16/Mar/2026:2[0-2]:"`

- `scripts/haproxy_git_refs_window_top.sh`
   - Purpose: top affected repos and source IPs for `503` on `info/refs` in a time window.
   - Usage:
      - `./scripts/haproxy_git_refs_window_top.sh /var/log/haproxy.log "16/Mar/2026:1[89]:\\|16/Mar/2026:2[0-2]:" 20`

- `scripts/babeld_fileserver_errors.sh`
   - Purpose: quantify and sample backend signatures (`short read`, `FileServerConnectionError`, `status_code="503"`).
   - Usage:
      - `./scripts/babeld_fileserver_errors.sh /var/log/babeld/babeld.log`
      - `./scripts/babeld_fileserver_errors.sh /var/log/babeld/babeld.log "16/Mar/2026:18:"`

## How-To: Fast Scope Assessment (Read-Only)

1. Confirm GHES host health:
    - `hostname`
    - `date -Is`
    - `ghe-service-list`

2. Measure protocol impact in HAProxy:
    - Run `haproxy_git_refs_status_summary.sh`
    - If `503` dominates, continue scope drill-down.

3. Check blast radius:
    - Run `haproxy_git_refs_window_top.sh`
    - Inspect top repos and top IPs.

4. Confirm backend signature in babeld:
    - Run `babeld_fileserver_errors.sh`
    - Look for `short read` + `FileServerConnectionError` + `status_code="503"`.

5. Cross-check admin path:
    - `journalctl -u ssh -u sshd -n 100 --no-pager`
    - If admin SSH is healthy while Git path fails, classify as backend Git path issue.

## Decision Guide: User-Specific vs Platform-Wide

- **Likely user/client-specific** when:
   - Failure tied to one IP/user/repo only.
   - No widespread 503 pattern in `info/refs`.
   - No backend error signatures in babeld.

- **Likely platform-wide** when:
   - Multi-repo and multi-IP 503 on `info/refs`.
   - Repeated babeld `FileServerConnectionError` and `short read`.
   - SSH and HTTPS Git paths both show failures.

## Incident Ticket Checklist (Generic)

Include at minimum:

1. UTC time window (`date -Is` based).
2. Service snapshot (`ghe-service-list`).
3. Status distribution from HAProxy (`200/401/503/5xx`).
4. Top affected repos and source IPs.
5. Babeld backend error samples.
6. Statement whether admin SSH path is healthy.

## Field Signals Seen in GHES Production

When users report `kex_exchange_identification: Connection closed by remote host` and/or repeated Git fetch/push failures, validate these **specific signals**:

1. **Admin SSH can succeed while Git SSH fails**
   - `admin@<ghes-host>:<admin-port>` accepted with key in `sshd` logs
   - Simultaneous failures on Git path (`ssh_protocol` via HAProxy/babeld)
   - Interpretation: likely **backend Git path issue**, not a user key/global firewall block.

2. **HAProxy Git smart-http failures**
   - Repeated `503` on `/<org>/<repo>.git/info/refs?service=git-upload-pack` or `git-receive-pack`
   - Appearing across multiple repos and multiple source IPs indicates broad impact.

3. **Babeld backend signature**
   - `failed to read HTTP proxy response: short read`
   - `FileServerConnectionError`
   - `failed to write initial git chunk`
   - `status_code="503"`
   - Interpretation: failure between babeld and fileserver/proxy backend, not a single client credential issue.

## Scope Check Playbook

To classify impact quickly, always check all three dimensions:

- **By repository**: top repos with `503` on `info/refs`
- **By source IP**: top client IPs with `503`
- **By protocol path**:
  - `sshd` admin acceptance
  - `haproxy` `ssh_protocol` short sessions
  - `haproxy` `https_protocol~ babeld_http` with 503

If failures appear in multiple repos and multiple IPs over time, treat as platform issue even if one user reported first.

## Incident Escalation Guidance

Raise incident when one or more conditions are true:

- Sustained `503` on Git `info/refs` for production repos for > 15 minutes.
- Cross-repo and cross-IP impact.
- Concurrent SSH handshake closures and smart-http failures.
- Clear babeld `FileServerConnectionError` evidence.

Minimum evidence bundle for incident ticket:

1. Time window in UTC.
2. Sample HAProxy lines for affected repo(s) and IP(s).
3. Sample babeld error lines showing `short read` and `503`.
4. Confirmation that admin SSH/auth path is healthy (to rule out user-key-only issues).
5. Current service summary (`ghe-service-list`) snapshot.
