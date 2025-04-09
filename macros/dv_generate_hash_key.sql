{% macro dv_generate_hash_key(cols) %}
    -- Generates a surrogate hash key.
    --   cols : list of plain SQL snippets (strings), e.g.
    --          ['CAST(order_id AS STRING)', 'CAST(customer_id AS STRING)']

    md5(
        concat_ws(
            '|',
            {%- for c in cols -%}
                coalesce({{ c }}, '¬'){% if not loop.last %}, {% endif %}
            {%- endfor -%}
        )
    )
{% endmacro %}
