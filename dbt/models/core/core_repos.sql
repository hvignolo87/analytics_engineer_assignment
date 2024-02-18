{{
    generate_raw_data(
        relation=ref('stg_repos'),
        deduplicate=True,
        partition_by=['id']
    )
}}

SELECT
    *
FROM final
