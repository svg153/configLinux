<!-- Managed by agent: keep sections & order; edit content, not structure. Last updated: 2025-12-12 -->

# AGENTS.md — jira-syntax

Development guide for maintaining templates, references, and validation scripts.

## Overview

Static content skill: templates, reference docs, and a validation script. No runtime dependencies.

## Setup & environment

No special setup. Files are plain text/markdown/shell.

## Build & tests

```bash
# Run the validator against a file
scripts/validate-jira-syntax.sh path/to/content.txt

# Run the regression test battery (T1–T15)
scripts/tests/run_tests.sh
scripts/tests/run_tests.sh --verbose   # per-test detail
```

The test battery (`scripts/tests/run_tests.sh`) is the source of truth for
validator behaviour. Add a new case there when fixing a validator bug.

## Code style & conventions

**Templates (`templates/`):**
- Use actual Jira wiki markup, never Markdown
- Include section comments explaining purpose
- Test in real Jira before committing

**References (`references/`):**
- Keep `jira-syntax-quick-reference.md` as single source of truth
- Examples must be copy-pasteable into Jira
- `markdown-to-jira-mapping.md`: MD→Jira conversion table (used while authoring)
- `validation-rules.md`: what the validator flags (ERROR vs WARNING) and why
- `jira-api-comments.md`: safe submission path via REST API (avoids CLI escaping)

**Validation script:**
- Bash with grep patterns
- Should catch common Markdown mistakes

## Lessons learned (from real Jira authoring work)

- **Do NOT count `{code}` block balance by token count.** In Jira, BOTH the
  opening (`{code:lang}`) and the closing (`{code}`) use the `{code}` token — there
  is no `{/code}`. Only count markers that are a line by themselves; an odd count
  means a block is left open. A narrative mention like "a {code} block" must not
  be counted.
- **Do NOT warn on bare `{code}` (no language).** It is a valid Jira block; the
  old regex `{code}[^{]` matched `{code:bash}` AND prose, causing false positives.
- **GNU grep ERE: `]` inside a character class must NOT be escaped.** Use
  `[^]]` (not `[^\]]`) to match "not a closing bracket". `[^\]]` is rejected.
- **Markdown `**bold**` is an ERROR, not a warning.** It silently breaks in Jira.
  Keep it as an error so it blocks submission.
- **CLI-escaped Jira chars must be detected.** The CLI adds literal backslashes
  (`\*`, `\{{`, `\[`). Use `grep -P` (PCRE) because ERE cannot express `{` `}`
  inside a character class. Preserve legitimate `\\` (Jira line break).
- **Do NOT validate `{panel}` balance by token count.** A bare `{panel}` can be
  either an opening or a closing, so counting produces false positives.

## Security & safety

- No executable code in templates
- No sensitive data in examples

## PR/commit checklist

- [ ] All examples use valid Jira wiki markup
- [ ] Tested in actual Jira instance
- [ ] Updated quick-reference if adding new syntax
- [ ] Validation script catches the patterns

## Good vs. bad examples

**Template changes:**
```
# ✓ Test paste into Jira before commit
# ✓ Update quick-reference if new syntax

# ✗ Assume Markdown works in Jira
# ✗ Add syntax without testing
```

## When stuck

- Paste content into real Jira to verify rendering
- Check official docs: https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa

## House rules

- SKILL.md has the user-facing syntax reference
- This file is for maintaining the skill itself

---

**Maintaining this file:** See root `AGENTS.md` for convention reference.
