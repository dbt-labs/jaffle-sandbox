{{ config(
    materialized='table',
    catalog='lakekeeper',
    schema='default',
    tags=['conference_catalog_demo', 'catalog_polaris_source', 'catalog_lakekeeper_write']
) }}

select
  'polaris' as source_catalog,
  'lakekeeper' as sink_catalog,
  count(*)::integer as source_rows
from {{ source('polaris_covid', 'us_states') }}
