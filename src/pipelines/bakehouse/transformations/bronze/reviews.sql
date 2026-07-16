-- Bronze: raw free-text customer reviews (204 rows). Sentiment is derived in silver.
CREATE OR REFRESH STREAMING TABLE ${medallion_catalog}.${bronze_schema}.reviews
COMMENT 'Raw customer reviews ingested from ${source_catalog}.${source_schema}.media_customer_reviews.'
TBLPROPERTIES ('quality' = 'bronze')
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  '${source_catalog}.${source_schema}.media_customer_reviews' AS _source_table
FROM STREAM ${source_catalog}.${source_schema}.media_customer_reviews;
