-- Silver: the fact table. Bronze transactions are typed, given derived date parts, and
-- enriched with the franchise and customer dimensions (a stream-static join: the fact
-- side streams, the dimensions are read as static snapshots).
--
-- cardNumber is intentionally NOT carried over from bronze — raw card numbers have no
-- place in an analytics layer.
--
-- Expectations reference the OUTPUT column names (total_price, not totalPrice). Naming
-- the source column here fails at pipeline run time with UNRESOLVED_COLUMN, not at deploy.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.transactions (
  CONSTRAINT valid_transaction_id EXPECT (transaction_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT positive_quantity EXPECT (quantity > 0) ON VIOLATION DROP ROW,
  CONSTRAINT positive_total_price EXPECT (total_price > 0) ON VIOLATION DROP ROW,
  CONSTRAINT valid_payment_method EXPECT (payment_method IN ('visa', 'mastercard', 'amex')),
  CONSTRAINT known_franchise EXPECT (franchise_name IS NOT NULL),
  CONSTRAINT known_customer EXPECT (customer_name IS NOT NULL)
)
COMMENT 'Cleaned transactions enriched with franchise and customer attributes.'
CLUSTER BY (transaction_date, franchise_id)
TBLPROPERTIES ('quality' = 'silver')
AS
SELECT
  CAST(t.transactionID AS BIGINT) AS transaction_id,
  CAST(t.customerID AS BIGINT) AS customer_id,
  CAST(t.franchiseID AS BIGINT) AS franchise_id,

  -- Derived date parts: the source only carries a raw timestamp.
  t.dateTime AS transaction_ts,
  CAST(t.dateTime AS DATE) AS transaction_date,
  YEAR(t.dateTime) AS transaction_year,
  MONTH(t.dateTime) AS transaction_month,
  DAY(t.dateTime) AS transaction_day,
  DATE_FORMAT(t.dateTime, 'yyyy-MM') AS transaction_year_month,
  DATE_FORMAT(t.dateTime, 'EEEE') AS transaction_day_of_week,

  TRIM(t.product) AS product,
  CAST(t.quantity AS INT) AS quantity,
  CAST(t.unitPrice AS DECIMAL(10, 2)) AS unit_price,
  CAST(t.totalPrice AS DECIMAL(10, 2)) AS total_price,
  LOWER(TRIM(t.paymentMethod)) AS payment_method,

  f.franchise_name,
  f.city AS franchise_city,
  f.country AS franchise_country,
  f.latitude AS franchise_latitude,
  f.longitude AS franchise_longitude,

  c.customer_name,
  c.country AS customer_country,
  c.gender AS customer_gender,

  t._ingested_at
FROM STREAM ${medallion_catalog}.${bronze_schema}.transactions t
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises f
  ON CAST(t.franchiseID AS BIGINT) = f.franchise_id
LEFT JOIN ${medallion_catalog}.${silver_schema}.customers c
  ON CAST(t.customerID AS BIGINT) = c.customer_id;
