# DuckDB Catalog Capability Demo

This branch adds small catalog probes under `models/catalog_demo/`. The default
project is intentionally runnable without any external catalog service.

Fusion currently initializes every DuckDB v2 REST catalog present in
`catalogs.yml` before model selection. Keep only the catalog backend under test
in `catalogs.yml`; otherwise an unhealthy REST catalog can block unrelated
local DuckDB, DuckLake, or local filesystem probes.

## Debug Binary

```bash
DBT=/Users/dataders/Developer/fs.codex-duckdb-horizon-catalog/target/debug/dbt
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

Lakekeeper verifies both DuckDB Iceberg `CREATE TABLE` + `INSERT` and dbt table
materialization via create-then-insert when the runtime is DuckDB `1.5.3` with
a fresh `iceberg` extension cache.

Polaris Iceberg REST demo:

```bash
cp catalogs.polaris.example.yml catalogs.yml
export POLARIS_URI=...                 # local secrets.zsh uses POLARIS_URL
export POLARIS_WAREHOUSE=...
export POLARIS_CLIENT_ID=...           # local secrets.zsh uses POLARIS_ID
export POLARIS_CLIENT_SECRET=...       # local secrets.zsh uses POLARIS_SECRET
export POLARIS_OAUTH2_SERVER_URI="${POLARIS_URI%/}/v1/oauth/tokens"
$DBT show --profiles-dir . --target polaris_iceberg_rest --select tag:catalog_polaris_metadata --limit 5 --output json --no-partial-parse
$DBT show --profiles-dir . --target polaris_iceberg_rest --inline 'select count(*) as rows from polaris_demo.sql_server_covid19.us_states' --limit 1 --output json --no-partial-parse
```

For OAuth-backed Iceberg REST catalogs, DuckDB expects credentials in a
`TYPE iceberg` secret and `catalogs.yml` references that secret by name during
`ATTACH`.

Avoid using `dbt debug --connection` in a live demo with real Polaris
environment variables; it prints the rendered profile, including secret fields.

Reference: <https://duckdb.org/docs/current/core_extensions/iceberg/iceberg_rest_catalogs>

Conference cross-catalog demo:

```bash
cp catalogs.conference.example.yml catalogs.yml
$DBT run --profiles-dir . --target conference_catalog_demo --select tag:conference_catalog_demo --no-partial-parse
$DBT show --profiles-dir . --target conference_catalog_demo --inline 'select * from iceberg_demo.default.polaris_to_lakekeeper' --output json --no-partial-parse
$DBT show --profiles-dir . --target conference_catalog_demo --inline 'select database_name from duckdb_databases() order by 1' --output json --no-partial-parse
```

The default conference catalog file intentionally omits Horizon so the
Polaris-to-Lakekeeper write path stays simple. To add Horizon reads, copy
`catalogs.conference.horizon.example.yml` to `catalogs.yml`, generate Horizon
OAuth env vars from a Snowflake key-pair profile, and enable the Horizon read
model on the `conference_catalog_demo_horizon` target.

```bash
cp catalogs.conference.horizon.example.yml catalogs.yml
uv run --no-project --with pyyaml --with pyjwt --with cryptography \
  scripts/horizon_keypair_env.py --profile fusion_tests --target snowflake \
  > /tmp/horizon_env.sh
source /tmp/horizon_env.sh
ENABLE_HORIZON_READ_MODEL=true $DBT run --profiles-dir . --target conference_catalog_demo_horizon --select tag:conference_catalog_demo --no-partial-parse
ENABLE_HORIZON_READ_MODEL=true $DBT show --profiles-dir . --target conference_catalog_demo_horizon --inline "select 'polaris_to_lakekeeper' as model, * from iceberg_demo.default.polaris_to_lakekeeper union all select 'horizon_read_probe' as model, * from iceberg_demo.default.horizon_read_probe order by model" --output json --no-partial-parse
$DBT show --profiles-dir . --target conference_catalog_demo_horizon --inline 'select database_name, type from duckdb_databases() order by 1' --output json --no-partial-parse
```

This avoids the 15-token Snowflake PAT cap by using a short-lived JWT as the
OAuth client secret. The local proof used the patched local DuckDB-Iceberg
extension cache and Snowflake-managed Iceberg table
`horizon_demo.ICEBERGRESTPARTITIONBY.MANAGED_TABLE`, which is visible through
the Horizon REST catalog and currently returns 17 rows. Stock DuckDB-Iceberg may
still reject the Horizon-specific REST ATTACH options until the extension patch
lands upstream.

The Horizon-enabled demo now runs both models in one command: Polaris reads and
Horizon reads are both materialized into Lakekeeper Iceberg tables through the
vanilla Fusion DuckDB adapter.

MotherDuck DuckLake demo:

```bash
MOTHERDUCK_TOKEN=... $DBT run --profiles-dir . --target ducklake_md_no_path --select tag:catalog_remote_ducklake --no-partial-parse
MOTHERDUCK_TOKEN=... $DBT show --profiles-dir . --target ducklake_md_no_path --inline "select count(*) as rows from jaffle_ducklake_remote_demo.main.remote_ducklake_catalog_demo" --limit 1 --output json --no-partial-parse
```

The MotherDuck target intentionally keeps the token out of the `attach.path`.
The current working database for this token is `jaffle_ducklake_remote_demo`.
MotherDuck currently rejects DuckDB `1.5.3`; use DuckDB `1.5.2` for this probe
until MotherDuck publishes a compatible extension.

## Verified Local Probes

These passed with the debug binary on May 25, 2026 (`3d3986ebeb`):

```bash
$DBT run --profiles-dir . --target local --select tag:catalog_builtin --no-partial-parse
$DBT run --profiles-dir . --target ducklake_no_path --select tag:catalog_local_ducklake --no-partial-parse
$DBT run --profiles-dir . --target catalog_showcase --select tag:catalog_local_filesystem --no-partial-parse
```

Expected results:

| Capability | Selector | Target | Status |
| --- | --- | --- | --- |
| Built-in DuckDB catalog write | `tag:catalog_builtin` | `local` | Verified writable table. |
| Local DuckLake catalog write | `tag:catalog_local_ducklake` | `ducklake_no_path` | Verified writable table via a fresh `ducklake:` metadata file. Older local `jaffle_ducklake.ducklake` metadata was version `0.3`; DuckLake now expects version `1.0`. |
| Local filesystem external write | `tag:catalog_local_filesystem` | `catalog_showcase` | Verified external CSV write from `source('local_files', 'raw_orders')`; readback returned `source_rows = 6`. |
| MotherDuck DuckLake catalog write | `tag:catalog_remote_ducklake` | `ducklake_md_no_path` | Blocked on DuckDB `1.5.3`: MotherDuck reports latest supported DuckDB version is `1.5.2`. |
| Lakekeeper Iceberg REST create/insert/read | `lakekeeper_insert_probe` | `iceberg_rest` | Verified with debug `dbt run-operation` plus readback count. |
| Lakekeeper Iceberg REST table materialization | `tag:catalog_iceberg_rest` | `iceberg_rest` | Verified writable table via dbt/Fusion create-then-insert with DuckDB 1.5.3; readback returned 1 row. |
| Lakekeeper via PyIceberg | direct PyIceberg probe | n/a | Verified PyIceberg can list the `default` namespace and read `default.iceberg_rest_catalog_demo` and `default.lakekeeper_insert_probe`, each with 1 row. |
| Polaris Iceberg REST metadata | `tag:catalog_polaris_metadata` | `polaris_iceberg_rest` | Verified with debug `dbt show`; returns real `polaris_demo` tables. |
| Polaris Iceberg REST data read | ad hoc inline query | `polaris_iceberg_rest` | Verified readable with DuckDB 1.5.3 when `DEFAULT_REGION 'us-west-2'` is present in the Iceberg REST ATTACH. Without it, DuckDB reaches the table but cannot resolve an object-store region from Polaris vended credentials. |
| Polaris to Lakekeeper cross-catalog write | `tag:conference_catalog_demo` | `conference_catalog_demo` | Verified source read from `polaris_demo.sql_server_covid19.us_states`, table write to `iceberg_demo.default.polaris_to_lakekeeper`, and readback `source_rows = 56`. |
| Polaris + Lakekeeper + Horizon attachments | inline `duckdb_databases()` | `conference_catalog_demo_horizon` | Verified three Iceberg catalogs attached together: `polaris_demo`, `iceberg_demo`, and `horizon_demo`, using the patched local DuckDB-Iceberg extension cache. |
| Snowflake Horizon to Lakekeeper cross-catalog write | `tag:conference_catalog_demo` with `ENABLE_HORIZON_READ_MODEL=true` | `conference_catalog_demo_horizon` | Verified read of Snowflake-managed Iceberg table `horizon_demo.ICEBERGRESTPARTITIONBY.MANAGED_TABLE` via Horizon, table write to `iceberg_demo.default.horizon_read_probe`, and readback `source_rows = 17`. |
| Polaris via PyIceberg | direct PyIceberg probe | n/a | PyIceberg can authenticate, list namespaces, and read tables such as `sql_server_covid19.us_states`, `sql_server_covid19.us`, and `sql_server_dbo.district`. It rejects some `aaron_fb_ads` tables because their metadata contains a custom statistics blob type `fivetran-synced-distribution`, while DuckDB reads those tables successfully. |
| Unity Catalog Iceberg REST | not configured | add a local-only catalog file | Cross-engine reads should work; DuckDB writes to UC remain blocked by open DuckDB Iceberg bugs. |
| Snowflake Horizon write | optional / disabled by default | `conference_catalog_demo_horizon` | Still requires the DuckDB-Iceberg Horizon write semantics patch. The write repro model stays opt-in with `ENABLE_HORIZON_WRITE_MODEL=true`. |

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
