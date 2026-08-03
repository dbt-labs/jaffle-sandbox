---
name: data-exploration
kind: workflow
description: >
  Explore available sources, schemas, tables, columns, relationships, and data
  shape before writing dashboard YAML or answering analyst questions. Use when
  the user asks what data exists, where to find a metric/dimension, how tables
  relate, or which columns are available. Do NOT use for dashboard design
  decisions (use dashboard-design) or error diagnosis after a failed render
  (use dataface-troubleshooting).
metadata:
  author: fivetran
---
# Data Exploration

Use the schema tools before writing SQL. The goal is to discover the real data
vocabulary, then verify only the small pieces needed to answer the question.

## Workflow

1. **List sources.** Start with `dft schema` without filters to see which
   sources are available.
2. **Drill the hierarchy.** Use `dft schema` with source, schema, table, and
   column arguments as you learn them:
   - source level: schemas (with table counts)
   - schema level: tables and views in that namespace
   - table level: an **overview** — the table's grain ("one row per …"),
     primary date column, and joins (with multiplicity like `many-to-one`),
     plus each column's name, SQL type, and a short tag list (`pk`/`fk`,
     semantic type such as `currency_amount`, `pii`, and category `enum`
     values). The tags augment the SQL type — keep using the real type for casts.
   - column level: the **full profile** for one column — semantic type, role,
     distribution, completeness, distinct count, null %, numeric range, and top
     values. The table overview is deliberately terse; **drill into a column to
     get these stats.** Don't sample with SQL for something the column profile
     already carries.
3. **Fetch several columns or tables at once.** The TABLE and COLUMN arguments
   accept a single name, a list (`id,status,created_at` or
   `id|status|created_at`), or a glob (`*_id`, `created_*`). The same works for
   tables (`ticket|user`), so you can profile related columns across tables in
   one call instead of many round-trips.
4. **Search across the corpus.** Use `dft schema -s` when you know a
   keyword or property but not the exact table:
   - `keyword` for vocabulary like "customer", "invoice", or "churn"
   - `column_name` for globs like `*_id` or `customer_*`
   - `table_name` for table-family globs like `stg_*` or `fct_*`
   - `role`, `tag`, `has_test`, and `fk_to` for modeled metadata
5. **Sample only after narrowing candidates.** Use `dft query SOURCE SQL` once
   likely tables/columns are known, to validate cardinality, inspect example
   values, test joins, or answer a concrete data question.

## What To Return

For "what data do I have?" questions, answer with a concise analyst inventory:

- relevant sources and schemas
- likely fact tables and dimension tables
- important measures and dimensions
- known keys or relationships
- suggested analyses or dashboard ideas
- gaps where metadata is missing and the exact follow-up query you would run

For "where is X?" questions, list the best matching paths from
`dft schema -s` first, then explain why they match.

## Query Discipline

Do not default to metadata-discovery SQL such as `PRAGMA show_tables`,
`information_schema`, or adapter-specific metadata queries when `dft schema` or
`dft schema -s` can answer the question. Those tools use the same
project-aware metadata path the rest of Dataface uses.

When sampling with `dft query SOURCE SQL`:

- select only the columns needed for the question
- use small limits for row samples
- aggregate before charting or comparing categories
- preserve Dataface template placeholders such as `{{ variable_name }}` when
  testing parameterized SQL that may move into dashboard YAML

## Red Flags

- Writing SQL before checking table and column names
- Treating missing optional metadata as proof that a table or source is absent
- Guessing file paths or table names from memory
- Using dialect-specific discovery SQL before trying `dft schema` and
  `dft schema -s`
