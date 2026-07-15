-- Gold: franchise ranking with geo (for the map + ranking widgets).
CREATE OR REFRESH MATERIALIZED VIEW gold_franchise_performance
COMMENT 'Franchise performance ranking with city/country/geo (gold)'
AS
SELECT
  t.franchise_id,
  t.franchise_name,
  t.franchise_city,
  t.franchise_country,
  f.latitude,
  f.longitude,
  SUM(t.total_price)                        AS revenue,
  COUNT(*)                                  AS orders,
  SUM(t.quantity)                           AS units_sold,
  CAST(AVG(t.total_price) AS DECIMAL(10,2)) AS avg_ticket
FROM silver_transactions t
LEFT JOIN silver_franchises f ON t.franchise_id = f.franchise_id
GROUP BY t.franchise_id, t.franchise_name, t.franchise_city, t.franchise_country,
         f.latitude, f.longitude;
