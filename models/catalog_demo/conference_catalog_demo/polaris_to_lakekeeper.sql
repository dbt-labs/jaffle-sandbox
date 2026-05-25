{{ config(
    materialized='table',
    catalog_name='iceberg_demo',
    schema='default',
    tags=['conference_catalog_demo', 'catalog_polaris_source', 'catalog_lakekeeper_write']
) }}

select
  'polaris_demo' as source_catalog,
  'iceberg_demo' as sink_catalog,
  count(*)::integer as source_rows
from {{ source('polaris_covid', 'us_states') }}
