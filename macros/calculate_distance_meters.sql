{% macro calculate_distance_meters(lat1, lon1, lat2, lon2) %}

    6371000 * 2 * ASIN(
        SQRT(
            LEAST(
                1.0,
                GREATEST(
                    0.0,
                    POWER(
                        SIN(
                            RADIANS({{ lat2 }} - {{ lat1 }}) / 2
                        ),
                        2
                    )
                    +
                    COS(RADIANS({{ lat1 }}))
                    * COS(RADIANS({{ lat2 }}))
                    * POWER(
                        SIN(
                            RADIANS({{ lon2 }} - {{ lon1 }}) / 2
                        ),
                        2
                    )
                )
            )
        )
    )

{% endmacro %}
