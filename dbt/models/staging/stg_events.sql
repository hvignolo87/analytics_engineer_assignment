{{ generate_raw_data(relation=source('raw', 'events')) }}

SELECT
    *
FROM final
