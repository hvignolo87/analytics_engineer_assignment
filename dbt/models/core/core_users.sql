{{
    generate_raw_data(
        relation=ref('stg_actors'),
        deduplicate=True
    )
}}

SELECT
    *
FROM final
