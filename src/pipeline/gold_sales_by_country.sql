-- Gold: revenue/orders per franchise country.
CREATE OR REFRESH MATERIALIZED VIEW gold_sales_by_country
COMMENT 'Revenue and orders per franchise country (gold)'
AS
SELECT
  franchise_country                         AS country,
  SUM(total_price)                          AS revenue,
  COUNT(*)                                  AS orders,
  COUNT(DISTINCT franchise_id)              AS franchises,
  CAST(AVG(total_price) AS DECIMAL(10,2))   AS avg_ticket
FROM silver_transactions
GROUP BY franchise_country;
