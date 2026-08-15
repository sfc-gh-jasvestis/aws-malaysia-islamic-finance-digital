-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Digital Islamic Banking Intelligence
-- ============================================================================
USE DATABASE ISLAMIC_DIGITAL_BANKING;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_SCORE_TRANSACTIONS
  WAREHOUSE = DIGITAL_WH
  SCHEDULE = 'USING CRON */15 * * * * UTC'
  COMMENT = 'Score new transactions for fraud probability'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_SEGMENT_CUSTOMERS
  WAREHOUSE = DIGITAL_WH
  AFTER APP.TASK_SCORE_TRANSACTIONS
  COMMENT = 'Update customer segments based on latest behavior'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_GENERATE_OFFERS
  WAREHOUSE = DIGITAL_WH
  AFTER APP.TASK_SEGMENT_CUSTOMERS
  COMMENT = 'Generate personalized Shariah-compliant product offers'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_GENERATE_OFFERS RESUME;
ALTER TASK APP.TASK_SEGMENT_CUSTOMERS RESUME;
ALTER TASK APP.TASK_SCORE_TRANSACTIONS RESUME;
