# HTML → ADF format for Jira

Catalogue for the Atlassian MCP HTML converter documented by this skill
(`contentFormat: "html"`). Discover the installed tool schemas and consult its
`getContentFormatGuide` when available: support can differ between servers or versions.
Jira Cloud REST API v3 instead accepts ADF in `body`; do not confuse that object with MCP arguments.

> **Jira only.** Column *layouts* (`<section data-type="layout-*">` and their
> `<div data-type="column">` children) are not supported for Jira by the documented converter.
> They can lose content or cause rejection. Lay the content out as consecutive blocks instead.

## ADF to HTML

Translate the **content**, not the JSON representation. Walk the existing ADF document in order,
preserving text, nesting and supported marks. Keep the original ADF for comparison; do not send
`JSON.stringify(adf)` as `commentBody` or wrap HTML in the REST `body` object.

| ADF node or mark | HTML |
| --- | --- |
| `doc` | Consecutive converted child blocks (no JSON wrapper) |
| `heading`, `attrs.level` | `<h1>` through `<h6>` with the same level |
| `paragraph` | `<p>...</p>` |
| `text` with `strong`, `em`, `code` | Escaped text with `<strong>`, `<em>`, `<code>` as supported |
| `link`, `attrs.href` | `<a href="escaped URL">...</a>`; preserve the label |
| `bulletList`, `orderedList`, `listItem` | `<ul>` / `<ol>` / `<li>`; keep child paragraphs and nesting; preserve start number |
| `table`, `tableRow`, `tableHeader`, `tableCell` | `<table>`, `<tr>`, `<th>`, `<td>`; put child `<p>` blocks inside cells |
| `panel`, `attrs.panelType` | `<div data-type="panel-TYPE">...</div>` with converted child blocks |
| `codeBlock`, `attrs.language` | `<pre><code class="language-LANGUAGE">escaped text</code></pre>`; preserve newlines |
| `hardBreak`, `rule`, `blockquote` | `<br>`, `<hr>`, `<blockquote>...</blockquote>` |

For an unsupported node or attribute (including media), consult the installed guide before
converting. Do not silently drop it or replace meaningful content. State the limitation and seek an
explicit content decision if fidelity cannot be preserved.

### Escaping and fidelity

- In **text**, escape `&`, `<` and `>` as `&amp;`, `&lt;` and `&gt;`.
- In quoted **attribute values**, also escape `"` as `&quot;` (and `'` as `&#39;` if using
  single-quoted attributes). Validate links and use only the schemes supported by the converter.
- Escape raw values once when generating HTML; do not double-escape already serialized HTML.
- Inside a code block, treat all code as text, never as HTML or Markdown. Preserve indentation,
  newlines and the language; omit the language class if none is known.
- Do not put secret values in the generated HTML, including examples, links or code blocks.

For example, code text `if (a < b && b > 0)` becomes:

```html
<pre><code class="language-javascript">if (a &lt; b &amp;&amp; b &gt; 0)</code></pre>
```

Compact structural example (replace the bracketed text before publication):

```html
<h2>[Report title]</h2>
<p><strong>[Status]</strong> — [actual date]</p>
<div data-type="panel-info"><p>[Summary and limitation]</p></div>
<ul><li><p>[Change] in <code>[file]</code>.</p></li></ul>
<table>
  <tr><th><p>Check</p></th><th><p>Result</p></th></tr>
  <tr><td><p>[Check]</p></td><td><p>[Confirmed result]</p></td></tr>
</table>
```

After a write, re-read the comment by its returned ID and compare semantic structure and text, not
byte-for-byte serialization: Jira can normalize HTML into ADF. Verify headings, panel types, table
dimensions/cell content, code language/text, links and lists. Inspect applied format fields only if
returned. If no Jira MCP is installed, these examples can be checked locally but **no live conversion
or publication verification can be claimed**.

## Blocks

| Element | Pattern |
| --- | --- |
| Heading | `<h1>`…`<h6>` |
| Paragraph | `<p>text</p>` |
| Bullet list | `<ul><li>item</li></ul>` |
| Ordered list | `<ol start="1"><li>item</li></ol>` |
| Task list | `<ul data-type="task-list"><li data-type="task-item"><input type="checkbox" checked> Done</li></ul>` |
| Table | `<table><thead><tr><th><p>H</p></th></tr></thead><tbody><tr><td><p>C</p></td></tr></tbody></table>` |
| Blockquote | `<blockquote><p>quoted text</p></blockquote>` |
| Code block | `<pre><code class="language-yaml">…</code></pre>` |
| Horizontal rule | `<hr>` |
| Panel | `<div data-type="panel-TYPE"><p>…</p></div>` |
| Custom panel | `<div data-type="panel-custom" data-icon=":emoji:" data-color="#DEEBFF"><p>…</p></div>` |
| Expand | `<details><summary>Title</summary><p>hidden</p></details>` |
| Block card | `<div data-type="block-card" data-url="URL"><a href="URL">URL</a></div>` |
| Embed card | `<div data-type="embed-card" data-layout="center"><iframe src="URL"></iframe></div>` |

**Panel types:** `info`, `note`, `warning`, `success`, `error` (`tip` is accepted as `info`).

Numeric sizing attributes: unitless decimal (`data-width="80.5"`, not `"80px"` or `"80%"`).

## Inline elements

| Element | Pattern |
| --- | --- |
| Bold | `<strong>text</strong>` (also `<b>`) |
| Italic | `<em>text</em>` (also `<i>`) |
| Underline | `<u>text</u>` |
| Strikethrough | `<s>text</s>` |
| Inline code | `<code>text</code>` |
| Subscript / superscript | `<sub>x</sub>` / `<sup>x</sup>` |
| Text color | `<span style="color: #0747A6">text</span>` |
| Highlight | `<span style="background-color: #F8E6A0">text</span>` |
| Link | `<a href="URL">text</a>` |
| Same-page heading link | `<a href="#My-heading">text</a>` |
| Line break | `<br>` |
| Status lozenge | `<span data-type="status" data-color="green">Done</span>` |
| Mention | `<span data-type="mention" data-user-id="ACCOUNT_ID">@Name</span>` |
| Date | `<time datetime="2026-10-13">2026-10-13</time>` |
| Emoji | `<span data-type="emoji" data-shortname=":rocket:">🚀</span>` |
| Placeholder | `<span data-type="placeholder">Type something…</span>` |

**Lozenge colors:** `neutral`, `purple`, `blue`, `red`, `yellow`, `green`.

**Valid text colors:** `#172b4d` (default), `#0747a6`, `#008da6`, `#006644`, `#ff991f`, `#bf2600`,
`#403294`, `#97a0af`, `#4c9aff`, `#00b8d9`, `#36b37e`, `#ffc400`, `#ff5630`, `#6554c0`, `#ffffff`.

## Constraints to respect

- **`<code>` accepts no further inline formatting.** A `<strong>` or any other mark inside a
  `<code>` is dropped; a `<code>` inside an `<a>` loses the code style and keeps the link.
- **No Confluence storage XML.** `<ac:structured-macro>`, `<ac:rich-text-body>`,
  `<ac:plain-text-body>`, `<ri:page>` or CDATA are printed as literal text.
- **Structured dates use `<time datetime="YYYY-MM-DD">`** when supported by the converter.
  Plain-text report dates are also useful, especially with a timezone. Do not wrap durations,
  versions or values that are not dates.
- **Alignment and indentation cannot be combined** on the same paragraph.

## Link card appearances

`data-card-appearance` on an `<a>` changes how the link renders:

| Value | ADF node | Renders as |
| --- | --- | --- |
| `inline` | `inlineCard` | an inline pill, inside a sentence |
| `block` | `blockCard` | a standalone summary card |
| `embed` | `embedCard` | a full embedded view |

`block` and `embed` are block-level: put the `<a>` on its own, not mid-paragraph. The anchor text is
dropped (the card is generated from the URL), so leave it empty:
`<a href="URL" data-card-appearance="embed"></a>`.

## Official references (only if something does not add up)

This catalogue is the distilled version — prefer it for the common case. Go to the official docs only
when you hit an element that is not here, need the exact `attrs`/children of a node, or Jira behaves
differently from what is written above.

| Doubt | Consult |
| --- | --- |
| Node or mark not in this catalogue | [ADF structure](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) |
| One node's `attrs` and allowed children | [ADF nodes](https://developer.atlassian.com/cloud/jira/platform/apis/document/nodes/doc) |
| One mark's details | [ADF marks](https://developer.atlassian.com/cloud/jira/platform/apis/document/marks/) |
| Validate against the schema | [ADF JSON schema](http://go.atlassian.com/adf-json-schema) |
| Inspect the ADF of something you typed | [ADF document builder](https://developer.atlassian.com/cloud/jira/platform/apis/document/viewer/) |
| Comments API endpoints and fields | [Issue comments REST API v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-comments/) |
