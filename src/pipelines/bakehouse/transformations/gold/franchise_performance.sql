-- Gold: franchise scorecard. Grain: one row per franchise.
-- Carries city, country and lat/long so the dashboard map can plot revenue geographically
-- without joining back to the silver dimension.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.franchise_performance
COMMENT 'Per-franchise performance scorecard with geo coordinates and a revenue ranking.'
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  franchise_id,
  franchise_name,
  franchise_city AS city,
  franchise_country AS country,
  franchise_latitude AS latitude,
  franchise_longitude AS longitude,
  COUNT(*) AS total_orders,
  COUNT(DISTINCT customer_id) AS unique_customers,
  SUM(quantity) AS total_units,
  SUM(total_price) AS total_revenue,
  ROUND(AVG(total_price), 2) AS avg_ticket,
  MIN(transaction_date) AS first_sale_date,
  MAX(transaction_date) AS last_sale_date,
  DENSE_RANK() OVER (ORDER BY SUM(total_price) DESC) AS revenue_rank
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY
  franchise_id,
  franchise_name,
  franchise_city,
  franchise_country,
  franchise_latitude,
  franchise_longitude;
