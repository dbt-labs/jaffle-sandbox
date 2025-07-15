-- This model references only the enabled source
select * from {{ source('source_enabled', 'table_enabled') }} 