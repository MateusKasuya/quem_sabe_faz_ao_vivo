-- Silver: conformed franchise dimension.
--
-- Data quality note: the source stores the United States as 'US' on franchises but as
-- 'USA' on customers. Left alone, "revenue by country" would split the US in two and
-- country joins between the two dimensions would silently miss. Both sides are
-- standardized to 'USA' here.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${silver_schema}.franchises (
  CONSTRAINT valid_franchise_id EXPECT (franchise_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_franchise_name EXPECT (franchise_name IS NOT NULL),
  CONSTRAINT valid_country EXPECT (country IS NOT NULL),
  CONSTRAINT valid_coordinates EXPECT (
    latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180
  )
)
COMMENT 'Cleaned franchise dimension with standardized country and validated geo coordinates.'
TBLPROPERTIES ('quality' = 'silver')
AS
SELECT
  CAST(franchiseID AS BIGINT) AS franchise_id,
  CAST(supplierID AS BIGINT) AS supplier_id,
  TRIM(name) AS franchise_name,
  TRIM(city) AS city,
  TRIM(district) AS district,
  CAST(zipcode AS STRING) AS zipcode,
  CASE
    WHEN UPPER(TRIM(country)) IN ('US', 'USA', 'U.S.', 'UNITED STATES') THEN 'USA'
    ELSE INITCAP(TRIM(country))
  END AS country,
  TRIM(size) AS franchise_size,
  CAST(latitude AS DOUBLE) AS latitude,
  CAST(longitude AS DOUBLE) AS longitude,
  _ingested_at
FROM STREAM ${medallion_catalog}.${bronze_schema}.franchises;
