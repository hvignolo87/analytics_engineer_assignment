{{
    generate_raw_data(
        relation=ref('stg_actors'),
        deduplicate=True,
        partition_by=['id']
    )
}}

SELECT
    *
FROM final
