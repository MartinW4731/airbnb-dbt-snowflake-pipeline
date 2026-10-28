{% macro tag(column_name) %}
    case
        when {{ column_name }} < 100 then 'low'
        when {{ column_name }} < 200 then 'medium'
        else 'high'
    end
{% endmacro %}
