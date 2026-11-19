{{ config(
    materialized='table',
    schema='gold_intermediate'
) }}

SELECT
    community_id,
    community_name,

    major_category,
    middle_category,
    minor_category,

    semantic_group,
    impact_type,
    poi_semantic_description,

    -- Total number of unique POIs
    COUNT(DISTINCT source_poi_id) AS poi_count,

    -- POI counts by distance
    COUNT(DISTINCT CASE
        WHEN distance_m <= 500 THEN source_poi_id
    END) AS poi_count_500m,

    COUNT(DISTINCT CASE
        WHEN distance_m <= 1000 THEN source_poi_id
    END) AS poi_count_1km,

    COUNT(DISTINCT CASE
        WHEN distance_m <= 3000 THEN source_poi_id
    END) AS poi_count_3km,

    -- Distance statistics
    MIN(distance_m) AS nearest_distance_m,
    AVG(distance_m) AS avg_distance_m,

    -- Representative POI names
    SLICE(
        ARRAY_SORT(COLLECT_SET(poi_name)),
        1,
        5
    ) AS poi_names,

    -- Number of POIs within each distance band
    COUNT(DISTINCT CASE
        WHEN distance_band = '0_500M' THEN source_poi_id
    END) AS count_0_500m,

    COUNT(DISTINCT CASE
        WHEN distance_band = '500M_1KM' THEN source_poi_id
    END) AS count_500m_1km,

    COUNT(DISTINCT CASE
        WHEN distance_band = '1KM_3KM' THEN source_poi_id
    END) AS count_1km_3km

FROM {{ ref('int_community_poi') }}

GROUP BY
    community_id,
    community_name,
    major_category,
    middle_category,
    minor_category,
    semantic_group,
    impact_type,
    poi_semantic_description