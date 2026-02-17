{%- macro generate_record_hash(columns) -%}
    md5(
        concat_ws('|',
            {%- for col in columns %}
            coalesce(cast({{ col }} as string), '__null__')
            {%- if not loop.last -%},{%- endif %}
            {%- endfor %}
        )
    )
{%- endmacro -%}
