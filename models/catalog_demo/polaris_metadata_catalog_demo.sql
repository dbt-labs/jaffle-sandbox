{{ config(
    materialized='ephemeral',
    tags=['catalog_demo', 'capability_probe', 'catalog_polaris_metadata', 'catalog_metadata_read_verified']
) }}

select
  table_catalog,
  table_schema,
  table_name
from system.information_schema.tables
where table_catalog = 'polaris_demo'
