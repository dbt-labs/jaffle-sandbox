-- This model references only the enabled source


select * from {{ source('source_enabled', 'source_enabled_table_enabled') }} 


