-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Digital Islamic Banking Intelligence
-- ============================================================================
USE DATABASE ISLAMIC_DIGITAL_BANKING;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.FEEDBACK_SEARCH
  ON FEEDBACK_TEXT
  ATTRIBUTES CHANNEL, SENTIMENT, PRODUCT, RATING
  WAREHOUSE = DIGITAL_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.CUSTOMER_FEEDBACK
);
