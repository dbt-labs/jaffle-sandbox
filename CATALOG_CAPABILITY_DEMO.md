# DuckDB Catalog Capability Demo

This branch adds small catalog probes under `models/catalog_demo/`. The default
project is intentionally runnable without any external catalog service.

Fusion currently initializes every DuckDB v2 REST catalog present in
`catalogs.yml` before model selection. Keep only the catalog backend under test
in `catalogs.yml`; otherwise an unhealthy REST catalog can block unrelated
local DuckDB, DuckLake, or local filesystem probes.

## Debug Binary

```bash
DBT=/Users/dataders/Developer/fs.codex-conference-catalog-demo-debug/target/debug/dbt
```

## Catalog Files

Default local demo:

```bash
cp catalogs.local.example.yml catalogs.yml
$DBT parse --profiles-dir . --target catalog_showcase --no-partial-parse
```

Lakekeeper Iceberg REST demo:

```bash
cp catalogs.lakekeeper.example.yml catalogs.yml
docker-compose up -d
$DBT run-operation lakekeeper_insert_probe --profiles-dir . --target iceberg_rest --no-partial-parse
$DBT show --profiles-dir . --target iceberg_rest --inline 'select count(*) as rows from iceberg_demo.default.lakekeeper_insert_probe' --limit 1 --output json --no-partial-parse
```

Lakekeeper currently verifies the DuckDB Iceberg `CREATE TABLE` + `INSERT`
path. CTAS/table materialization creates the temp table in Lakekeeper but the
DuckDB client reports `Table ... already exists`, so the demo keeps that as a
known unsupported path rather than using it as the primary proof.

Polaris Iceberg REST demo:

```bash
cp catalogs.polaris.example.yml catalogs.yml
export POLARIS_URI=...
export POLARIS_WAREHOUSE=...
export POLARIS_CLIENT_ID=...
export POLARIS_CLIENT_SECRET=...
export POLARIS_OAUTH2_SERVER_URI=...
$DBT show --profiles-dir . --target polaris_iceberg_rest --select tag:catalog_polaris_metadata --limit 5 --output json --no-partial-parse
```

For OAuth-backed Iceberg REST catalogs, DuckDB expects credentials in a
`TYPE iceberg` secret and `catalogs.yml` references that secret by name during
`ATTACH`.

Avoid using `dbt debug --connection` in a live demo with real Polaris
environment variables; it prints the rendered profile, including secret fields.

Reference: <https://duckdb.org/docs/current/core_extensions/iceberg/iceberg_rest_catalogs>

MotherDuck DuckLake demo:

```bash
MOTHERDUCK_TOKEN=... $DBT run --profiles-dir . --target ducklake_md_no_path --select tag:catalog_remote_ducklake --no-partial-parse
MOTHERDUCK_TOKEN=... $DBT show --profiles-dir . --target ducklake_md_no_path --inline "select count(*) as rows from jaffle_ducklake_remote_demo.main.remote_ducklake_catalog_demo" --limit 1 --output json --no-partial-parse
```

The MotherDuck target intentionally keeps the token out of the `attach.path`.
The current working database for this token is `jaffle_ducklake_remote_demo`.

## Verified Local Probes

These passed with the debug binary on May 23, 2026:

```bash
$DBT run --profiles-dir . --target local --select tag:catalog_builtin --no-partial-parse
$DBT run --profiles-dir . --target ducklake_no_path --select tag:catalog_local_ducklake --no-partial-parse
$DBT run --profiles-dir . --target catalog_showcase --select tag:catalog_local_filesystem --no-partial-parse
```

Expected results:

| Capability | Selector | Target | Status |
| --- | --- | --- | --- |
| Built-in DuckDB catalog write | `tag:catalog_builtin` | `local` | Verified writable table. |
| Local DuckLake catalog write | `tag:catalog_local_ducklake` | `ducklake_no_path` | Verified writable table via `ducklake:` attach. |
| Local filesystem external write | `tag:catalog_local_filesystem` | `catalog_showcase` | Verified external CSV write from `source('local_files', 'raw_orders')`. |
| MotherDuck DuckLake catalog write | `tag:catalog_remote_ducklake` | `ducklake_md_no_path` | Verified writable with a real `MOTHERDUCK_TOKEN`; readback count returned 1. |
| Lakekeeper Iceberg REST create/insert/read | `lakekeeper_insert_probe` | `iceberg_rest` | Verified with debug `dbt run-operation` plus readback count. |
| Lakekeeper Iceberg REST CTAS/table materialization | `tag:catalog_iceberg_rest` | `iceberg_rest` | Catalog service is healthy, but CTAS currently fails after creating the temp table with `Table ... already exists`. |
| Polaris Iceberg REST metadata | `tag:catalog_polaris_metadata` | `polaris_iceberg_rest` | Verified with debug `dbt show`; returns real `polaris_demo` tables. |
| Polaris Iceberg REST data read/write | ad hoc inline query | `polaris_iceberg_rest` | Data read currently fails with DuckDB Iceberg HTTP 400 on snapshot Avro; writes not attempted. |
| Unity Catalog Iceberg REST | not configured | add a local-only catalog file | Cross-engine reads should work; DuckDB writes to UC remain blocked by open DuckDB Iceberg bugs. |
| Snowflake Horizon | not configured | n/a | Local Snowflake profiles exist, but no Horizon catalog/external-volume demo artifact is configured in this project. |

## Cheap Checks

```bash
$DBT parse --profiles-dir . --target catalog_showcase --no-partial-parse
$DBT ls --profiles-dir . --target catalog_showcase --select tag:capability_probe --no-partial-parse
$DBT ls --profiles-dir . --target ducklake_no_path --select tag:catalog_local_ducklake --no-partial-parse
MOTHERDUCK_TOKEN=... $DBT ls --profiles-dir . --target ducklake_md_no_path --select tag:catalog_remote_ducklake --no-partial-parse
$DBT ls --profiles-dir . --target polaris_iceberg_rest --select tag:catalog_polaris_metadata --no-partial-parse
```

`ducklake_md_no_path` attaches `md:jaffle_ducklake_remote_demo`; the MotherDuck
extension reads `MOTHERDUCK_TOKEN` from the runtime environment, so even static
`parse` or `ls` checks for that target need the environment variable set.
