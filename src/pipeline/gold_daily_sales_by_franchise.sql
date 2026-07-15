-- Gold: daily revenue/orders per franchise (time series for the dashboard).
CREATE OR REFRESH MATERIALIZED VIEW gold_daily_sales_by_franchise
COMMENT 'Daily revenue and orders per franchise (gold)'
AS
SELECT
  transaction_date,
  franchise_id,
  franchise_name,
  franchise_country,
  SUM(total_price)              AS revenue,
  COUNT(*)                      AS orders,
  SUM(quantity)                 AS units_sold
FROM silver_transactions
GROUP BY transaction_date, franchise_id, franchise_name, franchise_country;
