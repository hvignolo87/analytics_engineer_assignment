{{ generate_raw_data(relation=source('raw', 'repos')) }}

SELECT
    *
FROM final
