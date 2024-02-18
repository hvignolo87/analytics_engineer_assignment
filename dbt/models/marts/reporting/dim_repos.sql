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
FROM {{ ref('core_repos') }}
