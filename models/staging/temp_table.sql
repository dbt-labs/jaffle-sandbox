{{ config(materialized='table') }}

SELECT
    1 as my_col,
    CURRENT_TIMESTAMP() as loaded_at