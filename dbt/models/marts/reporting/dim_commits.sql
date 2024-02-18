SELECT
    sha
    , message
    , event_id
FROM {{ ref('int_commits') }}
