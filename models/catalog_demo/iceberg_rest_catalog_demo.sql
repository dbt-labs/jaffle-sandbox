{{ config(
    materialized='table',
    catalog='lakekeeper',
    tags=['catalog_demo', 'capability_probe', 'catalog_iceberg_rest', 'catalog_writable_expected']
) }}

select
  4 as demo_order,
  'lakekeeper' as catalog_name,
  'lakekeeper + minio' as storage_type
