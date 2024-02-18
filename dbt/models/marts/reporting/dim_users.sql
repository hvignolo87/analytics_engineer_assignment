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
FROM {{ ref('int_users') }}
