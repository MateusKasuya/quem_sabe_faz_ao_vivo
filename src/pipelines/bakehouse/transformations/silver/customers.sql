-- Silver: conformed customer dimension. Country is standardized with the same rule used
-- on silver.franchises so the two dimensions agree.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.customers (
  CONSTRAINT valid_customer_id EXPECT (customer_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_customer_name EXPECT (customer_name IS NOT NULL),
  CONSTRAINT valid_email EXPECT (email_address IS NULL OR email_address LIKE '%@%')
)
COMMENT 'Cleaned customer dimension with standardized country and a derived full name.'
TBLPROPERTIES ('quality' = 'silver')
AS
SELECT
  CAST(customerID AS BIGINT) AS customer_id,
  TRIM(first_name) AS first_name,
  TRIM(last_name) AS last_name,
  CONCAT_WS(' ', TRIM(first_name), TRIM(last_name)) AS customer_name,
  LOWER(TRIM(email_address)) AS email_address,
  TRIM(phone_number) AS phone_number,
  TRIM(city) AS city,
  TRIM(state) AS state,
  CASE
    WHEN UPPER(TRIM(country)) IN ('US', 'USA', 'U.S.', 'UNITED STATES') THEN 'USA'
    ELSE INITCAP(TRIM(country))
  END AS country,
  TRIM(continent) AS continent,
  CAST(postal_zip_code AS STRING) AS postal_zip_code,
  TRIM(gender) AS gender,
  _ingested_at
FROM STREAM ${medallion_catalog}.${bronze_schema}.customers;
