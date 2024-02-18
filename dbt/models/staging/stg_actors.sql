{{
    generate_raw_data(
        relation=source('raw', 'actors'),
        columns=["id", "username"]
    )
}}

SELECT
    *
FROM final
