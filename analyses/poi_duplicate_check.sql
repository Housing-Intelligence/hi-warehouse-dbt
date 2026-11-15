SELECT *
FROM housing_intelligence.processed.dim_poi
WHERE source_poi_id IN (
    SELECT source_poi_id
    FROM housing_intelligence.processed.dim_poi
    WHERE source_poi_id IS NOT NULL
    GROUP BY source_poi_id
    HAVING COUNT(*) > 1
)
ORDER BY source_poi_id;