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

### DuckDB Iceberg Extension Limitations Hit
1. **`CREATE VIEW` not supported** — Iceberg tables only, no views. Fixed by setting `+materialized: table` for staging models.
2. **`DROP TABLE ... CASCADE` not supported** — The table materialization uses CASCADE which Iceberg rejects.
3. **Orphaned `__dbt_tmp` tables** — The table materialization creates `{model}__dbt_tmp` via CTAS, but on failure the tmp table persists in the Iceberg catalog. Subsequent runs fail because `DROP TABLE IF EXISTS` (with CASCADE) can't clean them up. Requires nuking the Lakekeeper stack (`docker-compose down`) to reset.

### Open Questions
- Why does the CTAS for `__dbt_tmp` tables fail/repeat even on a fresh catalog with a single model? The compiled SQL looks correct. Needs deeper investigation into the Fusion adapter's task execution for Iceberg catalogs.
- Should the DuckDB table materialization be adapted for Iceberg (skip CASCADE, use `CREATE OR REPLACE TABLE` if supported)?
- Does the `catalogs.yml` need a `warehouse` config key for cases where the warehouse name differs from the catalog name?
