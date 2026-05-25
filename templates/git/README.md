# Git templates

This folder stores only the shared **local identity seed templates** used by both Linux and Windows entrypoints.

## What lives here

- `gitconfig.d/personal-mail.gitconfig` — local personal identity template with placeholders
- `gitconfig.d/work/work.gitconfig` — local work routing template with `<WORK_GIT_HOST>` placeholder
- `gitconfig.d/work/work-company.gitconfig` — local work identity template with placeholders

The authoritative shared Git config remains versioned at the repo root in `\.gitconfig` and `\.gitconfig.d\*` because those files are linked directly into the home directory.

These template files are not the final user-specific identity files by themselves; the bootstrap helpers copy them into ignored local files under `.gitconfig.d/` when those files are missing.
