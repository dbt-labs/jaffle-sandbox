---
name: dashboard-structural-review
kind: workflow
description: >
  Review a Dataface face's YAML structure and content choices without rendering.
  Reads the face file, runs schema validation, then evaluates the YAML against
  a design checklist (chart-data shape match, layout intent, variable wiring,
  descriptive naming, anti-patterns). Use when asked to 'review this
  dashboard', 'check this face', 'is this YAML well-shaped', 'find problems in
  this dashboard', or after editing a face before delivery. Cheap — no
  rendering, no PNG, no LLM judge in the loop. Do NOT use for visual problems
  that need to be seen (use dashboard-visual-review). Do NOT use as a YAML
  linter substitute — schema validation already covers that.
metadata:
  author: fivetran
---
# Dashboard Structural Review

Read the face's YAML, run `dft validate`,
then evaluate the design choices encoded in the YAML against a checklist.
Produces a markdown findings list with severity tags. No rendering required —
this is the cheap pass.

## When to use

- Post-build sanity check before delivering a new face
- Post-edit verification after adding charts, queries, or variables
- Pre-PR review of a face change
- First pass inside the `dashboard-review` orchestrator

## When NOT to use

- Schema validation alone — `dft validate`
  is the right tool, this skill calls it
- Visual problems ("the legend is overlapping the title") — use
  `dashboard-visual-review`
- Comparing two versions of a face — use `looker-compare-diff` pattern instead

## Protocol

1. **Validate.** Run `dft validate`
   on the face path:

   ```bash
dft validate faces/finance/revenue-overview.yml
```


   If validation reports errors, surface them and stop — there's nothing to
   review until the schema is valid.

2. **Read the face YAML** with the agent's file-reading tool.

3. **Evaluate against the checklist below.** For each finding, emit a row with
   severity, the YAML path or chart name, and a concrete fix.

## Checklist

### Layout intent

- [ ] Top of the face is a summary (KPI row, hero metric) — not a detail table
- [ ] Reading order (top-down, left-to-right) tells a story: headline → trend →
      breakdowns → detail
- [ ] Related charts are grouped (same `cols:` row or adjacent rows)
- [ ] No more than 8 visualizations on one face

### Chart-data shape match

- [ ] `type: kpi` queries return **exactly 1 row** (aggregate, not raw)
- [ ] `type: pie` queries are pre-aggregated and have **2–3 segments** (use
      `bar` for 4+)
- [ ] `type: line` / `area` use a temporal x-axis
- [ ] `type: bar` has a categorical x-axis (not a continuous date)
- [ ] `type: table` columns make sense as a list — no 1-row tables, no
      single-column tables that should be KPIs
- [ ] No single-bar bar charts (one bar = use a KPI)

### Variables and parameterization

- [ ] Filters declared in `variables:` are referenced by at least one query
- [ ] Queries don't hardcode values that should be variables (date ranges,
      categorical filters)
- [ ] Variable defaults are sensible (last 30 days, most common segment)
- [ ] Executive / always-on dashboards have **no** filter variables

### Descriptive metadata

- [ ] Every query has a `description:` (what it returns and why)
- [ ] Every chart has a `description:` (what question it answers)
- [ ] Every variable has a `description:` (how it should be used)
- [ ] Chart names communicate intent (`revenue_trend`, not `chart_1`)
- [ ] Titles state what the chart answers (`"Revenue by Region, Last 30 Days"`,
      not `"Sales"`)

### Anti-patterns

- [ ] No `kpi` displaying a string column (KPIs are numeric)
- [ ] No chart that exists without a clear question it answers
- [ ] No duplicated queries (same SQL repeated under different names)
- [ ] No raw / unaggregated data feeding a chart that requires pre-aggregation

### Formatting

- [ ] No raw D3 format strings — use named presets (`currency_compact`, not `"$,.2s"`)
- [ ] No explicit `format:` when auto-detection already produces the correct result (see auto-detection rules below)
- [ ] Currency columns without `$`-triggering names (`arr`, `mrr`, `acv`, etc.) have an explicit `format: currency*` preset set
- [ ] Integer columns where exact counts matter use `format: integer` (auto for large integers produces SI compact `~s`)

**Preset reference**

| Preset | D3 equivalent | Example |
|--------|--------------|---------|
| `integer` | `",.0f"` | `1,234` |
| `number` | `",.2f"` | `1,234.56` |
| `currency` | `"$,.2f"` | `$1,234.56` |
| `currency_whole` | `"$,.0f"` | `$1,234` |
| `currency_compact` | `"$,.2s"` | `$1.2M` |
| `percent` | `".1%"` | `2.3%` |
| `percent_whole` | `".0%"` | `2%` |
| `percent_delta` | `"+.1%"` | `+2.3%` |
| `compact` | `",.2s"` | `1.2M` |
| `date_short` | `"%-d %b %Y"` | `26 May 2026` |

**Auto-detection rules** (apply when no explicit `format:` is set)

- Column name matches `*_pct`, `*_rate`, `*_ratio`, `*_share`, `*_proportion` → renders as `percent` (`.1%`)
- Column name matches `*revenue*`, `*amount*`, `*cost*`, `*price*`, `*spend*`, `*profit*`, `*fee*` → renders as currency with `$`
- Integer DB type + value ≥ 10K → SI compact `~s` (no `$`, no commas) — override with `format: integer` when exact counts matter
- Integer DB type + value < 10K → `integer` format (`,.0f`)
- Columns named `arr`, `mrr`, `acv`, etc. do **not** trigger currency auto-detection — always set an explicit `format: currency*` preset

## Output format

A markdown bulleted list, severity-tagged. Group by severity, most severe first:

```markdown
**Findings**

- `blocker` `charts.revenue_kpi`: query returns 12 rows but `type: kpi` requires
  exactly 1. Aggregate with `SUM()` or take the latest row only.
- `warning` `charts.region_pie`: 7 segments in a pie chart — humans compare
  angles poorly past 3. Switch to `type: bar` ordered by value.
- `warning` `queries.orders`: no `description:` field. Add one sentence stating
  what the query returns.
- `nit` `charts.chart_1`: generic name. Rename to indicate intent
  (e.g. `daily_active_users`).
```

If there are no findings: emit exactly `**No findings.**` so the orchestrator
can short-circuit.

## Severity rubric

| Tag | Meaning | Examples |
|---|---|---|
| `blocker` | The face will render wrong, error, or mislead | KPI on multi-row query; bar chart on raw rows when GROUP BY is expected |
| `warning` | The face renders but violates a clear design principle | Pie with >3 segments; missing descriptions; generic titles |
| `nit` | Stylistic — author can take or leave | Suboptimal chart name; consistent-but-verbose pattern |

## Common mistakes

| Mistake | Fix |
|---|---|
| Returning "looks fine" without validating first | Always run `dft validate` — if it fails, there's nothing to review |
| Padding findings with `nit`-level noise | Cap at 5 findings total; promote the most severe |
| Emitting findings without a concrete fix | Every finding needs an actionable suggestion |
| Inventing rules not in the checklist | Stay anchored to the checklist; if you discover a real gap, file a follow-up to extend the skill |

## Rationalizations to resist

| Excuse | Reality |
|---|---|
| "The user knows what they're doing" | Reviewing is the job. Apply the checklist. |
| "I'll just suggest the fix without the severity tag" | Severity is how the orchestrator ranks and the user prioritizes. Always tag. |
| "If I can't find anything, I'll find something" | If the face passes the checklist, say so. Padding erodes the skill's signal. |
