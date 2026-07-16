-- Gold: country roll-up. Grain: one row per franchise country.
-- Only meaningful because silver already reconciled 'US' and 'USA' — without that step
-- the United States would appear as two separate countries here.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_country
COMMENT 'Revenue, orders and footprint per country (franchise country, standardized in silver).'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  franchise_country AS country,
  COUNT(DISTINCT franchise_id) AS active_franchises,
  COUNT(DISTINCT customer_id) AS unique_customers,
  COUNT(*) AS total_orders,
  SUM(quantity) AS total_units,
  SUM(total_price) AS total_revenue,
  ROUND(AVG(total_price), 2) AS avg_ticket,
  ROUND(100.0 * SUM(total_price) / SUM(SUM(total_price)) OVER (), 2) AS revenue_pct
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY franchise_country;
