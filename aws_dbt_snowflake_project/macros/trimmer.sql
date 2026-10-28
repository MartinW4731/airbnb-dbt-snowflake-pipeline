{% macro trimmer(column_name) %}
    upper(trim({{ column_name }}))
{% endmacro %}
