-- ============================================================================
-- 08_native_installments.sql - Snowflake-only build: live installment feed without AWS.
-- Creates RAW.LIVE_INSTALLMENTS (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_INSTALLMENTS(N), which inserts synthetic
-- installment events with the same value ranges and ~10% MISSED rate as
-- aws/publish_installments.py. Rows are inserted directly; this simulates an
-- installment feed and is not Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_INSTALLMENTS).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_INSTALLMENTS (
  PORTFOLIO_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, AMOUNT_MYR FLOAT, DAYS_LATE FLOAT,
  STATUS VARCHAR, SENT_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_INSTALLMENTS(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_INSTALLMENTS (PORTFOLIO_ID, EVENT_TS, AMOUNT_MYR, DAYS_LATE, STATUS, SENT_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'PRT-' || LPAD(UNIFORM(0, 39, RANDOM())::VARCHAR, 4, '0') AS PORTFOLIO_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_MISSED,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs constant arguments, so the missed offset is applied outside it.
    SELECT PORTFOLIO_ID, TS,
           ROUND(IFF(IS_MISSED, 2400, 900) * EXP(NORMAL(0, 0.5, RANDOM())), 0),
           ROUND(IFF(IS_MISSED, 12, 0.3) * EXP(NORMAL(0, 0.4, RANDOM())), 0),
           IFF(IS_MISSED, 'MISSED', 'PAID'), TS, 'APP.SIMULATE_INSTALLMENTS'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_INSTALLMENTS
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_INSTALLMENTS(5);
