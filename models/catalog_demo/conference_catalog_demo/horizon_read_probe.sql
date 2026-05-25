{{ config(
    enabled=env_var('ENABLE_HORIZON_READ_MODEL', 'false') | as_bool,
    materialized='table',
    catalog_name='iceberg_demo',
    schema='default',
    tags=['conference_catalog_demo', 'catalog_horizon_read']
) }}

select
  'horizon_demo' as source_catalog,
  'iceberg_demo' as sink_catalog,
  count(*)::integer as source_rows
from {{ source('horizon_demo', 'MANAGED_TABLE') }}
