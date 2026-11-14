SELECT
    date,
    floor
FROM{{ ref('bronze_orders') }}