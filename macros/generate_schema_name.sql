{% macro generate_schema_name(custom_schema_name, node) -%}
  {%- set catalog_name = node.config.get('catalog') or node.config.get('catalog_name') -%}
  {%- if catalog_name not in [none, 'builtin', 'none'] and custom_schema_name is not none -%}
    {{ custom_schema_name | trim }}
  {%- elif custom_schema_name is none -%}
    {{ target.schema }}
  {%- else -%}
    {{ target.schema }}_{{ custom_schema_name | trim }}
  {%- endif -%}
{%- endmacro %}
