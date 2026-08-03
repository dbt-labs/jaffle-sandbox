---
name: dashboard-design
kind: workflow
description: >
  Design principles for Dataface dashboards — at-a-glance monitoring displays.
  Use when choosing chart types, designing dashboard layouts, picking colors,
  deciding dashboard vs report, or when the user says 'what chart type',
  'how should I lay this out', 'dashboard design'. Covers information
  hierarchy, chart selection, layout patterns, and visual design. Do NOT
  use for reports or narrative analyses (use report-design). Do
  NOT use for the build-test-iterate workflow (use
  dashboard-build). Do NOT use for fixing errors (use
  dataface-troubleshooting).
metadata:
  author: fivetran
---
# Dashboard Design

Design dashboards for **at-a-glance monitoring** — clear, scannable, action-oriented displays.

> Implementing in YAML? Switch to `dft skills dashboard-build` for the build-test-iterate workflow.

## Dashboard vs. Report

| | Dashboard | Report |
|--|-----------|--------|
| **Purpose** | Monitor status at a glance | Answer a question, tell a story |
| **Frequency** | Daily / continuous | One-time or periodic |
| **Text** | Minimal — titles and labels | Extensive — narrative + recommendations |
| **Charts** | Primary content | Supporting evidence for the narrative |
| **Interaction** | Scan in seconds | Read in minutes |

If the user needs a narrative analysis, use the `report-design` skill instead.

## Core Principles

1. **Single screen** — no scrolling. If it doesn't fit, split into multiple dashboards.
2. **Scannable in seconds** — a glance should convey status.
3. **Every element earns its place** — remove anything that doesn't aid understanding.
4. **Context for every number** — a number without comparison (trend, target, prior period) is meaningless.
5. **Purpose-driven** — every chart answers a specific question.

## Metadata Requirement

Whenever you output or edit Dataface YAML, add `description` metadata:

- `queries.*.description` for query intent
- `charts.*.description` for chart intent
- `variables.*.description` for filter semantics
- Layout object `description` fields (`rows`/`cols`/`grid.items`/`tabs.items`) when they add context

Descriptions should be concise and optimized for AI retrieval.

## Thinking Process

Before designing, work through these in order:

### 1. Audience & Purpose

- **Who** views this? (executive, analyst, operator)
- **When** do they view it? (morning standup, weekly review, always-on monitor)
- **What decision** does this inform?

### 2. Information Hierarchy

- What is the **#1 most important metric**? → top-left, largest
- What are the **3-5 supporting KPIs**? → KPI row
- What **trends** matter? → line/area charts
- What **comparisons** are useful? → bar charts
- What **detail** supports drill-down? → tables at the bottom

### 3. Chart Selection

| Question | Chart Type | Notes |
|----------|-----------|-------|
| Current value? | `kpi` | Big number, prominent position |
| Trending over time? | `line` | Continuous data, time on x-axis |
| Category comparison? | `bar` | Categorical x-axis, include zero baseline |
| Composition over time? | `area` (stacked) | Parts of a whole changing |
| Portion of whole? | `pie` | **Only for 2-3 segments** — use bar for more |
| Relationship? | `scatter` | Two numeric variables |
| Precise values? | `table` | When exact numbers matter |

**Avoid:**
- Pie for >3 categories (humans compare angles poorly — use bar)
- Multiple chart types for visual variety (consistency aids scanning)
- Scrolling layouts (if it scrolls, it's a report)

### 4. Layout — Inverted Pyramid

Most important information first, following Western reading pattern (top-left → bottom-right):

```
┌──────────────────────────────────────────────┐
│  KPI 1  │  KPI 2  │  KPI 3  │  KPI 4       │  ← HEADLINE
├──────────────────────────────────────────────┤
│  Primary trend chart (line/area)             │  ← STORY
├──────────────────────┬───────────────────────┤
│  Comparison chart    │  Comparison chart     │  ← CONTEXT
├──────────────────────┴───────────────────────┤
│  Detail table (if needed)                    │  ← EVIDENCE
└──────────────────────────────────────────────┘
```

- **4-8 total visualizations maximum**
- Related metrics grouped by proximity
- Consistent styling throughout

### 5. Color & Visual Design

- **Gray is default** — muted everything, ONE accent color for emphasis
- **Color carries meaning** — same color = same meaning everywhere
- **Direct labels** on charts when possible, not separate legends
- **Maximize data-ink ratio** — every pixel should represent data

### 6. Numeric Display

Apply standard numeric-display judgment (two-numeral rule, no false precision, tabular numerals in columns). Dataface-specific defaults:

- **Use format aliases, not raw d3 specs.** `format: currency_whole`, `format: percent`, `format: percent_delta`, `format: integer`, `format: compact`. Raw d3 (`"$,.0f"`) only when no alias fits.
- **Drop cents above $10.** `format: currency_whole` is the dashboard default. Reserve `format: currency` (with cents) for reconciliation surfaces — billing, financial statements.
- **Notation family: analytic for chrome, narrative for prose.** Analytic (`$2.5 M`, space, uppercase K/M/B) for axes, KPIs, tables, tooltips. Narrative (`$2.5mn`, no space, lowercase) only for text cards, titles, annotations. Independent of theme choice.
- **Zero strips trailing decimals even when siblings have them.** A `$0` KPI uses `currency_whole` even if its partner uses `currency`. A `0%` KPI uses `percent_whole` even if its partner uses `.2%`. The rule generalizes to any unit.
- **Percent precision is a group decision.** Default by magnitude: ≥20% → `.0%`; 1–20% → `.1%`; <1% → `.2%`. **Modulate by surface:** a single KPI or short rail can afford one more decimal; a long table column or axis wants the simpler form. **Override:** when tenths carry signal regardless of magnitude (A/B rates, churn, conversion in a tight range), use `format: ".2%"`.
- **Compaction is a group decision, not per-value.** Compact when ≥4 similar-magnitude values exceed 10,000, or when surface density demands it. Adjacent surfaces showing the same metric may compact differently — a reconciliation table can show full precision while the headline KPI uses `currency_compact`.
- **NULL renders as `—` (em-dash), never `0`.** Different claims about the data.
- **Tables anchor the currency symbol.** Default `symbol_mode: anchors` — first row carries the `$`, rows below don't.

### 7. Variables & Interactivity

Add variables when the dashboard serves different time windows or segments:

- Date ranges → `daterange` input
- Categorical filters → `select` input
- Set sensible defaults (last 30 days, most common category)
- **NOT for executive dashboards** — those show the single most important view

## Dashboard Patterns

### Executive Dashboard
4-6 KPIs → main trend → 2-3 breakdowns. No interaction. Show the single most important view.

### Operational Dashboard
Status KPIs with alerts → recent activity → issues table. Emphasize what needs attention now.

### Analytical Dashboard
KPIs → trends with filters → comparisons across dimensions → detail table. Include `variables:` for interactive filtering.

## Quality Checklist

Before delivering:

- [ ] Fits on one screen (≤8 visualizations, no scrolling)
- [ ] KPIs are first and most prominent (top row)
- [ ] Every number has context (comparison, trend, or target)
- [ ] Chart types match the analytical question
- [ ] Related metrics grouped by proximity
- [ ] Color is purposeful, not decorative
- [ ] Titles are informative ("Revenue by Region, Last 30 Days" not "Chart 1")
- [ ] User's most important question answered at a glance
- [ ] Query/chart/variable/layout `description` metadata is filled for AI context

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Too many charts (>8) | Split into multiple focused dashboards |
| KPIs without context | Add comparison period, trend, or target |
| Pie chart with 7 segments | Use a bar chart instead |
| Decorative color | Color must encode data or meaning |
| Generic titles | Titles should state what the chart answers |
| Scrolling dashboard | Reduce charts or split dashboards |

## Rationalizations to Resist

| Excuse | Reality |
|--------|---------|
| "User asked for 12 metrics on one page" | 8 max. Propose splitting into focused dashboards. |
| "Pie chart is fine for 6 categories" | It's not — humans compare angles poorly. Use bar. |
| "The legend explains the colors" | Direct labels are always better than legends. |
| "More charts = more value" | More charts = more noise. Each must earn its place. |
