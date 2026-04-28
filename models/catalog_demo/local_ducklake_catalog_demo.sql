{{ config(
    materialized='table',
    catalog_name='jaffle_ducklake',
    tags=['catalog_demo']
) }}

select
  2 as demo_order,
  'local_ducklake' as catalog_name,
  'local ducklake metadata file' as storage_type
