{{
    config(
        indexes=[
            {'columns': ['event_type', 'user_id']},
            {'columns': ['repo_id', 'commit_sha']},
            {'columns': ['repo_id', 'event_type']}
        ]
    )
}}

SELECT
    events.id AS event_id
    , events.type AS event_type
    , events.repo_id AS repo_id
    , commits.sha AS commit_sha
    , "users".id AS user_id
FROM {{ ref('int_events') }} AS events
LEFT JOIN {{ ref('int_repos') }} AS repos
    ON events.repo_id = repos.id
LEFT JOIN {{ ref('int_commits') }} AS commits
    ON events.id = commits.event_id
LEFT JOIN {{ ref('int_users') }} AS "users"
    ON events.user_id = "users".id
