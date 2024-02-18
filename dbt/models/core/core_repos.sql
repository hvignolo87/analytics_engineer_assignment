{{
    generate_raw_data(
        relation=ref('stg_repos'),
        deduplicate=True
    )
}}

SELECT
    *
FROM final
