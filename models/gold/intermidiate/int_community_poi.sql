
{{ config(
    materialized='table',
    schema='gold_intermediate'
) }}

WITH poi_mapped AS (

    SELECT
        p.source_poi_id,
        p.poi_name,
        p.major_category,
        p.middle_category,

        -- Use English minor category name
        f.minor_category_en AS minor_category,

        p.longitude,
        p.latitude,
        p.address,

        -- Semantic attributes from the new minor-category seed
        f.semantic_group,
        f.search_relevance,
        f.relevance_weight,
        f.impact_type,
        f.is_core_category,
        -- Minor-category-specific semantic description for RAG
        f.poi_semantic_description

    FROM {{ source('dim_data', 'dim_poi') }} p

    -- Single source for filtering and semantic mapping
    INNER JOIN {{ ref('poi_minor_category_filter_seed_rag') }} f
        ON p.major_category = f.major_category
        AND p.middle_category = f.middle_category
        AND p.minor_category = f.minor_category
        AND f.keep_minor_category = true
        AND f.search_relevance = true
),

candidate_pairs AS (
    SELECT
        -- Community attributes
        c.community_id,
        c.community_name,
        c.longitude AS community_longitude,
        c.latitude AS community_latitude,
        -- POI attributes
        p.source_poi_id,
        p.poi_name,
        p.major_category,
        p.middle_category,
        p.minor_category,
        p.longitude AS poi_longitude,
        p.latitude AS poi_latitude,
        -- Semantic attributes
        p.semantic_group,
        p.relevance_weight,
        p.impact_type,
        p.poi_semantic_description,
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
