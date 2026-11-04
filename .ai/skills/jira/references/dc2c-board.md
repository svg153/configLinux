# DC2C board — known context (Jira Cloud)

Verified against the live site. **Do not rediscover** these values; they are here so the Jira
skills work outside the `poc-jira-gh` workspace.

| Item | Value |
| --- | --- |
| Site | `https://bbva-team-dc2c.atlassian.net` |
| `cloudId` | `bfcff78c-dd52-48a6-b0ed-8c95f0ef76d4` |
| Project | `DC2C` (id `10069`, `classic`) |
| Board | `DC2C board`, id `70`, type **kanban** (no sprints) |
| Board filter | id `10069` — `fixVersion in unreleasedVersions() OR fixVersion is EMPTY` |

## Columns ↔ status ids

| Column | Status | Id |
| --- | --- | --- |
| Backlog | Backlog | `10035` |
| Ready | Ready | `10033` |
| In Progress | In Progress | `3` |
| In Review | In Review | `10113` |
| Done | Done | `10034` |

The board config repeats the *Backlog* column once without a status; that is a mapping quirk, not a
read error.

## Hierarchy

```text
Epic → Task | Story → Sub-task
```

Sub-tasks hang from Tasks, **never** from Epics. Aggregating by epic needs two hops
(`Sub-task → Task → Epic`); querying only `parent in (epics)` returns a partial rollup.

## Custom fields

| Field | Id | Notes |
| --- | --- | --- |
| Epic Link | `customfield_10014` | absent on Sub-tasks |
| Start date | `customfield_10015` | populated on 5 issues, 2 predate their own creation |
| Story point estimate | `customfield_10016` | **empty project-wide** |
| Rank | `customfield_10019` | |
| Sprint | `customfield_10020` | **empty** — kanban board |
| [CHART] Time in Status | `customfield_10027` | |

`fixVersion` (milestones M1–M4) is only returned with `view: "full"`; `compact` and `evidence` drop
it, and passing an explicit `fields` list does not help.

## jira-cli recipes

```powershell
# identity and project
jira me
jira project list

# my work
jira issue list -a"$(jira me)" --plain

# everything still open (kanban: no sprints)
jira issue list -q "project = DC2C AND statusCategory != Done" --plain

# raw JQL escape hatch
jira issue list -q "project = DC2C AND duedate is not empty ORDER BY duedate ASC" --plain

# machine-readable
jira issue list -q "project = DC2C" --raw
jira issue list -q "project = DC2C" --csv
```

`jira sprint list` is useless here: the board has no sprints. Use `jira issue list` / `jira epic list`.

## Known pitfalls

1. `jira issue comment add -b "..."` **escapes** `*`, `(`, `)`, `-`, `~`, `[`, `]`, `_`, breaking Jira
   wiki markup. For formatted comments use the Atlassian REST API directly
   (`POST /rest/api/2/issue/KEY/comment`) or the Atlassian MCP, which does not escape.
2. `customfield_*` values are not visible with the MCP default view; ask for `view: "full"` or
   `view: "evidence"`.
3. With the Atlassian MCP, `cloudId` is a **top-level** argument, never inside `inputs`.
4. `jira release list` needs *Releases and Versions* enabled on the site.
