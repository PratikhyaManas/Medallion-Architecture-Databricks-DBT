{%- macro is_non_prod_environment() -%}
  {{ return(target.name in ['dev', 'ci', 'qa', 'test']) }}
{%- endmacro -%}

{%- macro should_mask_pii() -%}
  {{ return(var('mask_pii_in_non_prod', true) and is_non_prod_environment()) }}
{%- endmacro -%}

{%- macro tokenize_value(column_expression) -%}
  sha2(concat(cast({{ column_expression }} as string), '{{ var("pii_token_salt") }}'), 256)
{%- endmacro -%}

{%- macro mask_email(column_expression) -%}
  case
    when {{ column_expression }} is null then null
    else concat('masked_', substr({{ tokenize_value(column_expression) }}, 1, 12), '@example.invalid')
  end
{%- endmacro -%}
