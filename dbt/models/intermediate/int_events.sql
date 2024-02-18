SELECT
    id
    , type
    , actor_id AS user_id
    , repo_id
FROM {{ ref('stg_events') }}
