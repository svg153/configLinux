# Jira REST API — Safe Comment/Description Submission

This reference explains the **only safe path** for submitting Jira content that
contains wiki markup. It exists because the `jira` CLI escapes special
characters, silently breaking formatting.

## The Problem: CLI escaping

The `jira issue comment add` CLI escapes the body when passed via `--template
<file>`, `-b`, or stdin. What you write gets transformed silently:

| You write | CLI stores | Renders as |
| :-- | :-- | :-- |
| `* bullet` | `\* bullet` | literal `\* bullet` |
| `*bold*` | `\*bold\*` | literal `\*bold\*` |
| `{{code}}` | `\{{code\}}` | literal `\{{code\}}` |
| `[~user]` | `\[~user\]` | literal `\[~user\]` |

**This is the #1 cause of "validator passed but Jira is broken".**

## Safe path (REST API, no escaping)

1. Write the body in a `.txt` file using clean Jira wiki markup.
2. Submit via the REST API (Bearer token from `$JIRA_API_TOKEN`):

```bash
curl -s -X POST \
  -H "Authorization: Bearer $JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://YOUR-JIRA-INSTANCE/rest/api/2/issue/PROJ-XXXX/comment" \
  -d "$(jq -n --arg b "$(cat /tmp/body.txt)" '{body: $b}')"
```

Finally, **always verify after posting** — re-fetch and scan for residual
backslash escapes:

```bash
curl -s -X GET \
  -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://YOUR-JIRA-INSTANCE/rest/api/2/issue/PROJ-XXXX/comment/<id>" \
  | grep -Po '\\[*_\-\[\]()~|{}]' || echo "NO ESCAPES ✓"
```

## Creating an issue with raw wiki markup (description)

```bash
BODY="$(cat /tmp/body.txt)"
curl -s -X POST \
  -H "Authorization: Bearer $JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://YOUR-JIRA-INSTANCE/rest/api/2/issue" \
  -d "$(jq -n --arg s "Summary here" --arg b "$BODY" '{
    fields: {
      project: { key: "PROJ" },
      summary: $s,
      description: $b,
      issuetype: { name: "Task" },
      labels: ["team-squad"],
      reporter: { name: "username" }
    }
  }')"
```

## Useful endpoints

| Action | Method + URL |
| :-- | :-- |
| Create comment | `POST /rest/api/2/issue/{key}/comment` |
| Update comment | `PUT /rest/api/2/issue/{key}/comment/{id}` |
| Get comment | `GET /rest/api/2/issue/{key}/comment/{id}` |
| List comments | `GET /rest/api/2/issue/{key}/comment?maxResults=N` |
| Create issue | `POST /rest/api/2/issue` |
| Get transitions | `GET /rest/api/2/issue/{key}/transitions` |
| Do transition | `POST /rest/api/2/issue/{key}/transitions` |

## Verification checklist (before "done")

- [ ] Submit via REST API, not `jira` CLI (unless MCP backend).
- [ ] Re-fetch the comment and grep for `\*`, `\[`, `\{{` — must be NONE.
- [ ] Bullets start with `*`, bold is `*...*`, code is `{{...}}`.
- [ ] No stray `**` (Markdown bold) or `[text](url)` (Markdown link).
