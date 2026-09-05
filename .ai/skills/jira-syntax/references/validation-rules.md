# Jira Validator Rules

Reference explaining every rule the validator (`scripts/validate-jira-syntax.sh`)
checks, why it exists, and whether it is an **ERROR** (blocks submission) or a
**WARNING** (tells the agent / doc-only).

> Priority: **ERRORs** are Jira-breaking markup that must be fixed before posting.
> **WARNINGs** are structural or doc-only notes that do NOT block submitting.

## Rules (ERROR — Jira-breaking)

These produce broken rendering in Jira if left in a comment/description body.

| Rule | Pattern | Why ERROR |
|:--|:--|:--|
| Markdown `**bold**` | `**text**` | `**` is Markdown; Jira needs `*text*`. Silent no-render. |
| Markdown link `[text](url)` | `\[[^]]+\]\([^)]+\)` | Markdown links don't render; Jira needs `[text\|url]`. |
| CLI-escaped Jira chars | `\*`, `\[`, `\{{`, `\(`, `\~`, `\|` | The CLI escapes the body, producing literal backslashes. |
| Unclosed `{code}` block | odd number of `{code}`/`{code:lang}` markers | A code block left open breaks everything after it. |
| Malformed `{code::lang}` | `{code::lang}` | Double colon is invalid; must be `{code:lang}`. |

Note on **CLI-escaped chars**: these are detected with `grep -P` (PCRE) because
ERE cannot express `{` `}` inside a character class. Legitimate `\\` (Jira line
break) is preserved.

## Rules (WARNING — structural / doc-only)

These are valid in documentation or templates but should NOT be used in a Jira
body. They tell the agent to prefer Jira syntax.

| Rule | Pattern | Why WARNING |
|:--|:--|:--|
| Markdown headings `#`/`##` | `^#{1,6}` | Legit in skill docs/templates; Jira body needs `h2.`. |
| Markdown code fences ` ``` ` | `^\`\`\`` | Legit in skill docs; Jira needs `{code:lang}`. |
| Markdown dash bullets `- item` | `^-` | Dash bullets render oddly; Jira prefers `* item`. |
| Markdown inline code `` `x` `` | `` `x` `` | Jira needs `{{x}}`; only flagged if no `{{}}` present. |

## Rules (deliberately NOT checked — avoid false positives)

| Rule | Reason NOT checked |
|:--|:--|
| Bare `{code}` (no language) | It is **valid Jira** — just no syntax highlighting. |
| `{panel}` balance | A bare `{panel}` can be open OR close → ambiguous → false positives. |
| Table column counts | Headers use `\|\|` and data uses `\|`; a pipe-count heuristic is wrong. |

## Why this matters

The validator can only catch **syntactic** issues. It cannot catch every
rendering nuance. The golden rule:
**run the validator AND re-read for stray `\*`, `\[`, `\{{`, and `**`** before
and after posting. The agent should apply the Markdown→Jira mapping
(`markdown-to-jira-mapping.md`) *before* generating, so the validator is a
safety net — not the primary authoring mechanism.

## Exit codes

| Code | Meaning |
|:--|:--|
| `0` | No errors (warnings allowed). Safe to submit. |
| `1` | One or more ERRORs found. Fix before submitting. |
