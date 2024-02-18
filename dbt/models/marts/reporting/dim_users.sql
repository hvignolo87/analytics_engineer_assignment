SELECT
    id
    , username
FROM {{ ref('core_users') }}
