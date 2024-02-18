{{
    config(
        indexes=[
            {'columns': ['id', 'name']}
        ]
    )
}}

SELECT
    id
    , name
FROM {{ ref('int_repos') }}
