# DuckDB Iceberg REST Catalog Experiment

Testing dbt Fusion's `catalogs.yml` v2 support for `iceberg_rest` type against a local Lakekeeper instance, using the debug binary from the `9402-duckdb-catalogs-v2` branch (PR dbt-labs/fs#9420).

## Setup

### Prerequisites
- Docker (via colima on macOS)
- Debug binary: `alias dbtd="/Users/dataders/Developer/fs.9402-duckdb-catalogs-v2/target/debug/dbt"`
- `/etc/hosts` entry: `127.0.0.1 minio` (Lakekeeper vends S3 paths using Docker-internal hostname)

### Infrastructure
`docker-compose.yml` spins up:
- **Lakekeeper** (Iceberg REST catalog) at `http://localhost:8181`
- **PostgreSQL 17** (Lakekeeper metadata store)
- **MinIO** (S3-compatible object storage) at `localhost:9000` (console at `localhost:9001`)
- Auto-bootstraps a warehouse named `demo` backed by MinIO bucket `examples`

```bash
docker-compose up -d    # start
docker-compose down     # stop
docker-compose down -v  # stop + wipe data (nuke and pave)
```

### Configuration
- `catalogs.yml` — v2 catalog definition for `iceberg_rest` type
- `profiles.yml` — `iceberg_rest` target with `:memory:` DuckDB, iceberg+httpfs extensions, S3 secret for MinIO
- `dbt_project.yml` — `use_catalogs_v2: true` flag, staging materialized as `table` (Iceberg doesn't support views)

## Findings

### Working
1. Lakekeeper + MinIO local stack works out of the box
2. `catalogs.yml` v2 with `iceberg_rest` parses and validates correctly (no `version:` key at top level — only `catalogs:`)
3. `dbt seed` successfully creates Iceberg tables via REST catalog — seeds load into `demo.main.*`
4. ATTACH SQL generation fires during DuckDB init, correctly attaching the Iceberg catalog

### Bug Found in PR #9420 (xdbc.rs)
The `generate_v2_catalog_attach_stmts()` method puts the endpoint URL as the ATTACH source argument:
```sql
-- WRONG (what the PR generates)
ATTACH IF NOT EXISTS 'http://localhost:8181/catalog' AS demo (TYPE ICEBERG, ...)

-- CORRECT (what DuckDB expects)
ATTACH IF NOT EXISTS 'demo' AS demo (TYPE ICEBERG, ENDPOINT 'http://localhost:8181/catalog', ...)
```

DuckDB's Iceberg extension expects the **warehouse name** as the first arg and `ENDPOINT` as an option.

**Fix applied** in `fs/sa/crates/dbt-adapter/src/engine/xdbc.rs`:
- Moved endpoint from source arg to `ENDPOINT '...'` option
- Added `warehouse` config key support (falls back to catalog name)
- Source arg now uses warehouse name instead of endpoint URL

### Iceberg Catalog Constraints (expected, not bugs)
1. **No views** — Iceberg only supports tables. Fixed by `+materialized: table` for staging.
2. **`DROP TABLE ... CASCADE` not supported** — DuckDB Iceberg rejects CASCADE. The table materialization macro uses CASCADE for cleanup.

### Blocking Bug: CTAS "already exists" (Fusion-specific)

`dbt run` fails on every model with:
```
Invalid Configuration Error: Table stg_customers__dbt_tmp already exists
```

**Not a DuckDB Iceberg extension bug.** Verified by replicating the exact Fusion query sequence in DuckDB CLI — CTAS works perfectly:
1. Same DuckDB v1.4.4, same iceberg extension (1095c1fa)
2. Same `CREATE SCHEMA IF NOT EXISTS`, same `information_schema.tables` query, same CTAS
3. Works in single-process and cross-process (dbt seed via Fusion, CTAS via DuckDB CLI)

**Root cause is in Fusion's ADBC execution layer.** Debug log shows only one CTAS statement, but DuckDB returns "already exists." The table IS registered in the Iceberg catalog (verified via Lakekeeper API). Hypothesis: ADBC prepared statement execution may create the table during `prepare()` then fail on `execute()`, or there's an internal retry that double-creates.

**Fusion debug log query sequence** (`dbt --log-level debug run`):
```
1. SELECT schema_name FROM system.information_schema.schemata WHERE lower(catalog_name) = '"demo"'
   -- NOTE: double quotes inside single quotes — likely returns wrong results
2. SELECT type FROM duckdb_databases() WHERE lower(database_name)='demo' AND type='sqlite'
3. CREATE SCHEMA IF NOT EXISTS "demo"."main"
4. SELECT table_catalog, ... FROM information_schema.tables WHERE table_schema = 'main'
5. CREATE TABLE "demo"."main"."stg_customers__dbt_tmp" AS (SELECT ... FROM "demo"."main"."raw_customers")
   -- FAILS: "Table stg_customers__dbt_tmp already exists"
```

### Also Noted
- Step 1 above has `'"demo"'` (double-quoted inside single quotes) in the WHERE clause — this is probably a quoting bug that causes the schema check to miss the `demo` catalog, but doesn't directly cause the CTAS failure.

### Open Questions
- What does Fusion's ADBC `execute_update()` do internally for CTAS against Iceberg? Is there a prepare/execute split that double-creates?
- Should the DuckDB table materialization use `CREATE OR REPLACE TABLE` or `CREATE TABLE IF NOT EXISTS` for Iceberg catalogs?
- Does `catalogs.yml` need a `warehouse` config key for cases where the warehouse name differs from the catalog name?
- The schema check quoting bug (`'"demo"'` vs `'demo'`) should be investigated separately.
