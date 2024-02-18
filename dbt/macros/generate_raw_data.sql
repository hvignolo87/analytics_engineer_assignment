{%- macro generate_raw_data(relation, columns="*", deduplicate=False, partition_by=None, order_by=None) -%}

{%- if columns == "*" -%}
    {%- set columns = adapter.get_columns_in_relation(relation) | map(attribute="name") | list -%}
{%- endif -%}

WITH raw_data AS (
    SELECT
        {{ columns | join('\n\t\t, ') }}
    FROM {{ relation }}
)

{% if deduplicate -%}
    {%- set partition -%}
        {%- if partition_by -%}
            {{ partition_by | join(', ') }}
        {%- else -%}
            {{ columns | join(', ') }}
        {%- endif -%}
    {%- endset -%}

    {%- set order -%}
        {%- if order_by -%}
            {{ order_by | join(', ') }}
        {%- else -%}
            {{ columns | join(', ') }}
        {%- endif -%}
    {%- endset -%}

, deduped_raw_data AS(
    SELECT DISTINCT ON({{ partition }})
        {{ columns | join('\n\t\t, ') }}
    FROM raw_data
    ORDER BY {{ order }}
)
{%- endif %}

, final AS (
    SELECT
        *
    FROM {% if deduplicate -%} deduped_raw_data {%- else -%} raw_data {%- endif %}
)

{%- endmacro %}
