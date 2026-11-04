---
name: add-comment-jira-cloud
description: "Publish a rich-formatted comment on a Jira Cloud issue using the Atlassian MCP. Use it to leave reports, status updates or notes on a ticket (Jira issue comment) with tables, panels, code blocks and links without losing formatting. Also to edit or replace an existing Jira comment."
argument-hint: "<issue key or URL> + comment content"
---

# Add Comment to Jira Cloud

Publish a formatted comment (tables, panels, code, links) on a Jira Cloud issue with the Atlassian
MCP, without losing formatting.

## When to use

- You need to leave a **report**, **status update** or **note** on a Jira issue.
- The content includes **tables, panels, code blocks or links**.
- You need to **edit** or **replace** an already published comment.

## Golden rule

For the **Atlassian MCP contract documented here**, author `commentBody` in **HTML** with
`contentFormat: "html"`. Its converter produces the ADF stored by Jira. Discover the available tools
and read their actual schemas before invoking them; use `getContentFormatGuide` if available.
Those schemas and the guide take precedence over this skill if they differ.

This is not a universal rule for every MCP server or version. **Jira Cloud REST API v3** accepts an
ADF document in its `body` field. That REST object is not the MCP argument schema: do not send
`{"body": ...}` or serialized ADF JSON as `commentBody`. To reuse an existing ADF report, translate
its structure to HTML as described in [the reference](./references/html-format.md#adf-to-html).

## Procedure

1. **Discover tools and their schemas**, including the resource, issue, comment and format-guide
   tools named below. Do not invent signatures or assume a tool is installed. Get the `cloudId`
   with `getAccessibleAtlassianResources` when available and reuse the confirmed resource for this
   session. In the documented contract it is a top-level argument, not inside `inputs`.
2. **Confirm the target issue** before writing:
   - With a key (`PROJ-123`) or a URL → `getJiraIssue`, using the identifier format its schema accepts.
   - From a vague description ("my ticket in Done") → `searchJiraIssuesUsingJql`:
     ```jql
     assignee = currentUser() AND status in (Done, Closed) ORDER BY updated DESC
     ```
   - If more than one candidate comes back, **ask** which one. A comment on the wrong issue does not
     undo itself.
3. **Prepare and publish** with `addOrEditJiraIssueComment` using its discovered schema (in this
   contract, without `commentId` it creates; with `commentId` it edits). Before an edit, read the
   existing comment and preserve content the user did not ask to replace. Only write when the user
   requested publication or editing; improving this skill does not authorize a Jira write.
   | Argument | Value |
   | --- | --- |
   | `cloudId` | the one from step 1 (top level) |
   | `issueIdOrKey` | confirmed issue identifier accepted by the schema |
   | `contentFormat` | **`"html"`** |
   | `commentBody` | the HTML of the content |
4. **Verify (not optional):** re-read with `listJiraIssueComments` (paginate if needed) and match the
   returned comment ID. Compare stored content and structure with what was sent: headings, links,
   lists, panel types, table cells and code language/text. If `body` is ADF, inspect its
   `panel`, `table` and `codeBlock` nodes rather than expecting HTML back. Check
   `appliedContentFormat` or other applied fields **only if the tool returns them**; their absence
   is not evidence of failure. A successful write response alone does not prove formatting.
5. **Report** only after step 4, quoting the `commentId` returned by the tool (do not invent or assume
   it).

If a write times out or returns a transport error, **read before retrying**: it may already have
created the comment. Look for the intended content and author in recent comments; never blindly
create a duplicate. If the outcome is ambiguous, stop and report uncertainty. If no Jira MCP is
available, prepare HTML only and explicitly state that publication and live verification were not
performed.

## Format

The full catalogue of blocks and inline elements (panels, tables, code, lozenges, mentions, dates,
emoji) is in [`./references/html-format.md`](./references/html-format.md).

**Panel types:** `info`, `note`, `warning`, `success`, `error` (`tip` is accepted as `info`).

### Report structure

Use a title and actual report date, followed by a short status panel. Select only useful sections:
**what was done**, **how it works**, **secret configuration**, **checks/evidence**, **risks and
alternatives**, and **pending work with an owner**. Do not force six sections or wide tables on a
short update; bullets or two-column tables are often clearer.

For a secret, include its **name, type, location, owner, required permissions versus verified
permissions, and expiry** when relevant. Never include its value or fragments. Distinguish
configured, published, merged and deployed states. Link evidence and state the result of each check;
mark unavailable evidence, unknown owners and unknown expiry explicitly instead of inventing them.

Reusable scaffold (replace every bracketed placeholder with confirmed information, or remove the
optional block; this is not a factual report):

```html
<h2>[Report title]</h2>
<p>Date: [actual date and timezone]</p>
<div data-type="panel-info">
  <p><strong>[Confirmed status].</strong> [Summary and important limitation].</p>
</div>
<h3>What was done</h3>
<ul><li><p>[Confirmed change and scope].</p></li></ul>
<h3>How it works</h3>
<p>[Source, destination, trigger and review/activation path].</p>
<h3>Secret configuration</h3>
<ul>
  <li><p>Name/type/location: <code>[name]</code>; [type]; [location].</p></li>
  <li><p>Owner/expiry: [confirmed owner or unknown]; [confirmed expiry or unknown].</p></li>
  <li><p>Required permissions: [minimum requirements]. Verified: [evidence or not verified].</p></li>
</ul>
<h3>Checks and evidence</h3>
<table>
  <thead>
    <tr>
      <th><p>Check</p></th>
      <th><p>Result and evidence</p></th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><p>[Check performed]</p></td>
      <td><p>[Actual result; add a link to confirmed evidence]</p></td>
    </tr>
  </tbody>
</table>
<h3>Risks and alternatives</h3>
<div data-type="panel-note"><p>[Risk, impact and alternative or mitigation].</p></div>
<h3>Pending work</h3>
<ol>
  <li><p>[Action] — Owner: [confirmed owner or unassigned].</p></li>
</ol>
```

## Common errors

| Error                                  | Cause                                                       | Fix                                                                                                                                                   |
| -------------------------------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| ADF shows up as plain text             | JSON was sent as text to an HTML/string input                | For this MCP contract, translate to **HTML** with `contentFormat: "html"`; check the actual schema                                                       |
| Panels or media disappear when editing | Conversion omitted unsupported content                      | Re-read the original and use the installed format guide; preserve supported structure and report unsupported nodes                                     |
| The comment ends up empty              | The body contains an unsupported column layout               | Avoid `<section data-type="layout-*">` or `<div data-type="column">` in this Jira converter. Lay it out as consecutive blocks                            |
| The format is printed literally        | Confluence storage XML was used (`<ac:*>`, `<ri:*>`, CDATA) | Use the documented HTML                                                                                                                               |
| It is published on the wrong issue     | The target was not confirmed                                | Verify it in step 2                                                                                                                                   |
| The `commentId` does not match         | It was assumed instead of read                              | Take it from the tool response                                                                                                                        |

## Success criteria

The comment appears on the issue and, **when re-read from Jira**, preserves the same panels, tables
and code blocks that were sent. Only then is it reported as published.

## References

Everything this skill needs is already distilled here and in
[`./references/html-format.md`](./references/html-format.md). **Do not go digging in the docs below
for the common case** — they are long and mostly irrelevant. Reach for them only when something does
not add up: an element that is not in the catalogue, a node you need that is not listed, a field or
attribute you are unsure about, or a Jira response that contradicts what is written here. If a doubt
cannot be resolved with the catalogue, then:

| Doubt                                                                  | Consult                                                                                                                  |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| A node or mark is not in the catalogue (e.g. media, extension, layout) | [ADF structure](https://developer.atlassian.com/cloud/jira/platform/apis/document/structure/) — full node and mark lists |
| Details of one node (`attrs`, allowed children)                        | [ADF nodes](https://developer.atlassian.com/cloud/jira/platform/apis/document/nodes/doc) (one page per node)             |
| Details of one mark                                                    | [ADF marks](https://developer.atlassian.com/cloud/jira/platform/apis/document/marks/)                                    |
| Validate a document against the schema                                 | [ADF JSON schema](http://go.atlassian.com/adf-json-schema)                                                               |
| See the ADF for something you typed                                    | [ADF document builder](https://developer.atlassian.com/cloud/jira/platform/apis/document/viewer/) (WYSIWYG → ADF)        |
| Endpoints, fields, status codes of the comments API                    | [Issue comments REST API v3](https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-comments/)      |

Also available:

- Canonical MCP guidance: discover `getContentFormatGuide` and its schema before calling it. If its
  schema supports `toolName`, request the guide for `addOrEditJiraIssueComment`.
- Recorded POC example: file-sync report on `DC2C-93` (comment `10011`, 2026-10-13) — `success`
  and `note` panels, 4 tables and a YAML block recognised as code. This is historical evidence,
  not live verification in the current session or a default publication target.
