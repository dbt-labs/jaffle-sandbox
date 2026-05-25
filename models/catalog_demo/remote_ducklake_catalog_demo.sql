{{ config(
    materialized='table',
    catalog='ducklake',
    tags=['catalog_demo', 'capability_probe', 'catalog_remote_ducklake', 'catalog_writable_expected']
) }}

select
  3 as demo_order,
  'remote_ducklake' as catalog_name,
  'motherduck' as storage_type
