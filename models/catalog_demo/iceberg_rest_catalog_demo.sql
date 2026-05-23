{{ config(
    materialized='table',
    database='iceberg_demo',
    tags=['catalog_demo', 'capability_probe', 'catalog_iceberg_rest', 'catalog_writable_expected']
) }}

select
  4 as demo_order,
  'iceberg_rest' as catalog_name,
  'lakekeeper + minio' as storage_type
