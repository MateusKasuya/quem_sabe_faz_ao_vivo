-- Bronze: raw ingestion of free-text customer reviews from samples.bakehouse.
CREATE OR REFRESH STREAMING TABLE bronze_reviews
COMMENT 'Raw customer reviews ingested from samples.bakehouse.media_customer_reviews'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'samples.bakehouse.media_customer_reviews' AS _source_table
FROM STREAM samples.bakehouse.media_customer_reviews;
