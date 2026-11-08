{% macro amount_bucket(amount_column) %}
    multiIf(
        {{ amount_column }} < 100,
        'small',
        {{ amount_column }} < 1000,
        'medium',
        'large'
    )
{% endmacro %}
