-- Silver: free-text reviews scored with the built-in ai_analyze_sentiment function —
-- no model endpoint to deploy, no key to manage, it is just a SQL function.
--
-- It returns 'positive', 'negative', 'neutral' or 'mixed', and NULL when it cannot tell.
-- 'mixed' is easy to forget and is genuinely common in this dataset, so downstream gold
-- counts it explicitly instead of assuming a positive/negative/neutral trichotomy.
--
-- Materialized view rather than a streaming table: the scoring is a batch enrichment over
-- a small, static review set.
CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.reviews_sentiment (
  CONSTRAINT valid_review_id EXPECT (review_id IS NOT NULL),
  CONSTRAINT known_sentiment EXPECT (
    sentiment IS NULL OR sentiment IN ('positive', 'negative', 'neutral', 'mixed')
  )
)
COMMENT 'Customer reviews enriched with ai_analyze_sentiment (positive/negative/neutral/mixed).'
TBLPROPERTIES ('quality' = 'silver')
AS
SELECT
  CAST(r.new_id AS BIGINT) AS review_id,
  CAST(r.franchiseID AS BIGINT) AS franchise_id,
  TRIM(r.review) AS review,
  CAST(r.review_date AS DATE) AS review_date,
  YEAR(r.review_date) AS review_year,
  MONTH(r.review_date) AS review_month,
  ai_analyze_sentiment(r.review) AS sentiment,
  r._ingested_at
FROM ${medallion_catalog}.${bronze_schema}.reviews r
WHERE r.review IS NOT NULL
  AND LENGTH(TRIM(r.review)) > 0;
