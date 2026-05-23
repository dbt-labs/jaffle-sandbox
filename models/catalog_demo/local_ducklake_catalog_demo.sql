{{ config(
    materialized='table',
    database='jaffle_ducklake',
    tags=['catalog_demo', 'capability_probe', 'catalog_local_ducklake', 'catalog_writable_expected']
) }}

select
  2 as demo_order,
  'local_ducklake' as catalog_name,
  'local ducklake metadata file' as storage_type
