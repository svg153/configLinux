# Metrics, JQL and rollup rules

Reference for the `generate-jira-weekly-report` skill. Everything here is derived from data that
Jira actually holds for DC2C. Nothing is estimated.

## 1. Source queries

```jql
-- Whole project, the single call the report is built from
project = DC2C ORDER BY key ASC

-- Pending work only
project = DC2C AND statusCategory != Done

-- My tasks
assignee = currentUser()

-- One milestone
project = DC2C AND fixVersion = "M1 - Foundation"
```

Call: `searchJiraIssuesUsingJql` with `cloudId`, `maxResults: 100`, `view: "full"`.

`view: "full"` is mandatory. The default and `evidence` views return a normalised subset that drops
`parent`, `fixVersions`, `components`, `description` and `resolutiondate`.

Milestones: `executeRead` → `getJiraProjectVersions`, `{ projectIdOrKey: "DC2C", orderBy: "sequence" }`.

## 2. Status → board column

| Board column | Status | statusId |
| --- | --- | --- |
| Backlog | Backlog | `10035` |
| Ready | Ready | `10033` |
| In Progress | In Progress | `3` |
| In Review | In Review | `10113` |
| Done | Done | `10034` |

Reported groupings:

- **Done** = `Done`.
- **En curso** (in flight) = `In Progress` + `In Review`. Both occupy a WIP column.
- **Ready** = `Ready` (groomed, not started).
- **Backlog** = `Backlog` (not groomed).

`% completado = Done / Total`.

## 3. Epic resolution

Sub-tasks in DC2C do **not** carry an Epic Link. Resolve in this order:

1. `fields.customFields["Epic Link"].value` — present on Epics' children (Tasks, Stories).
2. `fields.parent.key` → that issue's Epic Link.
3. If the parent has no Epic Link either, go one more level up.

An issue that still has no epic after step 3 means the join is broken, not that the issue is
orphaned. Stop and check before publishing.

Two totals are valid and they answer different questions:

- **Project total** — every issue, Epics included (94 in the 2026-10-15 snapshot).
- **Work total** — every non-Epic issue (84). Use this one for "% done" of deliverable work; an Epic
  is a container, and counting it inflates the denominator with something that is never "done" on
  its own.

Always state which total a percentage refers to.

## 4. Metrics

| Metric | Definition |
| --- | --- |
| Total | Issues in the query |
| Done / In flight / Ready / Backlog | Count per status group (§2) |
| % completado | `Done / Total` |
| Per-epic children | Non-Epic issues whose resolved epic is that Epic |
| Per-epic % | `Done children / children` |
| Per-milestone set | Issues whose `fixVersions` contains that milestone |
| Unassigned | `assignee` empty. Volume risk, not a per-person load |
| Weeks remaining | `(deadline - today).Days / 7`, one decimal |
| Required pace | `open issues / weeks remaining` |
| Observed pace | Done issues divided by the weeks of actual activity |

**Observed pace caveat.** DC2C was created on 2026-10-07 and **every** issue has `created` and
`resolutiondate` after 2026-10-01 — there is nothing resolved before kickoff, so the pace window starts
at the project creation date.

**Do not treat all 14 Done issues as delivered capacity.** The board was seeded on 2026-10-07 with
issues already in `Done`, so `resolutiondate` alone overstates the pace. Classify each closure by the
`created` → `resolutiondate` delta:

| Class | Rule | DC2C 2026-10-15 |
| --- | --- | --- |
| Seeded | delta < **90 min** | **9** of 14 (8 on 07-10; fastest DC2C-93 in **24 s**) |
| Worked | delta ≥ 90 min | **5** (DC2C-12, 88, 89, 90, 91), **4.0 – 6.1 days** each |

Report the split and say that seeded closures are board progress, not capacity. Fetch **both** fields
as full ISO instants: with only `YYYY-MM-DD` the check collapses and the correct output is "not
measurable", not a guess.

## 4b. Due dates

`duedate` is populated on **7 of 94** DC2C issues (7 %), all in October 2026 — a spotlight on specific
work, **not** a project calendar. Fetch it, tabulate the dated subset with an explicit state
(overdue / due today / due soon / closed late / closed on time), and **always print the denominator**.
Never derive a global schedule deviation from 7 dated issues; never claim the project has no due dates.

| Issue | Due | Status | State |
| --- | --- | --- | --- |
| DC2C-12 | 2026-10-09 | Done | closed late (4 d) |
| DC2C-18 | 2026-10-12 | In Review | **overdue** |
| DC2C-24 | 2026-10-12 | Done | on time |
| DC2C-93 | 2026-10-13 | Done | on time |
| DC2C-92 | 2026-10-15 | In Progress | **due today** |
| DC2C-15 | 2026-10-16 | In Review | due soon |
| DC2C-23 | 2026-10-16 | In Progress | due soon |

`customfield_10015` (Start date) is set on 5 issues; on DC2C-12 and DC2C-18 it **predates their own
`created`** — evidence of backdated seeding.

## 4c. Two denominators

| Denominator | DC2C value | Use |
| --- | --- | --- |
| Total | **94** | Anything the user compares against a Jira issue count |
| Work (non-Epic) | **84** | Progress, components, due dates, milestones |

The 10 epic containers are not work. State which denominator each figure uses — the same rollup differs
by 2–5 items depending on the choice (e.g. GitHub is 24 of 94 but 22 of 84).

## 5. Risks worth computing

- **Zero-progress epics** — epics with children and 0 Done. Any epic still in `Backlog` is a
  planning risk on its own.
- **Milestone after the deadline** — a milestone whose `releaseDate` is later than the deadline.
  In DC2C this is the headline finding: M3 (2026-12-31) and M4 (2027-03-31) both land after
  2026-12-24, so the Jira plan and the POC deadline disagree. Surface it; do not silently re-plan.
- **Unassigned volume** — 69 of 80 open issues were unassigned at the snapshot (86.3 %). Ownerless
  work has no throughput.
- **Concentration** — one person (NICHOLAS AYALA) holds 11 of the 14 Done items (**78.6 %**), so the
  pace is not a team pace.
- **Overdue dates** — a dated, non-Done issue whose `duedate` is in the past. DC2C-18 on the
  2026-10-15 snapshot.
- **Seeded closures** — a closure under 90 min after creation (see §4). If most closures are seeded,
  the observed pace is not a capacity measurement.
- **Missing estimation** — no story points and no sprints. The board cannot express effort or forecast
  by velocity; only counts are defensible. **Due dates are the exception**: they exist, on 7 issues,
  and belong in their own section rather than being declared absent.
- **Known blockers** — read `docs/plan/roadmap.md` (expired `SYNC_FILES_PAT`, missing repo variables
  `PROJECT_NUMBER` / `GH_HOST` / `ISSUE_STATUS_FIELD_ID` / `DEPLOYMENT_STATUS_FIELD_ID`, the leaked
  PAT that must be rotated, and Fase B as the critical path).

## 6. Custom fields

| Field | ID | Notes |
| --- | --- | --- |
| Epic Link | `customfield_10014` | Empty on sub-tasks |
| Start date | `customfield_10015` | Set on very few issues |
| Story point estimate | `customfield_10016` | Empty project-wide — do not use |
| Rank | `customfield_10019` | Board ordering |
| Sprint | `customfield_10020` | Empty project-wide — Kanban board, no sprints |

## 7. Parsing notes (Windows / PowerShell)

- Large MCP responses are written to a temp file. `Get-Content -Raw | ConvertFrom-Json` on that file
  instead of repeating the call.
- Date strings come back locale-formatted. Parse with
  `[datetime]::Parse($s, [cultureinfo]::InvariantCulture)`; plain `[datetime]$s` throws.
- `&&` only chains native commands in PowerShell; use `;` before a keyword.
