{{ config(static_analysis='unsafe') }}

{% set sku_list = dbt_utils.get_column_values(
            table=ref('imaginary_table'),
            column='sku'
            ) -%}
        {%- for sku in sku_list %}
            {%set sku = sku | replace("SKU","") %}
                select
                    {{ sku }} as sku
                from {{ ref('random_skus') }}
            {%- if not loop.last %}
                union all
            {%- endif -%}
        {% endfor %}