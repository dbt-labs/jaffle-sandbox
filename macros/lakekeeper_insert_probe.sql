{% macro lakekeeper_insert_probe() %}
  {% call statement('lakekeeper_insert_probe') %}
    drop table if exists lakekeeper.default.lakekeeper_insert_probe;
    create table lakekeeper.default.lakekeeper_insert_probe (
      id integer,
      catalog_name varchar,
      storage_type varchar
    );
    insert into lakekeeper.default.lakekeeper_insert_probe
    values (1, 'iceberg_rest', 'lakekeeper + minio');
  {% endcall %}
{% endmacro %}
