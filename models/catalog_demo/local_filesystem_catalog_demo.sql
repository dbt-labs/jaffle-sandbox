{{ config(
    materialized='external',
    catalog_name='local_files',
    tags=['catalog_demo', 'capability_probe', 'catalog_local_filesystem', 'catalog_external_write_if_available']
) }}

select
  5 as demo_order,
  'local_filesystem' as catalog_name,
  'local csv source + parquet external model' as storage_type,
  count(*) as source_rows
from {{ source('local_files', 'raw_orders') }}
