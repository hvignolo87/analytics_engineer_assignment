SELECT
    sha
    , message
    , event_id
FROM {{ ref('core_commits') }}
