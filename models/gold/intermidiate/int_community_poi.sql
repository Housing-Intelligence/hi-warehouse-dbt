{{ config(
    materialized='table',
    schema='gold_intermediate'
) }}

WITH poi_mapped AS (

    SELECT
        p.*,

        COALESCE(m.semantic_group, 'OTHER_EXCLUDED')
            AS semantic_group,

        COALESCE(m.search_relevance, false)
            AS search_relevance,

        COALESCE(m.relevance_weight, 0)
            AS relevance_weight,

        COALESCE(m.impact_type, 'NEUTRAL')
            AS impact_type,

        COALESCE(m.is_core_category, false)
            AS is_core_category,

        m.mapping_note

    FROM {{ source('dim_data', 'dim_poi') }} p

    LEFT JOIN {{ ref('poi_semantic_category_mapping') }} m
        ON p.major_category = m.major_category
        AND p.middle_category = m.middle_category

),

candidate_pairs AS (

    SELECT
        -- Community attributes
        c.community_id,
        c.community_name,
        c.subdistrict,
        c.business_area,
        c.longitude AS community_longitude,
        c.latitude AS community_latitude,
        c.avg_price,
        c.living_quality_score,
        c.environment_score,
        c.commerce_score,
        c.education_score,
        c.transport_score,
        p.source_poi_id,
        p.poi_name,
        p.major_category,
        p.middle_category,
        p.minor_category,
        p.longitude AS poi_longitude,
        p.latitude AS poi_latitude,
        p.address AS poi_address,
        p.semantic_group,
        p.search_relevance,
        p.relevance_weight,
        p.impact_type,
        p.is_core_category,
        p.mapping_note,

        -- Haversine distance in meters
        {{ calculate_distance_meters(
            'c.latitude',
            'c.longitude',
            'p.latitude',
            'p.longitude'
        ) }} AS distance_m

    FROM {{ source('dim_data', 'community_transform') }} c

    INNER JOIN poi_mapped p

        ON p.latitude BETWEEN
            c.latitude - (3000 / 111320.0)
            AND c.latitude + (3000 / 111320.0)

        AND p.longitude BETWEEN
            c.longitude - (
                3000 / (
                    111320.0 * COS(RADIANS(c.latitude))
                )
            )
            AND c.longitude + (
                3000 / (
                    111320.0 * COS(RADIANS(c.latitude))
                )
            )
),

community_poi AS (
    SELECT *
    FROM candidate_pairs
    WHERE distance_m <= 3000
)

SELECT *,
    CASE
        WHEN distance_m <= 500 THEN '0_500M'
        WHEN distance_m <= 1000 THEN '500M_1KM'
        WHEN distance_m <= 3000 THEN '1KM_3KM'
    END AS distance_band,

    distance_m <= 500 AS within_500m,
    distance_m <= 1000 AS within_1km,
    distance_m <= 3000 AS within_3km

FROM community_poi