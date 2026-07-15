-- Silver: cleaned + enriched transactions.
-- Stream-static join enriches each transaction with its franchise (name, city, country,
-- geo) and customer (name, country). Money cast to DECIMAL(10,2), date columns derived,
-- country standardized (franchise 'US' -> 'USA'). Expectations reference OUTPUT aliases.
CREATE OR REFRESH STREAMING TABLE silver_transactions (
  CONSTRAINT valid_transaction_id EXPECT (transaction_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_total_price   EXPECT (total_price > 0)            ON VIOLATION DROP ROW,
  CONSTRAINT valid_quantity      EXPECT (quantity > 0)              ON VIOLATION DROP ROW
)
COMMENT 'Cleaned and franchise/customer-enriched transactions (silver)'
AS
SELECT
  t.transactionID                              AS transaction_id,
  t.customerID                                 AS customer_id,
  t.franchiseID                                AS franchise_id,
  t.dateTime                                   AS transaction_ts,
  CAST(t.dateTime AS DATE)                     AS transaction_date,
  YEAR(t.dateTime)                             AS transaction_year,
  MONTH(t.dateTime)                            AS transaction_month,
  DAY(t.dateTime)                              AS transaction_day,
  t.product                                    AS product,
  t.quantity                                   AS quantity,
  CAST(t.unitPrice AS DECIMAL(10,2))           AS unit_price,
  CAST(t.totalPrice AS DECIMAL(10,2))          AS total_price,
  t.paymentMethod                              AS payment_method,
  f.name                                       AS franchise_name,
  f.city                                       AS franchise_city,
  -- Standardize country: franchises store USA as 'US'; conform to 'USA'.
  CASE WHEN f.country = 'US' THEN 'USA' ELSE f.country END AS franchise_country,
  f.latitude                                   AS franchise_latitude,
  f.longitude                                  AS franchise_longitude,
  c.first_name                                 AS customer_first_name,
  c.last_name                                  AS customer_last_name,
  c.country                                    AS customer_country
FROM STREAM bronze_transactions t
LEFT JOIN bronze_franchises f ON t.franchiseID = f.franchiseID
LEFT JOIN bronze_customers c ON t.customerID = c.customerID;
