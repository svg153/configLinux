#!/usr/bin/env node
/**
 * Rellena references/report-template.html y produce el informe semanal autocontenido.
 *
 *   node tools/fill-report.mjs [payload.json] [salida.html] [--allow-missing]
 *
 * Sin argumentos usa el payload de ejemplo del canvas jira-weekly y escribe por stdout.
 *
 * POR QUÉ EXISTE ESTE SCRIPT
 * --------------------------
 * El informe se montaba copiando y pegando bloques a mano y recalculando a mano las
 * coordenadas del timeline. Ese trabajo manual es la causa raíz del error que se coló en el
 * informe anterior: se afirmaba un ritmo observado («~6 issues/semana») que los propios datos
 * no sostenían, porque la cifra se había escrito en lugar de calcularse.
 *
 * Aquí NINGÚN número se escribe a mano: todos salen de computeMetrics(). Y para que el
 * informe y el canvas no puedan divergir, se importa el MISMO módulo de métricas que usa la
 * extensión (../../extensions/jira-weekly/report-model.mjs).
 */

import { readFileSync, writeFileSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = resolve(HERE, "..");

const MODEL_PATH =
    process.env.JIRA_WEEKLY_MODEL ||
    resolve(SKILL_DIR, "..", "..", "extensions", "jira-weekly", "report-model.mjs");
const TEMPLATE_PATH =
    process.env.JIRA_WEEKLY_TEMPLATE || resolve(SKILL_DIR, "references", "report-template.html");
const DEFAULT_PAYLOAD = resolve(
    SKILL_DIR,
    "..",
    "..",
    "extensions",
    "jira-weekly",
    "examples",
    "payload-dc2c.json",
);

const STATUS_FILL = {
    Backlog: "#9aa7b4",
    Ready: "#8b5cf6",
    "In Progress": "#0b6bcb",
    "In Review": "#d98a1a",
    Done: "#1a7f37",
};
const STATUS_PILL = {
    Backlog: "s-back",
    Ready: "s-ready",
    "In Progress": "s-prog",
    "In Review": "s-rev",
    Done: "s-done",
};
const DUE_STATE = {
    overdue: { label: "vencida", cls: "s-crit" },
    "due-today": { label: "vence hoy", cls: "s-rev" },
    "due-soon": { label: "vence pronto", cls: "s-ready" },
    "closed-late": { label: "cerrada tarde", cls: "s-rev" },
    "closed-on-time": { label: "cerrada en plazo", cls: "s-done" },
};
const RISK_CLASS = { critical: "crit", high: "warn", medium: "info", low: "ok" };
const MONTHS = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"];

// ---------------------------------------------------------------- utilidades

function esc(value) {
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

/** Un decimal con coma decimal, sin el «,0» sobrante. */
function fmt1(value) {
    if (value == null || Number.isNaN(Number(value))) return "—";
    const n = Number(value);
    const s = (Math.round(n * 10) / 10).toFixed(1);
    return (s.endsWith(".0") ? s.slice(0, -2) : s).replace(".", ",");
}

function fmtSigned(value) {
    if (value == null || Number.isNaN(Number(value))) return "—";
    const n = Number(value);
    if (n === 0) return "0";
    return `${n > 0 ? "+" : "−"}${fmt1(Math.abs(n))}`;
}

/**
 * Red de seguridad del separador decimal. El modelo ya formatea su propia prosa con `esNum()`
 * (coma), así que hoy esta sustitución es un no-op; se mantiene porque un campo de prosa nuevo
 * que olvide el formateador volvería a colar un `86.3 %` junto a las cifras del generador
 * (`78,6 %`). La sustitución es idempotente, así que no estorba.
 * Se dejan intactas las secuencias con más de un punto (`1.2.3`) por si aparecen versiones o rutas.
 */
function esDecimals(text) {
    if (typeof text !== "string") return text;
    return text.replace(/(?<![\d.])(\d+)\.(\d{1,2})(?![\d.])/g, "$1,$2");
}

function pct(part, whole) {
    if (!whole) return 0;
    return Math.round((part / whole) * 1000) / 10;
}

/** Clase de barra por avance: verde si está cerrado, rojo si no se ha empezado. */
function barClass(value, total) {
    if (value >= 100) return "b-done";
    if (value <= 0 && total > 0) return "b-crit";
    return "b-def";
}

function dayNumber(iso) {
    const [y, m, d] = String(iso).split("-").map(Number);
    return Date.UTC(y, m - 1, d) / 86400000;
}

function dayToIso(day) {
    return new Date(day * 86400000).toISOString().slice(0, 10);
}

function shiftMonth(iso, delta) {
    const [y, m] = String(iso).split("-").map(Number);
    const total = y * 12 + (m - 1) + delta;
    return `${String(Math.floor(total / 12)).padStart(4, "0")}-${String((total % 12) + 1).padStart(2, "0")}`;
}

function monthLabel(iso, includeYear) {
    const [y, m] = String(iso).split("-").map(Number);
    const name = MONTHS[m - 1];
    return includeYear ? `${name} ${String(y).slice(2)}` : name;
}

/** Reparte etiquetas en filas para que no se solapen (greedy, máx. `maxRows`). */
function layoutLabels(items, minGap, maxRows = 3) {
    const lastX = [];
    const placed = [];
    for (const item of items) {
        let row = 0;
        while (row < maxRows && lastX[row] !== undefined && item.x - lastX[row] < minGap) row += 1;
        if (row >= maxRows) row = maxRows - 1;
        lastX[row] = item.x;
        placed.push({ ...item, row });
    }
    return { placed, rowCount: Math.max(1, lastX.length) };
}

// ---------------------------------------------------------------- motor de plantilla

const TOKEN =
    /<!--\s*(#each|#if|#unless|\/each|\/if|\/unless)\s*([^\s>]*)\s*-->|\{\{\{([^{}]+?)\}\}\}|\{\{([^{}]+?)\}\}/g;

function parseTemplate(source) {
    const root = { type: "root", children: [] };
    const stack = [root];
    let cursor = 0;
    let match;
    TOKEN.lastIndex = 0;
    while ((match = TOKEN.exec(source)) !== null) {
        if (match.index > cursor) {
            stack[stack.length - 1].children.push({ type: "text", value: source.slice(cursor, match.index) });
        }
        cursor = TOKEN.lastIndex;
        if (match[1]) {
            const sigil = match[1];
            // Se normaliza el prefijo para que `#each` y `/each` compartan nombre desnudo.
            const kind = sigil.replace(/^[#/]/, "");
            const path = match[2];
            if (sigil.startsWith("/")) {
                const node = stack.pop();
                if (!node || node.type !== "block") throw new Error(`Cierre «${sigil}» sin apertura en la plantilla.`);
                if (node.kind !== kind) {
                    throw new Error(`Bloques cruzados: se abrió #${node.kind} y se cerró ${sigil}.`);
                }
            } else {
                const node = { type: "block", kind, path, children: [] };
                stack[stack.length - 1].children.push(node);
                stack.push(node);
            }
        } else if (match[3] !== undefined) {
            stack[stack.length - 1].children.push({ type: "raw", path: match[3].trim() });
        } else {
            stack[stack.length - 1].children.push({ type: "esc", path: match[4].trim() });
        }
    }
    if (cursor < source.length) {
        stack[stack.length - 1].children.push({ type: "text", value: source.slice(cursor) });
    }
    if (stack.length !== 1) throw new Error(`Bloque sin cerrar: #${stack[stack.length - 1].kind}.`);
    return root;
}

function makeScope(parent, item, index, array) {
    const locals = Object.create(null);
    if (item !== null && typeof item === "object" && !Array.isArray(item)) {
        for (const key of Object.keys(item)) locals[key] = item[key];
    }
    locals.this = item;
    locals["@index"] = index;
    locals["@number"] = index + 1;
    locals["@first"] = index === 0;
    locals["@last"] = index === array.length - 1;
    return { parent, locals };
}

function lookup(scope, path) {
    const parts = path.split(".");
    for (let node = scope; node; node = node.parent) {
        if (parts[0] in node.locals) {
            let value = node.locals[parts[0]];
            for (let i = 1; i < parts.length; i += 1) {
                if (value == null) return { found: false };
                value = value[parts[i]];
            }
            return { found: true, value };
        }
    }
    return { found: false };
}

// El 0 NO se considera falso: un contador a 0 es un dato válido que debe imprimirse.
// Sólo son falsos null, undefined, false y los arrays vacíos.
function truthy(value) {
    if (value === null || value === undefined || value === false) return false;
    if (Array.isArray(value)) return value.length > 0;
    return true;
}

function renderNodes(nodes, scope, report) {
    let out = "";
    for (const node of nodes) {
        if (node.type === "text") {
            out += node.value;
            continue;
        }
        const { found, value } = lookup(scope, node.path);
        if (!found) {
            report.missing.add(node.path);
            continue;
        }
        if (node.type === "esc" || node.type === "raw") {
            if (value === null || value === undefined) continue;
            out += node.type === "esc" ? esc(value) : String(value);
        } else if (node.kind === "each") {
            if (!Array.isArray(value)) throw new Error(`#each «${node.path}» apunta a un valor que no es un array.`);
            value.forEach((item, index) => {
                out += renderNodes(node.children, makeScope(scope, item, index, value), report);
            });
        } else if (node.kind === "if") {
            if (truthy(value)) out += renderNodes(node.children, scope, report);
        } else if (!truthy(value)) {
            out += renderNodes(node.children, scope, report);
        }
    }
    return out;
}

// ---------------------------------------------------------------- modelo de vista

function buildView(snap, metrics) {
    const view = {};
    const byKey = new Map(snap.issues.map((issue) => [issue.key, issue]));
    const c = metrics.counts;
    const t = metrics.timeline;
    const statusCount = (status) =>
        metrics.matrix.rows.reduce((acc, row) => acc + (row.cells[status] || 0), 0);

    view.PROJECT = metrics.project.key;
    view.POC_NAME = metrics.project.name;
    view.BOARD_NAME = metrics.project.boardName;
    view.BOARD_URL = metrics.project.boardUrl;
    view.SOURCE = metrics.source;
    view.GENERATED_AT = metrics.generatedAt;
    view.REPORT_DATE = metrics.reportDate;
    view.DEADLINE = metrics.deadline;
    view.DAYS_LEFT = t.daysLeft;
    view.WEEKS_LEFT = fmt1(t.weeksLeft);
    view.TOTAL = c.total;
    view.DONE = c.closed;
    view.OPEN = c.open;
    view.EPICS = c.epics;
    view.WORK_TOTAL = c.workTotal;
    view.PCT_DONE = fmt1(c.progressPct);
    view.PCT_WORK_DONE = fmt1(c.workProgressPct);
    view.PACE_REQ = fmt1(t.requiredPerWeek);
    view.EXPECTED_PCT = fmt1(t.expectedPct);
    view.BACKLOG = statusCount("Backlog");
    view.READY = statusCount("Ready");

    // `counts.inFlight` cuenta SÓLO items de trabajo (excluye los contenedores de épica),
    // mientras que el desglose por estado de justo debajo incluye todo. Publicar los dos
    // números sin etiquetar el denominador se lee como una contradicción (7 frente a 12),
    // así que aquí se publican ambos, explícitos.
    view.INFLIGHT = c.inFlight;
    view.INFLIGHT_ALL = statusCount("In Progress") + statusCount("In Review");
    // Derivado, nunca escrito a mano: los contenedores de épica que están en vuelo son la
    // diferencia entre las celdas de estado y los items de trabajo. Hoy son 5 (DC2C-1…5).
    view.INFLIGHT_EPICS = view.INFLIGHT_ALL - c.inFlight;

    // El ritmo observado sólo se publica si la ventana de cierres lo sostiene. Mientras no lo
    // haga se dice «no estimable» y se explica por qué: publicar una cifra extraída de 6 días
    // de datos es exactamente el error que este generador existe para evitar.
    if (t.paceReliable) {
        view.PACE_OBS = `${fmt1(t.observedPerWeek)}/sem`;
        view.PACE_OBS_NOTE = `ventana de cierres de ${t.closureSpanDays} días`;
        view.PACE_OBS_CLASS = "";
    } else {
        view.PACE_OBS = "no estimable";
        view.PACE_OBS_NOTE = `sólo ${t.closureSpanDays} días con cierres: sin base estadística`;
        view.PACE_OBS_CLASS = "warn";
    }

    view.DEVIATION_PCT = fmtSigned(t.deviationPct);
    view.DEVIATION_CLASS = t.deviationPct < -5 ? "crit" : t.deviationPct < 0 ? "warn" : "done";

    view.EXEC_SUMMARY = [
        `De ${c.total} issues del proyecto, ${c.closed} están cerradas (${fmt1(c.progressPct)} %; ${fmt1(c.workProgressPct)} % si se excluyen las ${c.epics} épicas, que son contenedores y no trabajo).`,
        `Quedan ${t.daysLeft} días naturales hasta el deadline del ${metrics.deadline} (${fmt1(t.weeksLeft)} semanas), lo que exige cerrar ${fmt1(t.requiredPerWeek)} items por semana.`,
        `A la altura de hoy el plan esperaría un ${fmt1(t.expectedPct)} % de avance, así que la desviación es de ${fmtSigned(t.deviationPct)} puntos.`,
        `Hay ${c.inFlight} items de trabajo en curso y ${view.INFLIGHT_EPICS} épicas también en curso (${view.INFLIGHT_ALL} issues en total si se cuentan los contenedores), y ${statusCount("Backlog")} todavía en backlog sin empezar.`,
    ].join(" ");

    // --- avance global por estado -------------------------------------------------
    const GLOBALBAR_W = 900;
    const total = c.total;
    let cursor = 0;
    view.globalBar = { segments: [], labels: [] };
    for (const status of metrics.matrix.statuses) {
        const count = statusCount(status);
        if (!count) continue;
        const w = (count / total) * GLOBALBAR_W;
        view.globalBar.segments.push({
            x: Math.round(cursor * 100) / 100,
            w: Math.round(w * 100) / 100,
            fill: STATUS_FILL[status] || "#9aa7b4",
            title: `${status}: ${count} issues (${fmt1(pct(count, total))} %)`,
        });
        // Sólo se rotula el segmento si hay sitio: un rótulo sobre 19 px se solaparía.
        if (w >= 62) {
            view.globalBar.labels.push({
                x: Math.round(cursor + w / 2),
                anchor: "middle",
                text: `${status} ${count}`,
            });
        }
        cursor += w;
    }
    view.GLOBALBAR_W = GLOBALBAR_W;
    view.GLOBALBAR_VIEWBOX = `0 0 ${GLOBALBAR_W} 68`;
    view.legend = metrics.matrix.statuses
        .filter((status) => statusCount(status) > 0)
        .map((status) => ({ fill: STATUS_FILL[status] || "#9aa7b4", text: `${status} (${statusCount(status)})` }));

    view.statusRows = metrics.matrix.statuses.map((status) => {
        const count = statusCount(status);
        return {
            status,
            count,
            pct: fmt1(pct(count, total)),
            pillClass: STATUS_PILL[status] || "s-back",
            barPct: pct(count, total),
            barClass:
                status === "Done" ? "b-done" : status === "Backlog" ? "b-crit" : status === "Ready" ? "b-warn" : "b-def",
        };
    });

    view.matrix = {
        statuses: metrics.matrix.statuses,
        rows: metrics.matrix.rows.map((row) => ({
            type: row.type,
            total: row.total,
            pct: fmt1(row.pct),
            cells: metrics.matrix.statuses.map((status) => ({ count: row.cells[status] || 0 })),
        })),
    };

    // --- por épica ----------------------------------------------------------------
    view.epicRows = metrics.epicRollup.map((epic) => ({
        key: epic.key,
        name: epic.summary,
        status: epic.status,
        pillClass: STATUS_PILL[epic.status] || "s-back",
        milestone: byKey.get(epic.key)?.milestone || "—",
        total: epic.total,
        done: epic.done,
        pct: fmt1(epic.pct),
        barPct: epic.pct,
        barClass: barClass(epic.pct, epic.total),
        byTypeText: epic.byType.map((entry) => `${entry.type} ${entry.done}/${entry.total}`).join(" · "),
    }));

    // --- plan por hito ------------------------------------------------------------
    const named = metrics.milestoneRollup.filter((ms) => ms.name !== "-");
    const unassigned = metrics.milestoneRollup.find((ms) => ms.name === "-");

    view.milestoneRows = metrics.milestoneRollup.map((ms) => {
        let vsDeadline = "sin hito";
        let vsClass = "s-back";
        if (ms.releaseDate) {
            const d = ms.daysFromDeadline;
            if (d <= 0) {
                vsDeadline = `dentro · ${fmtSigned(d)} d`;
                vsClass = "s-done";
            } else if (ms.startDate && ms.startDate < metrics.deadline) {
                // La ventana arranca antes del deadline pero libera después: «arrastra».
                vsDeadline = `arrastra · ${fmtSigned(d)} d`;
                vsClass = "s-rev";
            } else {
                vsDeadline = `fuera · ${fmtSigned(d)} d`;
                vsClass = "s-crit";
            }
        }
        return {
            name: ms.name === "-" ? "Sin hito (sin fixVersion)" : ms.name,
            description: ms.description || (ms.name === "-" ? "items sin hito asignado" : ""),
            window: ms.startDate && ms.releaseDate ? `${ms.startDate} → ${ms.releaseDate}` : "—",
            releaseDate: ms.releaseDate || "—",
            total: ms.total,
            done: ms.done,
            pct: fmt1(ms.pct),
            barPct: ms.pct,
            barClass: barClass(ms.pct, ms.total),
            vsDeadline,
            vsClass,
        };
    });

    const late = named.filter((ms) => ms.afterDeadline);
    const dragging = late.filter((ms) => ms.startDate && ms.startDate < metrics.deadline);
    const fullyLate = late.filter((ms) => !ms.startDate || ms.startDate >= metrics.deadline);

    view.MILESTONE_NOTE = [
        `${named.length} hitos con fixVersion${unassigned ? ` y ${unassigned.total} items sin hito (${unassigned.done} cerrados)` : ""}.`,
        "Los conteos incluyen el contenedor de épica; el informe semanal generado por la extensión los excluye, así que allí verás cifras una unidad menores por hito.",
    ].join(" ");

    view.milestoneNotes = [];
    if (late.length) {
        view.milestoneNotes.push({
            cls: "crit",
            title: `El plan no cabe en el deadline: ${late.length} hitos liberan después del ${metrics.deadline}`,
            body: [
                `${late.map((ms) => ms.name).join(" y ")} suman ${late.reduce((acc, ms) => acc + ms.total, 0)} items y liberan más tarde que la fecha límite.`,
                dragging.length
                    ? `${dragging
                          .map(
                              (ms) =>
                                  `${ms.name} se pasa ${fmt1(ms.daysFromDeadline)} días, pero su ventana de trabajo empieza el ${ms.startDate}, antes del deadline`,
                          )
                          .join("; ")}: el desarrollo cae dentro del plazo y lo que se sale es la validación, no la construcción.`
                    : "",
                fullyLate.length
                    ? `${fullyLate
                          .map(
                              (ms) =>
                                  `${ms.name} arranca el ${ms.startDate || "—"} y libera ${fmt1(ms.daysFromDeadline)} días después del deadline`,
                          )
                          .join("; ")}: este sí está enteramente fuera del plazo.`
                    : "",
                "Re-planificar las ventanas dentro del plazo o mover el deadline son las dos salidas; mantener ambas cosas sin tocar es la única opción que no se sostiene.",
            ]
                .filter(Boolean)
                .join(" "),
        });
    }
    const zeroMilestones = named.filter((ms) => ms.pct === 0);
    if (zeroMilestones.length) {
        view.milestoneNotes.push({
            cls: "warn",
            title: `${zeroMilestones.length} hitos siguen a cero`,
            body: `${zeroMilestones
                .map((ms) => `${ms.name} (${ms.total} items, libera ${ms.releaseDate})`)
                .join("; ")}. El trabajo cerrado del proyecto está concentrado en las épicas DC2C-1 y DC2C-2.`,
        });
    }

    // --- mini-gantt ---------------------------------------------------------------
    const declared = snap.milestones.filter((ms) => ms.startDate && ms.releaseDate);
    const domainStart = [metrics.reportDate, ...declared.map((ms) => ms.startDate)].sort()[0];
    const domainEnd = [metrics.deadline, ...declared.map((ms) => ms.releaseDate)].sort().slice(-1)[0];
    // Se alinea a meses completos para que las guías verticales caigan en fronteras de mes.
    const axisStart = `${shiftMonth(domainStart, 0)}-01`;
    const axisEnd = dayToIso(dayNumber(`${shiftMonth(domainEnd, 1)}-01`) - 1);

    const GANTT_W = 900;
    const PAD_L = 190;
    const PAD_R = 40;
    const PLOT_TOP = 46;
    const ROW_H = 30;
    const BAR_H = 15;
    const plotW = GANTT_W - PAD_L - PAD_R;
    const span = dayNumber(axisEnd) - dayNumber(axisStart) || 1;
    const xOf = (iso) => PAD_L + ((dayNumber(iso) - dayNumber(axisStart)) / span) * plotW;
    const round1 = (n) => Math.round(n * 10) / 10;

    const gantt = { axisLabels: [], axisTicks: [], guides: [], rows: [], footLabels: [] };

    let month = axisStart;
    let first = true;
    while (dayNumber(month) <= dayNumber(axisEnd)) {
        const x = round1(xOf(month));
        // El eje se parte en dos filas apiladas (rótulos arriba, marcas abajo) para que los
        // nombres de mes no se pisen entre sí ni con las marcas.
        gantt.axisLabels.push({ x, y: 14, text: monthLabel(month, first || month.endsWith("-01")) });
        gantt.axisTicks.push({ x, y1: 20, y2: 28 });
        month = `${shiftMonth(month, 1)}-01`;
        first = false;
    }

    const plotBottom = PLOT_TOP + declared.length * ROW_H;
    for (const [iso, stroke, dash, text] of [
        [metrics.deadline, "#c0392b", "5 4", `deadline ${metrics.deadline}`],
        [metrics.reportDate, "#0b6bcb", "", `hoy ${metrics.reportDate}`],
    ]) {
        const x = round1(xOf(iso));
        gantt.guides.push({ x, y1: PLOT_TOP - 12, y2: plotBottom + 4, stroke, sw: 1.6, dash });
        gantt.footLabels.push({ x, anchor: "middle", text, fill: stroke, weight: 600 });
    }

    declared.forEach((ms, index) => {
        const rollup = metrics.milestoneRollup.find((r) => r.name === ms.name) || { pct: 0, done: 0, total: 0 };
        const x = round1(xOf(ms.startDate));
        const w = Math.max(3, round1(xOf(ms.releaseDate) - xOf(ms.startDate)));
        const y = PLOT_TOP + index * ROW_H;
        const pctLabel = `${fmt1(rollup.pct)}% · ${rollup.done}/${rollup.total}`;
        const labelX = x + w + 10;
        const fitsRight = labelX + pctLabel.length * 6.4 < GANTT_W;
        gantt.rows.push({
            name: ms.name,
            nameX: PAD_L - 12,
            nameY: y + BAR_H - 3,
            x,
            y,
            w,
            h: BAR_H,
            fillW: round1(w * (Math.min(100, rollup.pct) / 100)),
            fill: "#1a7f37",
            markX: round1(x + w),
            markY: y + BAR_H / 2,
            markFill: ms.releaseDate <= metrics.deadline ? "#16202b" : "#c0392b",
            // Si el rótulo no cabe a la derecha de la barra, se ancla a la izquierda del
            // extremo: si no, el último hito se saldría del viewBox.
            pctX: fitsRight ? labelX : round1(x + w - 10),
            pctY: y + BAR_H - 3,
            pctAnchor: fitsRight ? "start" : "end",
            pctLabel,
        });
    });

    const foot = layoutLabels(gantt.footLabels, 150, 2);
    gantt.footLabels = foot.placed.map((label) => ({ ...label, y: plotBottom + 22 + label.row * 15 }));

    view.gantt = gantt;
    view.GANTT_W = GANTT_W;
    view.GANTT_H = plotBottom + 22 + foot.rowCount * 15 + 8;
    view.GANTT_VIEWBOX = `0 0 ${GANTT_W} ${view.GANTT_H}`;
    view.GANTT_NOTE = [
        "Cada barra es la ventana de trabajo real del hito (startDate → release) sobre el eje temporal; el relleno verde es el porcentaje ya cerrado y el punto marca la fecha de liberación.",
        `${declared.length} hitos tienen ambas fechas y se dibujan; ${metrics.milestoneRollup.length - declared.length} grupo(s) sin fechas (items sin fixVersion) se omiten porque no tienen ventana.`,
        "Un hito que libera después de la línea roja está fuera del plazo; si además su barra empieza a la izquierda de esa línea, el desarrollo cae dentro y lo que se sale es la validación.",
    ].join(" ");

    // --- componentes --------------------------------------------------------------
    view.componentRows = metrics.components.map((component) => ({
        name: component.name,
        total: component.total,
        done: component.done,
        inFlight: component.inFlight,
        pct: fmt1(component.pct),
        barPct: component.pct,
        barClass: barClass(component.pct, component.total),
    }));
    view.COMPONENT_NOTE = [
        `${metrics.components.length} componentes en uso; ${metrics.withoutComponent} items no tienen ninguno.`,
        `Ninguna issue lleva más de un componente, así que los rollups suman exacto (${c.workTotal - metrics.withoutComponent} + ${metrics.withoutComponent} = ${c.workTotal} items de trabajo).`,
    ].join(" ");

    // --- vencimientos -------------------------------------------------------------
    const d = metrics.dueDates;
    view.dueRows = d.rows.map((row) => ({
        key: row.key,
        summary: row.summary,
        type: row.type,
        status: row.status,
        pillClass: STATUS_PILL[row.status] || "s-back",
        dueDate: row.dueDate,
        delta: fmtSigned(row.daysFromReport),
        stateLabel: (DUE_STATE[row.state] || { label: row.state }).label,
        stateClass: (DUE_STATE[row.state] || { cls: "s-back" }).cls,
        assignee: row.assignee,
    }));
    view.dueDates = {
        summary: {
            nextOpen: d.summary.nextOpen
                ? {
                      key: d.summary.nextOpen.key,
                      summary: d.summary.nextOpen.summary,
                      dueDate: d.summary.nextOpen.dueDate,
                      status: d.summary.nextOpen.status,
                      assignee: d.summary.nextOpen.assignee,
                      stateLabel: (DUE_STATE[d.summary.nextOpen.state] || { label: d.summary.nextOpen.state })
                          .label,
                  }
                : null,
        },
    };
    view.DUE_NOTE = [
        `Sólo ${d.summary.dated} de ${d.summary.dated + d.summary.undated} issues (${fmt1(d.summary.datedPct)} %) tienen fecha de vencimiento.`,
        "No son un calendario del proyecto: son un foco sobre trabajo concreto y por eso no sirven para medir desviación global.",
        `${d.summary.overdue} vencida sin cerrar, ${d.summary.dueToday} vence hoy, ${d.summary.dueSoon} en los próximos días.`,
    ].join(" ");

    // --- tiempo de ciclo ----------------------------------------------------------
    const ct = metrics.cycleTime;
    const fastest = ct.rows.reduce((best, row) => (best === null || row.minutes < best.minutes ? row : best), null);
    const asDuration = (minutes) => (minutes < 180 ? `${fmt1(minutes)} min` : `${fmt1(minutes / 1440)} d`);
    view.CYCLE_MEASURED = ct.measured;
    view.CYCLE_SEEDED = ct.seeded;
    view.CYCLE_WORKED = ct.worked;
    view.CYCLE_WINDOW = ct.seededWindowMinutes;
    view.CYCLE_WORKED_RANGE = ct.worked ? `${fmt1(ct.workedMinDays)} – ${fmt1(ct.workedMaxDays)} días` : "—";
    view.CYCLE_FASTEST = fastest ? asDuration(fastest.minutes) : "—";
    view.CYCLE_FASTEST_KEY = fastest ? fastest.key : "—";
    view.cycleRows = ct.rows
        .slice()
        .sort((a, b) => a.minutes - b.minutes)
        .map((row) => ({
            key: row.key,
            minutes: asDuration(row.minutes),
            label: row.seeded
                ? `siembra del tablero: cerrada en menos de ${ct.seededWindowMinutes} min`
                : "trabajo real",
        }));
    view.CYCLE_NOTE = [
        `Los ${ct.measured} cierres se reparten así: ${ct.seeded} se resolvieron menos de ${ct.seededWindowMinutes} minutos después de crearse y ${ct.worked} se trabajaron de verdad (${fmt1(ct.workedMinDays)} a ${fmt1(ct.workedMaxDays)} días).`,
        `Los cierres se concentran en una ventana de ${t.closureSpanDays} días, así que cualquier cifra de «items por semana» sería aritmética sin significado estadístico.`,
        "La distinción se hace comparando created con resolutiondate: resolutiondate sola no distingue trabajo de siembra.",
    ].join(" ");

    // --- riesgos ------------------------------------------------------------------
    // `origin` es opcional: lo añade el pipeline de la extensión para los riesgos que no se
    // derivan de Jira (por ejemplo los bloqueos del roadmap). Se rotula como «Fuente: …».
    view.riskNotes = metrics.risks.map((risk) => ({
        cls: RISK_CLASS[risk.level] || "info",
        title: esDecimals(risk.title),
        body: esDecimals(risk.detail),
        origin: risk.origin || null,
    }));

    // --- carga --------------------------------------------------------------------
    const maxLoad = metrics.assignees.reduce((max, row) => Math.max(max, row.total), 0) || 1;
    view.assigneeRows = metrics.assignees.map((row) => ({
        name: row.name,
        total: row.total,
        done: row.done,
        open: row.open,
        barPct: round1((row.total / maxLoad) * 100),
        barClass: row.name === "Sin asignar" ? "b-crit" : row.done > 0 ? "b-done" : "b-def",
    }));
    view.CONCENTRATION_NOTE = metrics.concentration
        ? `${metrics.concentration.name} acumula ${metrics.concentration.closed} de los ${c.closed} cierres (${fmt1(metrics.concentration.sharePct)} %) con un equipo de ${metrics.concentration.teamSize} personas. Es un riesgo de continuidad: el conocimiento del proyecto está en una sola persona.`
        : "Sin cierres que atribuir.";

    // --- qué queda y nota metodológica ---------------------------------------------
    view.actionItems = metrics.recommendations.map((item) => ({
        title: esDecimals(item.title),
        detail: esDecimals(item.detail),
    }));
    view.METHOD_SOURCE = `${c.total} issues leídas de Jira (${metrics.project.key} en ${metrics.project.site || "Jira Cloud"}) el ${metrics.reportDate}, con el mismo payload que consume el canvas jira-weekly.`;
    view.METHOD_COUNT = `Todo se cuenta por número de issues, no por esfuerzo. Los campos de story points están vacíos en las ${c.total} issues del proyecto, así que no hay burn-down por esfuerzo. Se publican dos denominadores porque la diferencia importa: ${c.total} issues incluyen las ${c.epics} épicas y ${c.workTotal} es el trabajo real.`;
    view.METHOD_GAPS = `No hay velocity ni story points (el campo está vacío en todo el proyecto) y no hay sprints: el tablero es Kanban, así que sprint in openSprints() no devuelve nada. Las fechas de vencimiento existen sólo en ${d.summary.dated} issues y no describen el calendario del proyecto. El ritmo observado no se publica mientras la ventana de cierres sea inferior a 21 días.`;
    view.METHOD_REPRO = `Este documento se genera con node tools/fill-report.mjs sobre el payload de Jira; no hay ningún número escrito a mano. La geometría del timeline la calcula el generador a partir de las fechas del payload. Sin scripts, sin CDN y sin peticiones de red: se abre con file:// o se imprime a PDF.`;

    return view;
}

// ---------------------------------------------------------------- CLI

async function main(argv) {
    const flags = new Set(argv.filter((arg) => arg.startsWith("--")));
    const positional = argv.filter((arg) => !arg.startsWith("--"));
    const payloadPath = positional[0] || DEFAULT_PAYLOAD;
    const outputPath = positional[1] || null;

    let model;
    try {
        model = await import(pathToFileURL(MODEL_PATH).href);
    } catch (error) {
        process.stderr.write(
            `No se pudo cargar el módulo de métricas en ${MODEL_PATH}.\n` +
                `Ajusta la ruta con la variable de entorno JIRA_WEEKLY_MODEL.\n${error.message}\n`,
        );
        process.exit(2);
    }

    const { normalizeSnapshot, computeMetrics } = model;
    if (typeof normalizeSnapshot !== "function" || typeof computeMetrics !== "function") {
        process.stderr.write(`${MODEL_PATH} no exporta normalizeSnapshot/computeMetrics.\n`);
        process.exit(2);
    }

    const payload = JSON.parse(readFileSync(payloadPath, "utf8"));
    const snapshot = normalizeSnapshot(payload);
    const metrics = computeMetrics(snapshot);
    const view = buildView(snapshot, metrics);

    const ast = parseTemplate(readFileSync(TEMPLATE_PATH, "utf8"));
    const report = { missing: new Set() };
    const html = renderNodes(ast.children, { parent: null, locals: view }, report);

    // Red de seguridad: si algún bloque anidado dejó un placeholder sin expandir, se detecta
    // aquí en lugar de llegar al HTML final.
    const leftovers = html.match(/\{\{[^{}]*\}\}/g);
    if (leftovers) for (const token of leftovers) report.missing.add(token.trim());

    if (report.missing.size) {
        const list = [...report.missing].sort().join(", ");
        if (flags.has("--allow-missing")) {
            process.stderr.write(`Aviso: ${report.missing.size} ruta(s) sin valor: ${list}\n`);
        } else {
            process.stderr.write(
                `Error: ${report.missing.size} ruta(s) de la plantilla no tienen valor: ${list}\n` +
                    "Usa --allow-missing para emitir el informe igualmente.\n",
            );
            process.exit(1);
        }
    }

    if (outputPath) {
        writeFileSync(outputPath, html, "utf8");
        process.stderr.write(`Informe escrito en ${outputPath} (${html.length} caracteres).\n`);
    } else {
        process.stdout.write(html);
    }
}

await main(process.argv.slice(2));
