---
name: disk-cleanup-analysis
description: Analyze Linux disk usage (/, home, Docker, caches) and propose safe cleanup commands without making changes.
---

# Disk Cleanup Analysis (Linux)

## Purpose
Provide a read-only disk usage analysis focused on `/`, `$HOME`, Docker, and user caches. Produce safe cleanup recommendations and optional command lists without executing deletions.

## Scope
- Linux hosts
- Root filesystem usage, user home usage
- Docker images/containers/build cache
- User caches (Playwright, Puppeteer, Trivy, pip, npm, pre-commit, VS Code server)

## Workflow
1. **Baseline usage**: gather `df -hT /`, `df -i /`, and identify top-level directories on `/`.
2. **Drill down**: focus on `/var`, `/usr`, `/opt`, and `$HOME` to identify large subdirectories.
3. **Home analysis**: identify heavy folders (repos, `.cache`, `.npm`, VS Code server) and their biggest subfolders.
4. **Docker analysis**: summarize `docker system df -v`, list dangling images, stopped containers, and build cache usage.
5. **Recommendations**: present safe cleanup candidates with sizes and provide commands only when asked.

## Read-Only Commands (examples)
- Filesystem: `df -hT /`, `df -i /`, `du -x --max-depth=1 -h /`
- Home: `du -x --max-depth=2 -h ~/.cache | sort -hr | head -n 80`
- Docker: `docker system df -v`, `docker images -f dangling=true`

## Cleanup Guidance (no execution)
- Prefer cache cleanup (Playwright, Puppeteer, Trivy, pip, npm, pre-commit).
- Prefer Docker build cache cleanup before deleting images.
- For VS Code server, recommend pruning old server versions and logs.

## Safety Rules
- Do not delete or modify files unless explicitly requested.
- Use read-only analysis by default.
- Present cleanup commands as optional, one per line.
