{{ config(
    materialized='table',
    schema='mart_rag'
) }}

SELECT
    community_id,
    community_name,

    major_category,
    middle_category,
    minor_category,

    poi_count,
    poi_count_500m,
    poi_count_1km,
    poi_count_3km,

    nearest_distance_m,
    avg_distance_m,
    semantic_group,
    impact_type,
    poi_semantic_description,
    poi_names,

    -- Category-level RAG text
    CONCAT(
        'Community: ', community_name, '. ',

        'Facility category: ',
        major_category, ' > ',
        middle_category, ' > ',
        minor_category, '. ',

        CAST(poi_count AS STRING),
        ' locations within 3 km. ',

        CAST(poi_count_500m AS STRING),
        ' within 500 m, ',

        CAST(poi_count_1km AS STRING),
        ' within 1 km. ',

        'Nearest location: ',
        CAST(ROUND(nearest_distance_m) AS STRING),
        ' meters away. ',

        'Average distance: ',
        CAST(ROUND(avg_distance_m) AS STRING),
        ' meters. ',

        CASE
            WHEN poi_semantic_description IS NOT NULL
            THEN CONCAT(
                'Distinctive characteristics: ',
                poi_semantic_description,
                '. '
            )
            ELSE ''
        END,

        'Representative locations: ',
        CONCAT_WS(', ', poi_names)
    ) AS rag_text

FROM {{ ref('int_community_poi_category') }}