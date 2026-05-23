{{ config(
    materialized='table',
    tags=['catalog_demo', 'capability_probe', 'catalog_builtin', 'catalog_writable_expected']
) }}

select
  1 as demo_order,
  'builtin' as catalog_name,
  'local duckdb file' as storage_type
