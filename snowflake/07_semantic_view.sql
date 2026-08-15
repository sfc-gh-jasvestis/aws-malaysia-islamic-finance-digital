-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Digital Islamic Banking Intelligence
-- ============================================================================
USE DATABASE ISLAMIC_DIGITAL_BANKING;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.DIGITAL_BANKING_ANALYTICS
  COMMENT = 'Digital Islamic banking transaction, fraud, and customer analytics'
AS
  TABLES (
    CURATED.TRANSACTION_METRICS AS transaction_metrics,CURATED.FRAUD_ALERTS_LIVE AS fraud_alerts_live,CURATED.CUSTOMER_SEGMENTS AS customer_segments,CURATED.PRODUCT_PERFORMANCE AS product_performance
  );
