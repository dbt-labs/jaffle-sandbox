# source freshness stuff w/ Martin

## to reproduce

1. for both `models/temp_view.sql` and `models/temp_table.sql` the below files:
   1. remove `.hide` from them
   2. execute `dbt run -s temp_view temp_table`
   3. add `.hide` back so dbt thinks of them as sources
2. `dbt source freshness`


