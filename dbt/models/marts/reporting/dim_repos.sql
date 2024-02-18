SELECT
    id
    , name
FROM {{ ref('core_repos') }}
