SELECT
    events.id AS event_id
    , events.type AS event_type
    , events.repo_id AS repo_id
    , commits.sha AS commit_sha
    , "users".id AS user_id
FROM {{ ref('core_events') }} AS events
LEFT JOIN {{ ref('core_repos') }} AS repos
    ON events.repo_id = repos.id
LEFT JOIN {{ ref('core_commits') }} AS commits
    ON events.id = commits.event_id
LEFT JOIN {{ ref('core_users') }} AS "users"
    ON events.user_id = "users".id