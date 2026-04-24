{{ config(
    materialized='table',
    tags=['catalog_demo']
) }}

select
  1 as demo_order,
  'builtin' as catalog_name,
  'local duckdb file' as storage_type
