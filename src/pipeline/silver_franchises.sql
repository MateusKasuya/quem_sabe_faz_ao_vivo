-- Silver: cleaned franchises with standardized country ('US' -> 'USA') and typed geo.
CREATE OR REFRESH STREAMING TABLE silver_franchises (
  CONSTRAINT valid_franchise_id EXPECT (franchise_id IS NOT NULL) ON VIOLATION DROP ROW
)
COMMENT 'Cleaned franchises with standardized country and geo (silver)'
AS
SELECT
  franchiseID                                            AS franchise_id,
  name                                                   AS franchise_name,
  city                                                   AS city,
  district                                               AS district,
  CASE WHEN country = 'US' THEN 'USA' ELSE country END   AS country,
  size                                                   AS size,
  latitude                                               AS latitude,
  longitude                                              AS longitude,
  supplierID                                             AS supplier_id
FROM STREAM bronze_franchises;
