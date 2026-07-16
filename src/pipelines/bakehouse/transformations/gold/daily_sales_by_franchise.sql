-- Gold: the daily sales fact mart.
--
-- Grain: one row per (sale_date, franchise_id, payment_method). Keeping payment_method as
-- a dimension here — rather than aggregating it away — lets this single mart drive the KPI
-- tiles, the daily revenue trend AND the payment mix. It stays tiny (17 days x 48
-- franchises x 3 methods at most).
--
-- avg_ticket is the average at THIS grain. When rolling up, recompute it as
-- SUM(total_revenue) / SUM(total_orders) — averaging an average would weight each row equally.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.daily_sales_by_franchise
COMMENT 'Daily sales by franchise and payment method. Grain: (sale_date, franchise_id, payment_method).'
CLUSTER BY (sale_date)
TBLPROPERTIES ('quality' = 'gold')
AS
SELECT
  transaction_date AS sale_date,
  transaction_year AS sale_year,
  transaction_month AS sale_month,
  transaction_day_of_week AS day_of_week,
  franchise_id,
  franchise_name,
  franchise_city AS city,
  franchise_country AS country,
  payment_method,
  COUNT(*) AS total_orders,
  SUM(quantity) AS total_units,
  SUM(total_price) AS total_revenue,
  ROUND(AVG(total_price), 2) AS avg_ticket
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY
  transaction_date,
  transaction_year,
  transaction_month,
  transaction_day_of_week,
  franchise_id,
  franchise_name,
  franchise_city,
  franchise_country,
  payment_method;
