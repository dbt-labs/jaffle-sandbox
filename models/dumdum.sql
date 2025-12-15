
{{
    config(
        materialized = 'table',
        catalog_name = 'fusion_dev'
    )
}}

SELECT 1 as my_col;