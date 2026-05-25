{{ config(
    materialized='table',
    catalog='ducklake',
    tags=['catalog_demo', 'capability_probe', 'catalog_local_ducklake', 'catalog_writable_expected']
) }}

select
  2 as demo_order,
  'ducklake' as catalog_name,
  'local ducklake metadata file' as storage_type
