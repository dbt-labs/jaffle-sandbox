{% macro anonymise_user_PII(model) %}

   UPDATE {{ model }}
    SET customer_id = SHA2_HEX(customer_id)
        , anonymised_at = current_timestamp()
    {% if model.identifier in ('customers','user_history') %}
        , first_name = 'ANONYMISED'
        , last_name = 'ANONYMISED'
    {% endif %}
          
    WHERE (LEN(customer_id) < 20) -- don't want to update id already encrypt


{% endmacro %}