---
name: jira-syntax
description: "Use when writing or formatting Jira descriptions, comments, or any text destined for Jira. Converts Markdown to Jira wiki markup, provides templates (bug reports, feature requests), and validates syntax before submission. Trigger on any Jira content authoring task."
license: "(MIT AND CC-BY-SA-4.0). See LICENSE-MIT and LICENSE-CC-BY-SA-4.0"
metadata:
  author: Netresearch DTT GmbH
  version: "3.10.0"
  repository: https://github.com/netresearch/jira-skill
---

# Jira Syntax

Jira wiki markup syntax, templates, and validation. For API operations, use the **jira-communication** skill.

## Quick Syntax Reference

| Jira Syntax | Purpose | NOT this (Markdown) |
|-------------|---------|---------------------|
| `h2. Title` | Heading | `## Title` |
| `*bold*` | Bold | `**bold**` |
| `_italic_` | Italic | `*italic*` |
| `{{code}}` | Inline code | `` `code` `` |
| `{code:java}...{code}` | Code block | ``` ```java ``` |
| `[text\|url]` | Link | `[text](url)` |
| `[PROJ-123]` | Issue link | - |
| `[~username]` | User mention | `@username` |
| `* item` | Bullet list | `- item` |
| `# item` | Numbered list | `1. item` |
| `\|\|Header\|\|` | Table header | `\|Header\|` |

## References (load as needed)

Read the relevant reference file when doing Jira authoring or validation:

| File | When to read |
| :-- | :-- |
| `references/jira-syntax-quick-reference.md` | Complete Jira wiki markup syntax reference. |
| `references/markdown-to-jira-mapping.md` | Converting Markdown text to Jira wiki markup. |
| `references/validation-rules.md` | What the validator flags (ERROR vs WARNING) and why. |
| `references/jira-api-comments.md` | Safe Jira comment/description submission via REST API (avoids CLI escaping). |

**Authoring first, validating second.** To produce correct Jira on the first pass,
apply the Markdown→Jira mapping (`markdown-to-jira-mapping.md`) *while authoring*,
then use the validator as a safety net.

## Available Templates

### Bug Report
**Path**: `templates/bug-report-template.md`

Sections: Environment, Steps to Reproduce, Expected/Actual Behavior, Error Messages, Technical Notes

### Feature Request
**Path**: `templates/feature-request-template.md`

Sections: Overview, User Stories, Acceptance Criteria, Technical Approach, Success Metrics

## Syntax Validation

Run before submitting to Jira:
```bash
${CLAUDE_SKILL_DIR}/scripts/validate-jira-syntax.sh path/to/content.txt
```

### Running the test battery

Verify the validator against the regression test cases (T1–T15):
```bash
${CLAUDE_SKILL_DIR}/scripts/tests/run_tests.sh            # pass/fail summary
${CLAUDE_SKILL_DIR}/scripts/tests/run_tests.sh --verbose  # show per-test detail
```

### Validation Checklist
- [ ] Headings: `h2. Title` (space after period)
- [ ] Bold: `*text*` (single asterisk)
- [ ] Code blocks: `{code:language}...{code}`
- [ ] Lists: `*` for bullets, `#` for numbers
- [ ] Links: `[label|url]` or `[PROJ-123]`
- [ ] Tables: `||Header||` and `|Cell|`
- [ ] Colors: `{color:red}text{color}`
- [ ] Panels: `{panel:title=X}...{panel}`

### Common Mistakes

| ❌ Wrong | ✅ Correct |
|---------|-----------|
| `## Heading` | `h2. Heading` |
| `**bold**` | `*bold*` |
| `` `code` `` | `{{code}}` |
| `[text](url)` | `[text\|url]` |
| `- bullet` | `* bullet` |
| `h2.Title` | `h2. Title` |

### Stricter checks the validator now catches (learned in practice)

These real issues were found after a validator run claimed success. Always
confirm these *before* submitting:

| ❌ Wrong | ✅ Correct | Why it matters |
|---------|-----------|----------------|
| `**closed**` | `*closed*` | `**` is Markdown bold, silently not rendered in Jira |
| `\* bullet` | `* bullet` | The CLI escapes the body; `\*` renders as literal `\*` |
| `\{{code\}}` | `{{code}}` | CLI escaping breaks inline code |
| `[text](url)` | `[text\|url]` | Markdown link style is not Jira |
| `- item` | `* item` | Dash bullets render oddly vs Jira asterisk |

> **Golden rule:** always run the validator, AND re-read for stray `\*`, `\[`,
> `\{{`, and `**` before/after posting. The validator cannot catch every
> rendering nuance.

## Integration with jira-communication Skill

**Workflow:**
1. Get template from jira-syntax
2. Fill content using Jira wiki markup
3. Validate with `${CLAUDE_SKILL_DIR}/scripts/validate-jira-syntax.sh`
4. Submit via jira-communication skill

## ⚠️ CLI Escaping Trap (learned in practice)

The `jira issue comment add` CLI **escapes** special characters (`\*`, `\(`,
`\-`, `\[`, `\]`, `~`) when the body is passed via `--template <file>`, `-b`,
or stdin. This silently breaks Jira wiki markup — bullets render as literal
`\*`, bold as `\*text\*`, and `{{code}}` becomes `\{{code\}}`.

**This escaped body is the #1 source of "validator passed but Jira is broken".**

**Safe submission path for anything with formatting:**

1. Write the body in a `.txt` file using Jira wiki markup.
2. Submit via the REST API (Bearer token):

```bash
curl -s -X POST \
  -H "Authorization: Bearer $JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://YOUR-JIRA-INSTANCE/rest/api/2/issue/PROJ-XXXX/comment" \
  -d "$(jq -n --arg b "$(cat /tmp/body.txt)" '{body: $b}')"
```

3. **Always verify after posting** — re-fetch by API and confirm no backslash
   escapes remain (bullets must be `*`, code must be `{{...}}`). If broken, fix
   with `PUT .../comment/<id>`.

**MCP backend** (`mcp__atlassian__addCommentToJiraIssue`) does not escape and is
safe to use directly.

### Verification snippet (copy/paste after posting)

Re-fetch the comment and scan for residual backslash escapes:

```bash
curl -s -X GET \
  -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://YOUR-JIRA-INSTANCE/rest/api/2/issue/PROJ-XXXX/comment/<id>" \
  | grep -Po '\\[*_\-\[\]()~|{}]' || echo "NO ESCAPES ✓"
```

If any backslash-marker shows up, the CLI stripped the markup — repair with a
`PUT .../comment/<id>` using the clean body.

## External references & tools

These are third-party projects on GitHub related to Jira formatting, conversion,
and validation. Prefer them for a robust (non-bash) implementation of the
Markdown→Jira conversion; this skill's bash validator covers the validation
side.

| Tool | URL | What it does | Reuse |
| :-- | :-- | :-- | :-- |
| `astsu-dev/md2jira` (Go) | https://github.com/astsu-dev/md2jira | CLI + Go library to convert Markdown → Jira Text Formatting Notation | ✅ Ideal to replace bash validator with a compiled binary + tests |
| `evilfaust/jira-wiki-preview` (VS Code) | https://github.com/evilfaust/jira-wiki-preview | VS Code extension: Jira Wiki Markup syntax highlighting + live side-by-side preview | Preview what you wrote |
| `s2005/jira-formatting-skill` | https://github.com/s2005/jira-formatting-skill | Claude skill + VS Code snippets for Jira text formatting per Atlassian rules | Reference syntax rules (more complete, official) |
| `danielmontes9/md2jira` (TypeScript) | https://github.com/danielmontes9/md2jira | MD → Jira Wiki Markup, ADF, Confluence Storage (`md2jira-core`) | Alternative MD→Jira conversion |
| `kenchan0130/markdown-to-atlassian-wiki-markup` (JS) | https://github.com/kenchan0130/markdown-to-atlassian-wiki-markup | MD → Atlassian wiki markup (lib + CLI) | Alternative conversion |
| `peter-evans/jira2md` (JS) | https://github.com/peter-evans/jira2md | Jira text formatting ↔ GitHub flavored Markdown | Reverse conversion (Jira → MD) |
| `Ragnoroct/jira-wiki-previewer` | https://github.com/Ragnoroct/jira-wiki-previewer | Gives a preview for Jira Wiki syntax | Preview render |

> **Recommendation (decision)**: Do *not* re-implement Markdown→Jira conversion.
> Reuse [`astsu-dev/md2jira`](https://github.com/astsu-dev/md2jira) (Go) for that.
> Our unique value is the **robust validation + tests + CLI-escape handling +
> templates** — none of which external projects ship. So, rather than forking
> `s2005/jira-formatting-skill` (which only has syntax reference + snippets with
> **no validator**), keep this skill as the validation layer and **link out** to
> the conversion tool and the official reference. If a compiled binary is
> desired later, port just the *validator* (bag of rules + tests) to Go as a
> `jira-validate` command — the conversion stays in `md2jira`.

## Official documentation

- [Atlassian Jira Wiki Markup](https://jira.atlassian.com/secure/WikiRendererHelpAction.jspa?section=all)

## References (index)

- `references/jira-syntax-quick-reference.md` — Complete syntax reference.
- `references/markdown-to-jira-mapping.md` — MD → Jira conversion mapping.
- `references/validation-rules.md` — Validator rules (ERROR vs WARNING).
- `references/jira-api-comments.md` — Safe REST-API submission (no CLI escaping).
- `templates/bug-report-template.md` — Bug report template.
- `templates/feature-request-template.md` — Feature request template.
- `scripts/validate-jira-syntax.sh` — Automated syntax checker (bash).
- `scripts/tests/run_tests.sh` — Regression test battery (T1–T15).
