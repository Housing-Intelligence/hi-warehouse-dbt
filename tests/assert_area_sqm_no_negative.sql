SELECT 
* 
FROM 
{{ source('landing', 'sales_data') }}
WHERE area_sqm < 0 or listing_price_wan < 0