-- This model references only the enabled source
select * from {{ source('source_disabled', 'table_disabled') }} 