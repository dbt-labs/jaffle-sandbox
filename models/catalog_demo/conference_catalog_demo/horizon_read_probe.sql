{{ config(
    enabled=env_var('ENABLE_HORIZON_READ_MODEL', 'false') | as_bool,
    materialized='table',
    catalog='lakekeeper',
    schema='default',
    tags=['conference_catalog_demo', 'catalog_horizon_read']
) }}

select
  'horizon' as source_catalog,
  'lakekeeper' as sink_catalog,
  count(*)::integer as source_rows
from {{ source('horizon_managed', 'managed_table') }}
