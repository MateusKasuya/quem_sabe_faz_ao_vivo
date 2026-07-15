-- Silver: reviews enriched with AI sentiment.
-- Materialized view (batch) so ai_analyze_sentiment runs over the full review set.
-- ai_analyze_sentiment returns one of: positive / negative / neutral / mixed.
-- Isolated in its own MV: if the AI endpoint fails, the rest of the medallion still builds.
CREATE OR REFRESH MATERIALIZED VIEW silver_reviews_sentiment
COMMENT 'Customer reviews with AI-analyzed sentiment (silver)'
AS
SELECT
  new_id                          AS review_id,
  franchiseID                     AS franchise_id,
  review                          AS review_text,
  CAST(review_date AS DATE)       AS review_date,
  ai_analyze_sentiment(review)    AS sentiment
FROM bronze_reviews;
