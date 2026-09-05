---
name: jira
description: Use when the user mentions Jira issues (e.g., "PROJ-123"), asks about tickets, wants to create/view/update issues, check sprint status, or manage their Jira workflow. Triggers on keywords like "jira", "issue", "ticket", "sprint", "backlog", or issue key patterns.
---

# Jira

Natural language interaction with Jira. Supports multiple backends.

## Backend Detection

**Run this check first** to determine which backend to use:

```
1. Check if jira CLI is available:
   → Run: which jira
   → If found: USE CLI BACKEND

2. If no CLI, check for Atlassian MCP:
   → Look for mcp__atlassian__* tools
   → If available: USE MCP BACKEND

3. If neither available:
   → GUIDE USER TO SETUP
```

| Backend | When to Use | Reference |
|---------|-------------|-----------|
| **CLI** | `jira` command available | `references/commands.md` |
| **MCP** | Atlassian MCP tools available | `references/mcp.md` |
| **None** | Neither available | Guide to install CLI |

---

## Quick Reference (CLI)

> Skip this section if using MCP backend.

| Intent | Command |
|--------|---------|
| View issue | `jira issue view ISSUE-KEY` |
| List my issues | `jira issue list -a$(jira me)` |
| My in-progress | `jira issue list -a$(jira me) -s"In Progress"` |
| Create issue | `jira issue create -tType -s"Summary" -b"Description"` |
| Move/transition | `jira issue move ISSUE-KEY "State"` |
| Assign to me | `jira issue assign ISSUE-KEY $(jira me)` |
| Unassign | `jira issue assign ISSUE-KEY x` |
| Add comment | `jira issue comment add ISSUE-KEY -b"Comment text"` |
| Open in browser | `jira open ISSUE-KEY` |
| Current sprint | `jira sprint list --state active` |
| Who am I | `jira me` |

---

## Quick Reference (MCP)

> Skip this section if using CLI backend.

| Intent | MCP Tool |
|--------|----------|
| Search issues | `mcp__atlassian__searchJiraIssuesUsingJql` |
| View issue | `mcp__atlassian__getJiraIssue` |
| Create issue | `mcp__atlassian__createJiraIssue` |
| Update issue | `mcp__atlassian__editJiraIssue` |
| Get transitions | `mcp__atlassian__getTransitionsForJiraIssue` |
| Transition | `mcp__atlassian__transitionJiraIssue` |
| Add comment | `mcp__atlassian__addCommentToJiraIssue` |
| User lookup | `mcp__atlassian__lookupJiraAccountId` |
| List projects | `mcp__atlassian__getVisibleJiraProjects` |

See `references/mcp.md` for full MCP patterns.

---

## Triggers

- "create a jira ticket"
- "show me PROJ-123"
- "list my tickets"
- "move ticket to done"
- "what's in the current sprint"

---

## Issue Key Detection

Issue keys follow the pattern: `[A-Z]+-[0-9]+` (e.g., PROJ-123, ABC-1).

When a user mentions an issue key in conversation:
- **CLI:** `jira issue view KEY` or `jira open KEY`
- **MCP:** `mcp__atlassian__jira_get_issue` with the key

---

## Workflow

**Creating tickets:**
1. Research context if user references code/tickets/PRs
2. Draft ticket content
3. Review with user
4. Create using appropriate backend
5. **Verify formatting** — re-fetch the created content via the REST API and confirm the wiki markup rendered clean (no backslash escapes)

**Updating tickets:**
1. Fetch issue details first
2. Check status (careful with in-progress tickets)
3. Show current vs proposed changes
4. Get approval before updating
5. Add comment explaining changes
6. **Verify formatting** — after posting any comment/description with formatting, re-fetch via REST API and confirm no `\*` `\(` `\-` escapes remain

---

## Before Any Operation

Ask yourself:

1. **What's the current state?** — Always fetch the issue first. Don't assume status, assignee, or fields are what user thinks they are.

2. **Who else is affected?** — Check watchers, linked issues, parent epics. A "simple edit" might notify 10 people.

3. **Is this reversible?** — Transitions may have one-way gates. Some workflows require intermediate states. Description edits have no undo.

4. **Do I have the right identifiers?** — Issue keys, transition IDs, account IDs. Display names don't work for assignment (MCP).

---

## NEVER

- **NEVER transition without fetching current status** — Workflows may require intermediate states. "To Do" → "Done" might fail silently if "In Progress" is required first.

- **NEVER assign using display name (MCP)** — Only account IDs work. Always call `lookupJiraAccountId` first, or assignment silently fails.

- **NEVER edit description without showing original** — Jira has no undo. User must see what they're replacing.

- **NEVER use `--no-input` without all required fields (CLI)** — Fails silently with cryptic errors. Check project's required fields first.

- **NEVER assume transition names are universal** — "Done", "Closed", "Complete" vary by project. Always get available transitions first.

- **NEVER bulk-modify without explicit approval** — Each ticket change notifies watchers. 10 edits = 10 notification storms.

---

## Comment Formatting (CRITICAL — learned the hard way)

Jira comments must use **Jira wiki markup**, NOT Markdown. The `jira` CLI **escapes special characters** when you pass the body via `--template <file>`, `-b "..."`, or here-doc input: it inserts backslashes before `*`, `(`, `)`, `-`, `~`, `[`, `]`, `_`, etc. This **breaks the wiki markup** — bullets become literal `\*`, bold becomes `\*text\*`, code becomes `\{{code\}}`.

### Safe syntax

| Purpose | Jira wiki markup |
|---------|------------------|
| Heading | `h3. Title` (space after `.`) |
| Bold | `*text*` |
| Italic | `_text_` |
| Bullet list | `* item` |
| Numbered list | `# item` (nested: `## item`) |
| Inline code | `{{code}}` |
| Code block | `{code:bash}...{code}` |
| Link | `[label\|url]` |
| Issue link | `[PROJ-123]` |

### The bug: `jira issue comment add` escapes everything

| Command | Result |
|---------|--------|
| `jira issue comment add KEY --template /tmp/body.txt` | ❌ Escapes `* ( ) [ ] - ~` → broken wiki markup |
| `echo "...* bullet..." \| jira issue comment add KEY` | ❌ Same escaping |
| `jira issue comment add KEY -b "*bold*"` | ❌ Same escaping |

### The fix: use the REST API directly for formatted content

The CLI backend's own API calls do **not** escape if you hit the REST endpoint directly. The jira-cli config stores the endpoint and the token is in the env var `JIRA_API_TOKEN` (Bearer works). To **add**:

```bash
# ADD a comment
curl -s -X POST \
   -H "Authorization: Bearer $JIRA_API_TOKEN" \
   -H "Content-Type: application/json" \
   "$JIRA_URL/rest/api/2/issue/PROJ-XXXX/comment" \
   -d "$(jq -n --arg b "$(cat /tmp/body.txt)" '{body: $b}')"
```

To **edit/update** an existing comment (useful when you already posted a broken one):

```bash
# UPDATE comment #12345 on issue PROJ-XXXX
curl -s -X PUT \
   -H "Authorization: Bearer $JIRA_API_TOKEN" \
   -H "Content-Type: application/json" \
   "$JIRA_URL/rest/api/2/issue/PROJ-XXXX/comment/12345" \
   -d "$(jq -n --arg b "$(cat /tmp/body.txt)" '{body: $b}')"
```

For MCP backend, use `mcp__atlassian__addCommentToJiraIssue` — it does not escape.

### Always verify after posting (MANDATORY)

After posting or editing a comment, **re-fetch via the REST API** and check the raw body is clean (no `\*`, `\(`, `\-` backslash escapes):

```bash
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
   "$JIRA_URL/rest/api/2/issue/PROJ-XXXX/comment" | jq '.comments[] | .body'
```

If you see backslash escapes (`\*`, `\(`, `\-`), the comment is broken — re-post via the REST API PUT method above. When you re-read it by API, the escape error becomes visible and you can confirm the fix.

> **Golden rule:** build the body in a `.txt` file with clean Jira wiki markup, then push it via the REST API (Bearer `$JIRA_API_TOKEN`). Avoid the CLI body arguments for anything with formatting. Then verify by re-fetching.

---

## Safety

- Always show the command/tool call before running it
- Always get approval before modifying tickets
- Preserve original information when editing
- Verify updates after applying
- Always surface authentication issues clearly so the user can resolve them

---

## Git & PR Rules

When applying fixes to code repositories:

### Branch Strategy
1. **NEVER push directly to `main`** — always create a feature branch first
2. Branch naming: `{issue-key}-fix-{short-description}` or `{issue-key}-{short-description}`
3. Fetch before branching: `git fetch origin`
4. Start from latest `origin/main`

### Commit Message Convention
Use [Conventional Commits](https://www.conventionalcommits.org/) with Jira ticket prefix:
```
fix(PROJ-XXXX): add secrets: inherit to trivy job

The trivy job calls trivy.yaml which needs vault secrets.
Without secrets: inherit, $VAULT_** were not propagated.
```

Format: `type(scope): description` where scope = Jira ticket
Types: `fix`, `feat`, `chore`, `docs`, `refactor`, `test`

### PR Creation
After committing, ALWAYS create a PR:
```bash
git checkout -b {issue-key}-fix-description origin/main
# make changes and commit
git push origin {issue-key}-fix-description
gh pr create --base main --head {issue-key}-fix-description \
   --title "fix(PROJ-XXXX): description" \
   --body "## Context\n...\n## Fix\n...\n## Related\n- Fixes: PROJ-XXXX"
```

### Before Pushing
1. Verify branch name is different from `main`/`master`
2. Check if branch protection rules exist (may require bypass)
3. If bypass exists, still prefer PR for audit trail
4. Link Jira ticket in PR body with `Fixes: {TICKET_ID}`

### Error Recovery
If already pushed to main by mistake:
1. Reset main: `git reset --hard origin/main~1`
2. Push with force: `git push origin HEAD:main --force-with-lease`
3. Re-create proper branch and PR

## No Backend Available

If neither CLI nor MCP is available, guide the user:

```
To use Jira, you need one of:

1. **jira CLI** (recommended):
   https://github.com/ankitpokhrel/jira-cli

   Install: brew install ankitpokhrel/jira-cli/jira-cli
   Setup:   jira init

2. **Atlassian MCP**:
   Configure in your MCP settings with Atlassian credentials.
```

---

## Deep Dive

**LOAD reference when:**
- Creating issues with complex fields or multi-line content
- Building JQL queries beyond simple filters
- Troubleshooting errors or authentication issues
- Working with transitions, linking, or sprints

**Do NOT load reference for:**
- Simple view/list operations (Quick Reference above is sufficient)
- Basic status checks (`jira issue view KEY`)
- Opening issues in browser

| Task | Load Reference? |
|------|-----------------|
| View single issue | No |
| List my tickets | No |
| Create with description | **Yes** — CLI needs `/tmp` pattern |
| Transition issue | **Yes** — need transition ID workflow |
| JQL search | **Yes** — for complex queries |
| Link issues | **Yes** — MCP limitation, need script |

References:
- CLI patterns: `references/commands.md`
- MCP patterns: `references/mcp.md`

## Git & PR Rules

When applying fixes to code repositories:

### Branch Strategy
1. **NEVER push directly to `main`** — always create a feature branch first
2. Branch naming: `{issue-key}-fix-{short-description}` or `{issue-key}-{short-description}`
3. Fetch before branching: `git fetch origin`
4. Start from latest `origin/main`

### Commit Message Convention
Use [Conventional Commits](https://www.conventionalcommits.org/) with Jira ticket prefix:
```
fix(PROJ-XXXX): add secrets: inherit to trivy job

The trivy job calls trivy.yaml which needs vault secrets.
Without secrets: inherit, $VAULT_** were not propagated.
```

Format: `type(scope): description` where scope = Jira ticket
Types: `fix`, `feat`, `chore`, `docs`, `refactor`, `test`

### PR Creation
After committing, ALWAYS create a PR:
```bash
git checkout -b {issue-key}-fix-description origin/main
# make changes and commit
git push origin {issue-key}-fix-description
gh pr create --base main --head {issue-key}-fix-description \
   --title "fix(PROJ-XXXX): description" \
   --body "## Context\n...\n## Fix\n...\n## Related\n- Fixes: PROJ-XXXX"
```

### Before Pushing
1. Verify branch name is different from `main`/`master`
2. Check if branch protection rules exist (may require bypass)
3. If bypass exists, still prefer PR for audit trail
4. Link Jira ticket in PR body with `Fixes: {TICKET_ID}`

### Error Recovery
If already pushed to main by mistake:
1. Reset main: `git reset --hard origin/main~1`
2. Push with force: `git push origin HEAD:main --force-with-lease`
3. Re-create proper branch and PR
