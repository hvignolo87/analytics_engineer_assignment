{{
    config(
        indexes=[
            {'columns': ['id', 'username']}
        ]
    )
}}

SELECT
    id
    , username
FROM {{ ref('core_users') }}
