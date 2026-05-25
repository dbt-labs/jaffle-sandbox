# DuckDB Catalog Capability Demo

This branch keeps the demo as the normal jaffle-shop DAG. Catalog behavior is
controlled by model config, not by separate proof-only models or profile
targets.

## Shape

- `catalogs.yml` contains the catalog definitions used by the demo: Lakekeeper,
  Polaris, Snowflake Horizon, Databricks Unity Catalog, DuckLake, and local
  files.
- `profiles.yml` has one DuckDB target: `catalog_demo`.
- `profiles.yml` does not use DuckDB `attach:` blocks; catalog attachment comes
  from `catalogs.yml`.
- `dbt_project.yml` defaults model writes to the built-in DuckDB catalog with
  `JAFFLE_CATALOG=builtin`.
- Individual layers can move by setting `JAFFLE_STAGING_CATALOG`,
  `JAFFLE_ORDERS_CATALOG`, and `JAFFLE_CUSTOMERS_CATALOG`.

The important demo knob is `catalog`, for example:

```yaml
models:
  jaffle_shop:
    orders:
      +catalog: "{{ env_var('JAFFLE_ORDERS_CATALOG', env_var('JAFFLE_CATALOG', 'builtin')) }}"
```

## Runtime

Use the fs debug binary from the stacked Fusion branches:

```bash
export DBT=/Users/dataders/Developer/fs/target/debug/dbt
```

Start Lakekeeper, Postgres, and MinIO for the local writable Iceberg REST
catalog:

```bash
docker-compose up -d
```

Set remote catalog credentials in the environment before running the full demo:

```bash
export POLARIS_URI=...
export POLARIS_WAREHOUSE=...
export POLARIS_CLIENT_ID=...
export POLARIS_CLIENT_SECRET=...
export POLARIS_OAUTH2_SERVER_URI="${POLARIS_URI%/}/v1/oauth/tokens"

export HORIZON_ENDPOINT=...
export HORIZON_WAREHOUSE=...
export HORIZON_PAT=...
export HORIZON_OAUTH2_SERVER_URI="${HORIZON_ENDPOINT%/}/v1/oauth/tokens"
export HORIZON_OAUTH2_SCOPE="session:role:<role>"
export HORIZON_DEFAULT_SCHEMA=ICEBERGRESTPARTITIONBY

export DATABRICKS_UC_ENDPOINT=...
export DATABRICKS_UC_CATALOG=...
export DATABRICKS_UC_SCHEMA=...
export DATABRICKS_TOKEN=...
```

`HORIZON_PAT` should be a retained/static token secret. The old helper that
generated a short-lived key-pair JWT is intentionally not part of the main
demo path.

## Runs

Default run, all jaffle models in built-in DuckDB:

```bash
$DBT seed --profiles-dir . --target catalog_demo --no-partial-parse
$DBT run --profiles-dir . --target catalog_demo --no-partial-parse
```

Move the staging layer to Lakekeeper and marts to Horizon:

```bash
JAFFLE_STAGING_CATALOG=lakekeeper \
JAFFLE_STAGING_SCHEMA=default \
JAFFLE_ORDERS_CATALOG=horizon \
JAFFLE_ORDERS_SCHEMA=ICEBERGRESTPARTITIONBY \
JAFFLE_CUSTOMERS_CATALOG=horizon \
JAFFLE_CUSTOMERS_SCHEMA=ICEBERGRESTPARTITIONBY \
$DBT run --profiles-dir . --target catalog_demo --full-refresh --no-partial-parse
```

Move the whole DAG to DuckLake:

```bash
JAFFLE_CATALOG=ducklake \
JAFFLE_SCHEMA=main \
$DBT run --profiles-dir . --target catalog_demo --full-refresh --no-partial-parse
```

Read source tables routed through catalog definitions:

```bash
$DBT show --profiles-dir . --target catalog_demo \
  --inline 'select count(*) as rows from polaris.sql_server_covid19.us_states' \
  --output json --no-partial-parse

$DBT show --profiles-dir . --target catalog_demo \
  --inline 'select count(*) as rows from horizon.ICEBERGRESTPARTITIONBY.MANAGED_TABLE' \
  --output json --no-partial-parse
```

## Current Capability Notes

| Catalog | Demo role | Status |
| --- | --- | --- |
| Built-in DuckDB | Default write target | Works as the default `builtin` catalog. |
| Local DuckLake | Optional write target | Works through `catalog: ducklake`. |
| Local files | Source catalog | `source('local_files', 'raw_orders')` declares the local filesystem source. |
| Lakekeeper | Writable Iceberg REST target | Works for DuckDB/Fusion writes when the local service is running. |
| Polaris | Read-only source catalog for this demo | Reads work; do not use it as a write target in the conference demo. |
| Snowflake Horizon | Writable Iceberg REST target | Writes require a Horizon schema with a default external volume and DuckDB CTAS fallback to create-then-insert. |
| Databricks Unity Catalog | Writable Iceberg REST target | Writes require the patched DuckDB-Iceberg branch with the manifest schema-header and UC vended-credential fixes. |

The DuckDB-Iceberg demo extension branch is
`dataders/codex/demo-horizon-uc-write-compat`.

## Source Declarations

`models/sources.yml` declares Polaris, Horizon, and local filesystem sources.
That keeps read-only catalog access in dbt source definitions instead of
embedding direct three-part names throughout the model DAG.

## Stack Pointers

- fs PR #10457: conference catalog routing demo base.
- fs PR #10464: DuckDB Snowflake Horizon catalog support.
- fs PR #10478: DuckDB Unity Catalog attachment support.
- DuckDB-Iceberg branch `codex/demo-horizon-uc-write-compat`: Horizon write
  compatibility plus Unity Catalog write fixes.
