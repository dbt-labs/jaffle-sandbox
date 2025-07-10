{{ config(materialized='view') }}
SELECT 1 as my_col FROM {{source("temp", "m1")}}
