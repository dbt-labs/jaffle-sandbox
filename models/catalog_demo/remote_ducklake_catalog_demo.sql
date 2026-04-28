{{ config(
    materialized='table',
    catalog_name='jaffle_ducklake_remote_demo',
    tags=['catalog_demo']
) }}

select
  3 as demo_order,
  'remote_ducklake' as catalog_name,
  'motherduck' as storage_type
