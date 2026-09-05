# Markdown → Jira Wiki Markup Mapping

Complete conversion reference between Markdown and Jira Text Formatting Notation
(Wiki Markup). This is the canonical mapping the agent should apply **before**
generating Jira text, so the output is correct on the first pass.

> Source: cross-referenced with the Go CLI [`astsu-dev/md2jira`](https://github.com/astsu-dev/md2jira)
> and Atlassian's Text Formatting Notation.

## Text Formatting (Emphasis)

| Markdown | Jira | Description |
| :-- | :-- | :-- |
| `**bold**` | `*bold*` | Bold |
| `__bold__` | `*bold*` | Bold (alternate) |
| `*italic*` | `_italic_` | Italic |
| `_italic_` | `_italic_` | Italic (alternate) |
| `***both***` | `*_both_*` | Bold + italic |
| `~~strike~~` | `-strike-` | Strikethrough |
| `` `code` `` | `{{code}}` | Inline / monospaced code |

## Headings

| Markdown | Jira |
| :-- | :-- |
| `# Heading 1` | `h1. Heading 1` |
| `## Heading 2` | `h2. Heading 2` |
| `### Heading 3` | `h3. Heading 3` |
| `#### Heading 4` | `h4. Heading 4` |
| `##### Heading 5` | `h5. Heading 5` |
| `###### Heading 6` | `h6. Heading 6` |

## Lists

| Markdown | Jira |
|:--|:--|
| `- item` | `* item` |
| `* item` | `* item` |
| `1. item` | `# item` |
| Nested unordered | `** item` |
| Nested ordered | `## item` |
| Mixed nested | `*# item` / `#* item` |
| `- [ ] task` | `* ( ) task` |
| `- [x] task` | `* (/) task` |

## Links and Images

| Markdown | Jira |
|:--|:--|
| `[text](url)` | `[text\|url]` |
| `[text](url "title")` | `[text\|url]` |
| `![alt](url)` | `!url\|alt=text!` |

## Code Blocks

| Markdown | Jira |
|:--|:--|
| ```` ``` ```` (fenced) | `{code:language}...{code}` |
| ```` ```javascript ```` | `{code:javascript}...{code}` |
| Indented code | `{noformat}...{noformat}` (preformatted, no highlight) |

## Tables

| Markdown | Jira |
|:--|:--|
| `\| Header \|` (GFM pipes) | `\|\| Header \|\|` (double pipe header) |
| `\| cell \|` | `\| cell \|` (single pipe data) |

## Block Quotes / Panels / Color

| Markdown | Jira |
|:--|:--|
| `> quote` | `bq. quote` (single) or `{quote}...{quote}` (multi) |
| — | `{panel:title=X}...{panel}` |
| — | `{color:red}text{color}` |

## Paragraphs / Breaks / Rules

| Markdown | Jira |
|:--|:--|
| blank line | blank line (new paragraph) |
| `  ` (two spaces, hard break) | `\\` at end of line (force break) |
| `---` (horizontal rule) | `----` on its own line |
| `—` (em dash) | `---` |
| `–` (en dash) | `--` |

## User Mentions and Issue Links

| Markdown | Jira |
|:--|:--|
| `@user` | `[~username]` |
| `PROJ-123` | `[PROJ-123]` |
| `[label](url)` | `[label\|url]` |

## Important Pitfalls (why the validator exists)

1. **`**bold**` does NOT render in Jira** — you must use `*bold*`. The validator
   treats `**bold**` as an ERROR.
2. **Backticks `` `code` `` do NOT render** — you must use `{{code}}`.
3. **`[text](url)` does NOT render** as a link — you must use `[text\|url]`.
4. **The Jira CLI escapes the body** when posted via `--template`, `-b`, or stdin,
   producing literal `\*`, `\[`, `\{{`. Always submit via the REST API.
5. **Bare `{code}` (no language) is still valid** — only no syntax highlighting.
6. **Jira `{code}` has NO `{/code}`** — both open and close use the `{code}` token.
