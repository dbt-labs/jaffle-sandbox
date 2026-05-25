{{ config(
    enabled=env_var('ENABLE_HORIZON_WRITE_MODEL', 'false') | as_bool,
    materialized='table',
    catalog_name='horizon_demo',
    schema=env_var('HORIZON_DEFAULT_SCHEMA', 'DEMO'),
    contract={'enforced': true},
    tags=['conference_catalog_demo', 'catalog_polaris_source', 'catalog_horizon_write_repro']
) }}

select
  'polaris_demo' as source_catalog,
  'horizon_demo' as sink_catalog,
  count(*)::integer as source_rows
from {{ source('polaris_covid', 'us_states') }}
