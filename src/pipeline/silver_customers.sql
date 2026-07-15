-- Silver: cleaned customers (country already 'USA'/'Australia'/'Japan' — kept as-is).
CREATE OR REFRESH STREAMING TABLE silver_customers (
  CONSTRAINT valid_customer_id EXPECT (customer_id IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT 'Cleaned customers (silver)'
AS
SELECT
  customerID     AS customer_id,
  first_name     AS first_name,
  last_name      AS last_name,
  email_address  AS email_address,
  city           AS city,
  state          AS state,
  country        AS country,
  continent      AS continent,
  gender         AS gender
FROM STREAM bronze_customers;
