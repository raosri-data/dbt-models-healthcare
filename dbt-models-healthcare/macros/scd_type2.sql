-- macros/scd_type2.sql
{% macro scd_type2(source, target, business_key, effective_col, end_col) -%}
-- Example macro (conceptual)
select * from {{ source }}
{%- endmacro %}
