{{ config(
    materialized='table',
    catalog_name='iceberg_demo',
    tags=['catalog_demo']
) }}

select
  4 as demo_order,
  'iceberg_rest' as catalog_name,
  'lakekeeper + minio' as storage_type
