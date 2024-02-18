{{ generate_raw_data(relation=source('raw', 'commits')) }}

SELECT
    *
FROM final
