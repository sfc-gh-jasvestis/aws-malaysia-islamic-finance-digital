-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Digital Islamic Banking Intelligence
-- ============================================================================
USE DATABASE ISLAMIC_DIGITAL_BANKING;
USE SCHEMA CURATED;

-- TRANSACTION_METRICS: Real-time transaction volume, value, and STP rate aggregations
-- Source: TRANSACTIONS
CREATE OR REPLACE DYNAMIC TABLE CURATED.TRANSACTION_METRICS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = DIGITAL_WH
AS
SELECT * FROM RAW.TRANSACTIONS;
-- TODO: Replace with actual join/aggregation logic per demo

-- FRAUD_ALERTS_LIVE: Live fraud alert feed with ML scores and account context
-- Source: TRANSACTIONS, ALERTS, ACCOUNTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.FRAUD_ALERTS_LIVE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = DIGITAL_WH
AS
SELECT * FROM RAW.TRANSACTIONS;
-- TODO: Replace with actual join/aggregation logic per demo

-- CUSTOMER_SEGMENTS: Customer segmentation by behavior, product usage, and risk profile
-- Source: ACCOUNTS, TRANSACTIONS, PRODUCTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.CUSTOMER_SEGMENTS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = DIGITAL_WH
AS
SELECT * FROM RAW.ACCOUNTS;
-- TODO: Replace with actual join/aggregation logic per demo

-- PRODUCT_PERFORMANCE: Product conversion, adoption, and revenue metrics
-- Source: PRODUCTS, TRANSACTIONS, ACCOUNTS
CREATE OR REPLACE DYNAMIC TABLE CURATED.PRODUCT_PERFORMANCE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = DIGITAL_WH
AS
SELECT * FROM RAW.PRODUCTS;
-- TODO: Replace with actual join/aggregation logic per demo

