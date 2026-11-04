---
name: generate-jira-weekly-report
description: "Generate a self-contained weekly status report (HTML) for a Jira project, with progress by epic and by milestone, status KPIs, workload per assignee, risks and required weekly pace. Use it to know how a project is progressing against its deadline, or to refresh an existing report from live Jira data. Defaults to the DC2C board of the Jira-GH-Hybrid POC (deadline 2026-12-24)."
argument-hint: "[project key, default DC2C] + [deadline date, default 2026-12-24]"
---

# Generate the weekly report

> **Global installation — read this first.** This skill was authored inside the
> `poc-jira-gh` workspace and is now installed at user level. Two things are therefore
> relative to the **target repository**, not to this skill folder:
>
> | Item | Resolved against | Fallback |
> | --- | --- | --- |
> | Metrics engine `report-model.mjs` | `JIRA_WEEKLY_MODEL` env var | `<repo>/docs/.github/extensions/jira-weekly/report-model.mjs` |
> | Output directory | `<repo>/docs/reporting/` | — create it if missing |
> | Board context (`cloudId`, board id, statuses, epics, custom fields) | `<repo>/AGENTS.md` | read with the Atlassian MCP before generating |
>
> If the target repo has no `docs/.github/extensions/jira-weekly/`, point
> `JIRA_WEEKLY_MODEL` at the extension from any checkout that has it, or skip step *Generating
> the HTML* and produce the report from the metrics engine alone. The **board context below is
> DC2C-specific**: when the user targets another project, rediscover `cloudId`, statuses and
> custom fields instead of reusing these numbers.

Builds a single-file HTML weekly report (inline CSS and SVG, no external resources) from live Jira
data, and leaves it at `docs/reporting/<report-date>-informe-semanal-dc2c.html`.

The board context (site, `cloudId`, board id, statuses, epics, custom fields) is already recorded in
the root `AGENTS.md`, section *POC DC2C — Jira y GitHub*. Read it first; do not rediscover it.

> **`docs/reporting/` is the canonical location.** Reports are versioned there, one file per cut-off
> date, so the history of "how the project looked on date X" is preserved. The older
> `docs/plan/informe-semanal-DC2C.html` was **removed on 2026-10-15** — it predated the
> milestone-aware pipeline and its numbers were not maintained, so it was superseded by this one
> rather than kept alongside it. Do not write new reports there, and do not hand-edit files in
> `docs/reporting/` either: the `jira-weekly` canvas extension can also generate them from a JSON
> payload, and hand-edits are lost on the next export. That extension is versioned in this repo at
> [`.github/extensions/jira-weekly/`](../../extensions/jira-weekly/README.md) — read its README for the
> install steps and the payload schema; prefer driving the canvas (`ingest` → `export_html`) over
> hand-writing the HTML.

## When to use

- The user asks **how the project is going** ("cómo vamos", "informe semanal", "status report").
- The user asks about **progress per epic**, **per milestone** or **against the deadline**.
- The report exists and is stale and the user wants it **regenerated**.

## Golden rules

0. **Generate, do not transcribe.** The report is produced by
   [`tools/fill-report.mjs`](./tools/fill-report.mjs), which expands
   [`references/report-template.html`](./references/report-template.html) against the payload and
   computes **all** geometry (bar widths, gantt x-positions, label de-collision). Never hand-fill
   the template or hand-copy a repeated block: that is the documented root cause of the false-pace
   error and of milestone labels that contradict their own data. See [Generating the HTML](#generating-the-html).
1. **`cloudId` is explicit.** `bfcff78c-dd52-48a6-b0ed-8c95f0ef76d4`. It is a top-level argument of
   every Atlassian MCP call, never inside `inputs`.
2. **Use `view: "full"`** on `searchJiraIssuesUsingJql`. It is the only view that returns `parent`,
   `fixVersions`, `components`, `description` and `resolutiondate`. With the default view or with an
   explicit `fields` list, `parent` is dropped and the epic hierarchy cannot be rebuilt.
3. **Read-only.** This skill never writes to Jira. If the user also wants the report published as a
   Jira comment or a Confluence page, that is a separate, explicitly requested step (see
   `add-comment-jira-cloud` and `createConfluenceContent`).
4. **Counts, not effort.** The board has no story points and no sprints. Every metric is an issue
   count. Never invent velocity or hours.
5. **Due dates exist, but only on a handful of issues.** `duedate` is populated on **7 of 94** DC2C
   issues. Fetch it, report it as a *spotlight* (a dated table with overdue / due-today / due-soon
   states), and always print the denominator — **never** present it as a project calendar or use it
   to compute a global deviation. The inverse mistake is also wrong: do not claim the project has no
   due dates.
6. **Separate seeded closures from real work.** The board was seeded on 2026-10-07 with issues already
   in `Done`. Fetch **both** `created` and `resolutiondate` (full instants, not dates) and classify a
   closure as **seeded** when `resolutiondate - created < 90 min`. Report the split (currently
   **9 seeded of 14**, fastest 24 s, vs **5 worked over 4.0–6.1 days**) and say that seeded closures
   are board progress, not delivered capacity. Never reconstruct the seeding from `resolutiondate`
   alone, and never assert a pre-kickoff closure date without checking `created` — every DC2C issue
   has `created` and `resolutiondate` after 2026-10-01.
7. **Two denominators.** The total (94) includes the 10 epic containers; the work total (84) excludes
   them. State which one each percentage uses. The same applies to component and milestone rollups:
   DC2C numbers differ by 2–5 items depending on the denominator.
8. **Label the snapshot.** Stamp the report with the actual generation date and say that the data is
   a snapshot, not a live view.
9. **Do not publish a pace you cannot support.** If the closures are concentrated in a handful of
   days, say the observed pace is **not estimable** instead of dividing counts by weeks. The required
   pace is always reportable; the observed one is not.

## Procedure

1. **Fix the parameters.** Project (default `DC2C`) and deadline (default `2026-12-24`). If the user
   gives a different deadline, use theirs and say so in the report.
2. **Fetch the issues** in one call, paging until `isLast` is true:
   ```jql
   project = DC2C ORDER BY key ASC
   ```
   `maxResults: 100`, `view: "full"`. With ~94 issues the response is ~280 KB and gets written to a
   temp file — **parse that file**, do not re-issue the query. Keep `duedate`, `created`,
   `resolutiondate`, `components` and `customFields["Start date"]` in the payload; the sections
   below depend on them. Note that with an explicit `fields` list plus `view: "full"` the shape
   changes: `status` becomes nested and custom fields move under `fields.customFields` keyed by
   **display name**. `duedate`, `created`, `resolutiondate` and `components` stay top-level.
   **Parse with Node, not PowerShell** — `ConvertFrom-Json` converts ISO strings to `[datetime]` and
   rewrites them in the machine's locale, which destroys the instants the seeding check needs.
3. **Fetch the milestones** with `executeRead` / `getJiraProjectVersions` (`projectIdOrKey: "DC2C"`,
   `orderBy: "sequence"`). Milestones carry the real release dates and are the backbone of the
   timeline section.
4. **Resolve the epic of every issue.** Direct `customFields["Epic Link"].value` first; otherwise
   walk `fields.parent` up to the task that carries the Epic Link. Sub-tasks never carry it
   themselves. Verify that every non-Epic issue resolves; an unresolved issue means the join is
   wrong, not that the issue is orphaned.
5. **Compute the metrics** exactly as defined in [`references/metrics.md`](./references/metrics.md).
6. **Render the HTML** with the generator (see [Generating the HTML](#generating-the-html)). Keep it
   self-contained: inline `<style>` and inline `<svg>`, no CDN, no fonts, no scripts. It must open
   correctly from the filesystem with no network.
7. **Write** to `docs/reporting/<report-date>-informe-semanal-dc2c.html`, where `<report-date>` is the
   ISO cut-off date. **Never overwrite an existing report**: each file is evidence of how the project
   looked on a specific date, and rewriting it destroys that evidence. Re-running on the same day
   overwrites that day's file, which is fine.
8. **Verify**: the file contains no `http` reference other than Jira links; the KPI totals match the
   fetched data; open it in the browser canvas and confirm it renders.

## Report sections

Select the sections that carry information; do not pad.

| Section | Content |
| --- | --- |
| Header | POC name, generation date, deadline, days and weeks remaining |
| KPIs | Total, Done, **in flight (In Progress + In Review)**, Ready, Backlog, % done on **both** denominators, items with a due date, required vs observed pace |
| Progress | Global bar + breakdown by status |
| By epic | Epic, status, children, done, %, progress bar, milestone |
| By milestone | Milestone, release date, issues, done, %, flag if it lands after the deadline |
| **Due dates** | The dated subset only: key, due date, status, assignee, state (overdue / due today / due soon / closed late / on time). Print the denominator ("N of 84") |
| **By component** | Component, issues, done, %, stacked bar. State which denominator the totals use |
| Risks | Zero-progress epics, unassigned volume, milestone/deadline mismatch, overdue dates, closure concentration, seeded closures, known blockers |
| Workload | Assignee, assigned, done, open |
| Timeline | Milestones against the deadline, with a month gridline and a "today" marker, plus the required weekly pace |
| **What's left** | A **data-derived** list of actions: cut or pull forward late scope, start the blocked milestone, assign unowned work, attend immediate due dates, decide on epics with no closures |
| Methodology | JQL used, snapshot date, and the "counts not effort" limitation |

> ⚠️ **Repeat blocks are loops, not copies.** The template uses real block syntax
> (`<!-- #each ruta --> … <!-- /each -->`, `<!-- #if ruta -->`, `<!-- #unless ruta -->`) and
> placeholders (`{{ruta}}` escaped, `{{{ruta}}}` raw). The generator emits one block per item and
> computes its geometry. **Never** duplicate a block by hand and recalculate its coordinates — that
> is how a report ends up with a milestone label that contradicts the data.

## Generating the HTML

`tools/fill-report.mjs` expands the template against a payload. It imports `report-model.mjs` from
the extension, so **both pipelines share one metrics engine** and the report can no longer disagree
with the canvas export.

```bash
cd docs/.github/skills/generate-jira-weekly-report

# payload y salida explícitos
node tools/fill-report.mjs \
  "../../extensions/jira-weekly/examples/payload-dc2c.json" \
  "../../../reporting/2026-10-15-informe-semanal-dc2c.html"

# o con los valores por defecto (payload de ejemplo → stdout)
node tools/fill-report.mjs
```

| Argumento | Por defecto |
| --- | --- |
| `[payload]` | `docs/.github/extensions/jira-weekly/examples/payload-dc2c.json` |
| `[out]` | `stdout` |
| `--allow-missing` | falla (exit 1) si queda alguna ruta sin resolver |

Reglas que aplica el generador y conviene no romper:

- **Sale con código 1** si alguna ruta de la plantilla no tiene valor, y lista las que faltan. Un
  informe con `{{…}}` a la vista es un informe roto, no un informe «casi listo».
- **Normaliza el separador decimal a coma** (`86,3 %`, no `86.3 %`) en los textos que vienen del
  modelo, para que el informe sea coherente consigo mismo. El modelo ya formatea su prosa con
  `esNum()`, así que hoy es una red de seguridad idempotente más que un arreglo: se mantiene porque
  protege contra un campo de prosa nuevo que olvide el formateador.
- **No genera recursos externos.** El resultado no lleva `<script>` ni `src=` remotos.
- **El motor de plantillas escanea el fichero crudo, comentarios incluidos.** Por eso la
  documentación de la sintaxis que va en la cabecera de `report-template.html` está escrita con
  **entidades HTML** (`&#123;&#123;ruta&#125;&#125;`, `<!&#45;&#45; #each ruta &#45;&#45;>`). Si
  escribes un `{{` o un `<!--` literal en un comentario, el parser lo trata como sintaxis real y la
  ejecución falla con rutas fantasma (`@first`, `this`, `ruta`).

## Success criteria

The report is done when **all** of these hold:

- It exists at `docs/reporting/<report-date>-informe-semanal-dc2c.html` and no earlier report was
  modified or deleted.
- The KPI totals reconcile with a direct status count from the same JQL (94 / 14 / 80 open for the
  2026-10-15 snapshot, on the 84-item work denominator where the report says so).
- The "By milestone" section lists all four milestones M1–M4 and flags M3 and M4 as landing after
  the deadline.
- The due-date section lists exactly the 7 dated issues and states that only 7 of 84 work items are
  dated.
- The seeded/worked split is present and consistent with `created` vs `resolutiondate`
  (9 seeded / 5 worked for the 2026-10-15 snapshot).
- The observed pace is either backed by a closure window of ≥ 21 days or explicitly labelled
  **not estimable**.
- The "What's left" list is derived from the data, not hand-written.
- The file renders offline: no `<script>`, no external `src=`, and the only `http` references are
  Jira links.
- It was produced by `node tools/fill-report.mjs` and the run exited **0** with no unresolved
  paths — no `{{…}}` left anywhere in the output.

## Common errors

| Symptom | Cause | Fix |
| --- | --- | --- |
| Every issue looks orphaned | `parent`/`fixVersions` missing | Re-query with `view: "full"` |
| Sub-tasks counted as separate work | Epic resolved only from the direct Epic Link | Walk the `parent` chain |
| `%` done disagrees with Jira | Epics counted in the denominator | Report both totals; the per-epic rollup excludes the epic itself |
| Milestones appear missing | Read from the issue fields only | Call `getJiraProjectVersions` |
| "The project has no due dates" | Checked `duedate` on the wrong query, or on the default view | 7 DC2C issues carry `duedate`; re-check with `project = DC2C AND duedate is not empty` |
| A milestone label contradicts its own data | A repeat block was duplicated and its geometry hand-recalculated | Loop over the data; never hand-copy a repeated block |
| "N issues were already Done before kickoff" | `resolutiondate` read without `created` | Compare `created` with `resolutiondate`; in DC2C both are after 2026-10-01 |
| Seeding cannot be classified | Instants truncated to `YYYY-MM-DD`, or parsed through a locale | Keep the full ISO instants and parse them with Node |
| Dates fail to parse | Locale-dependent strings | Parse with `InvariantCulture` |
| Report needs a network to render | A CDN or webfont slipped in | Inline everything |
| `Bloques cruzados: se abrió #each y se cerró /each` | The template's block tags are unbalanced | Balance them; the generator names the offending tag |
| `N ruta(s) de la plantilla no tienen valor: @first, @index, this…` | A literal `{{…}}` or `<!-- #each … -->` sits in a **comment** (usually the header doc comment) | Escape it as an HTML entity: `&#123;&#123;…&#125;&#125;`, `<!&#45;&#45; #each … &#45;&#45;>` |
| `{{…}}` visible in the rendered report | A template path has no value and the run was forced with `--allow-missing` | Fix the payload or the view model; do not ship a report with unresolved placeholders |
| `Cannot find module …/report-model.mjs` | `JIRA_WEEKLY_MODEL` points nowhere, or the extension moved | Point `JIRA_WEEKLY_MODEL` at `docs/.github/extensions/jira-weekly/report-model.mjs` |
| Decimals render as `86.3 %` next to `78,6 %` | Model prose interpolates a raw `Number` — a prose field added without `esNum()` | `report-model.mjs` formats its prose with `esNum()`; the generator's `esDecimals()` is the idempotent safety net. Route new prose through either |

## References

- [`references/metrics.md`](./references/metrics.md) — metric definitions, JQL, status mapping and
  the epic-resolution algorithm.
- [`references/report-template.html`](./references/report-template.html) — self-contained scaffold
  with the layout, styles and SVG chart patterns, plus the block-syntax reference in its header.
- [`tools/fill-report.mjs`](./tools/fill-report.mjs) — the generator that expands the template and
  computes every coordinate. Imports `report-model.mjs`, so the report and the canvas export can
  never diverge.
- [`../../extensions/jira-weekly/README.md`](../../extensions/jira-weekly/README.md) — install the
  canvas, and the JSON payload schema the generator consumes.
- Root `AGENTS.md`, section *POC DC2C — Jira y GitHub* — site, board, epics, custom fields, board URL.
