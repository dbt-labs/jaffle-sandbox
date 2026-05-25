{{ config(
    enabled=env_var('ENABLE_UNITY_WRITE_MODEL', 'false') | as_bool,
    materialized='table',
    catalog='unity',
    schema=env_var('DATABRICKS_UC_SCHEMA', 'foo'),
    tags=['conference_catalog_demo', 'catalog_unity_write_proof']
) }}

select
  'unity' as sink_catalog,
  'duckdb_fusion' as writer,
  1::integer as proof_rows
