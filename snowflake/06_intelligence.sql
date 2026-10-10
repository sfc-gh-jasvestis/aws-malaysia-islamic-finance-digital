-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-arrears alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_INSTALLMENTS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic collections knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.ARREARS_DOCS AS
WITH types AS (
  SELECT DISTINCT r.ARREARS_REASON, a.CATEGORY
  FROM RAW.PORTFOLIO_DAILY r JOIN RAW.PORTFOLIOS a ON a.ID = r.ENTITY_ID
  WHERE r.ESCALATED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ARREARS_REASON)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ARREARS_REASON,
  CATEGORY || ' - ' || ARREARS_REASON || ' arrears handling' AS TITLE,
  'Synthetic demo SOP for a fictional bank. It does not state any regulatory or Shariah requirement. Financing product: ' || CATEGORY
  || '. Arrears reason: ' || ARREARS_REASON || '. '
  || 'Step 1: open an arrears case, link the missed installment and assign a collections officer within one working day. '
  || 'Step 2: ' || CASE
       WHEN ARREARS_REASON = 'Auto-debit insufficient balance' THEN 'compare the debit date with the customer''s usual income date, send a reminder through the mobile app, and offer a manual payment link before the next debit attempt.'
       WHEN ARREARS_REASON = 'Income disruption' THEN 'contact the customer to understand the change in income, record it in the case, and refer the customer to the restructuring desk to discuss rescheduling options under the bank''s approved policy and the product contract.'
       WHEN ARREARS_REASON = 'Customer unreachable' THEN 'try every registered contact channel over three working days, log each attempt, and ask the branch relationship officer to arrange a visit.'
       WHEN ARREARS_REASON = 'Business cash-flow shortfall' THEN 'request the latest cash-flow statement, compare it with the financing plan, and refer the case to the SME restructuring desk.'
       WHEN ARREARS_REASON = 'Leased asset downtime' THEN 'confirm the status of the leased asset and of any insurance claim, and record the asset condition in the case before the rental schedule is discussed.'
       WHEN ARREARS_REASON = 'Late business report' THEN 'request the overdue business performance report, because profit distribution under the mudarabah contract is calculated from reported business results, and escalate if it is not received within 10 working days.'
       ELSE 'review the case against the portfolio profile and escalate if unexplained.'
     END
  || ' Step 3: if the auto-debit rejection rate on the portfolio exceeds 5% or the average days past due exceeds 40 after triage, keep the case open and request a portfolio review. '
  || 'Step 4: record the resolution; if the case was escalated or missed its customer-contact SLA, log it for the collections report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.ARREARS_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ARREARS_REASON
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ARREARS_REASON, CONTENT FROM SEARCH.ARREARS_DOCS);

-- ---------- Auto-debit rejection rate anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.AUTODEBIT_REJECT_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, AUTODEBIT_REJECT_PCT::FLOAT AS AUTODEBIT_REJECT
FROM RAW.PORTFOLIO_DAILY;
CREATE OR REPLACE VIEW ML.AUTODEBIT_REJECT_TRAIN AS
SELECT * FROM ML.AUTODEBIT_REJECT_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.AUTODEBIT_REJECT_SERIES);
CREATE OR REPLACE VIEW ML.AUTODEBIT_REJECT_DETECT AS
SELECT * FROM ML.AUTODEBIT_REJECT_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.AUTODEBIT_REJECT_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.AUTODEBIT_REJECT_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.AUTODEBIT_REJECT_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'AUTODEBIT_REJECT',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.AUTODEBIT_REJECT_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS AUTODEBIT_REJECT, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.AUTODEBIT_REJECT_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.AUTODEBIT_REJECT_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'AUTODEBIT_REJECT'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.FINANCING_ANALYTICS
  TABLES (
    portfolios AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      COMMENT = 'One row per financing portfolio (one product in one city), 90-day totals',
    risk AS ML.ESCALATION_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day arrears escalation probability per portfolio',
    arrears AS CURATED.ARREARS_SUMMARY PRIMARY KEY (ARREARS_REASON)
      COMMENT = 'Arrears cases, escalations and contact SLA breaches by arrears reason, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Bank-wide totals per day'
  )
  RELATIONSHIPS (risk_portfolio AS risk (ENTITY_ID) REFERENCES portfolios)
  FACTS (
    portfolios.arrears_f AS ARREARS_COUNT,
    portfolios.escalated_f AS ESCALATED_COUNT,
    portfolios.breaches_f AS SLA_BREACH_COUNT,
    portfolios.installments_f AS INSTALLMENT_COUNT,
    portfolios.value_f AS VALUE_MYR,
    portfolios.review_due_f AS REVIEW_DUE,
    portfolios.review_done_f AS REVIEW_COMPLETED,
    risk.escalation_prob_f AS ESCALATION_PROB_7D,
    arrears.reason_arrears_f AS ARREARS_COUNT,
    arrears.reason_escalated_f AS ESCALATED_COUNT,
    arrears.reason_breaches_f AS SLA_BREACH_COUNT,
    arrears.reason_value_f AS EXPOSED_VALUE_MYR,
    daily.day_arrears_f AS ARREARS_COUNT,
    daily.day_escalated_f AS ESCALATED_COUNT,
    daily.day_value_f AS VALUE_MYR
  )
  DIMENSIONS (
    portfolios.portfolio_id AS ENTITY_ID WITH SYNONYMS = ('portfolio', 'financing portfolio', 'entity'),
    portfolios.portfolio_name AS ENTITY_NAME,
    portfolios.city AS REGION WITH SYNONYMS = ('city', 'region', 'branch network')
      COMMENT = 'Malaysian city where the portfolio is booked',
    portfolios.product AS CATEGORY WITH SYNONYMS = ('product', 'financing product', 'contract type')
      COMMENT = 'Tawarruq personal, SME murabahah, Musharakah mutanaqisah home, Ijarah equipment or Mudarabah working capital',
    portfolios.risk_tier AS RISK_TIER COMMENT = 'Customer risk grade 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    arrears.arrears_reason AS ARREARS_REASON WITH SYNONYMS = ('arrears reason', 'reason', 'cause'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    portfolios.portfolio_count AS COUNT(portfolios.portfolio_id)
      WITH SYNONYMS = ('number of portfolios', 'entities', 'number of entities'),
    portfolios.on_time_collection_pct AS 100 * (SUM(portfolios.installments_f) - SUM(portfolios.arrears_f)) / NULLIF(SUM(portfolios.installments_f), 0)
      WITH SYNONYMS = ('on-time collection rate', 'collection rate')
      COMMENT = 'Installments without an arrears case / installments due',
    portfolios.escalation_rate_pct AS 100 * SUM(portfolios.escalated_f) / NULLIF(SUM(portfolios.arrears_f), 0)
      COMMENT = 'Arrears cases escalated to restructuring review / arrears cases',
    portfolios.arrears_cases AS SUM(portfolios.arrears_f) WITH SYNONYMS = ('arrears', 'late installments'),
    portfolios.escalated_cases AS SUM(portfolios.escalated_f) WITH SYNONYMS = ('escalations', 'restructuring referrals'),
    portfolios.sla_breaches AS SUM(portfolios.breaches_f) WITH SYNONYMS = ('contact SLA misses'),
    portfolios.installments_due AS SUM(portfolios.installments_f),
    portfolios.total_value_myr AS SUM(portfolios.value_f) WITH SYNONYMS = ('scheduled value', 'value in MYR'),
    portfolios.review_compliance_pct AS 100 * SUM(portfolios.review_done_f) / NULLIF(SUM(portfolios.review_due_f), 0)
      COMMENT = 'Customer account reviews completed / reviews due',
    risk.avg_escalation_prob AS AVG(risk.escalation_prob_f),
    arrears.reason_arrears AS SUM(arrears.reason_arrears_f),
    arrears.reason_escalated AS SUM(arrears.reason_escalated_f),
    arrears.reason_breaches AS SUM(arrears.reason_breaches_f),
    arrears.reason_escalation_rate_pct AS 100 * SUM(arrears.reason_escalated_f) / NULLIF(SUM(arrears.reason_arrears_f), 0),
    daily.daily_arrears AS SUM(daily.day_arrears_f),
    daily.daily_escalated AS SUM(daily.day_escalated_f),
    daily.daily_value_myr AS SUM(daily.day_value_f)
  )
  COMMENT = 'Synthetic Malaysia digital Islamic bank financing collections analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.FINANCING_AGENT
  COMMENT = 'Collections assistant over a synthetic Malaysian digital Islamic bank financing book'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give portfolio IDs and numbers with units (MYR, %). Do not give religious or regulatory rulings."
  orchestration: "Use financing_analyst for installments, arrears cases, escalations, contact SLA breaches, on-time collection rate, account review compliance, portfolios, cities, financing products, arrears reasons and escalation risk. Use sop_search for arrears-handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: financing_analyst
      description: "Installments due, scheduled value in MYR, arrears cases, escalations to restructuring review, contact SLA breaches, on-time collection rate, account review compliance, arrears reasons and escalation risk scores by portfolio, city and financing product"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic arrears-handling SOPs by financing product and arrears reason"
tool_resources:
  financing_analyst:
    semantic_view: __DEMO_DB__.APP.FINANCING_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.ARREARS_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-arrears alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), PORTFOLIO_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_MYR FLOAT, DAYS_LATE FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION MY_ISLAMIC_FINANCE_DIGITAL_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (PORTFOLIO_ID, EVENT_TS, AMOUNT_MYR, DAYS_LATE, SOP_HINT)
    SELECT p.PORTFOLIO_ID, p.EVENT_TS, p.AMOUNT_MYR, p.DAYS_LATE,
           'Check ' || r.CATEGORY || ' arrears SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_INSTALLMENTS p
    JOIN RAW.PORTFOLIOS r ON r.ID = p.PORTFOLIO_ID
    LEFT JOIN ML.ESCALATION_RISK_SCORES s ON s.ENTITY_ID = p.PORTFOLIO_ID
    WHERE p.STATUS = 'MISSED'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.PORTFOLIO_ID = p.PORTFOLIO_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('MY_ISLAMIC_FINANCE_DIGITAL_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Missed installment alert',
      'New missed installments logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ARREARS_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_INSTALLMENTS p
    WHERE p.STATUS = 'MISSED'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.PORTFOLIO_ID = p.PORTFOLIO_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();
-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.ARREARS_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.ESCALATION_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.ESCALATION_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.ESCALATION_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'PORTFOLIO_AGE_YEARS', PORTFOLIO_AGE_YEARS,
             'AUTODEBIT_REJECT_PCT', AUTODEBIT_REJECT_PCT, 'AVG_DAYS_PAST_DUE', AVG_DAYS_PAST_DUE,
             'AUTODEBIT_REJECT_7D', AUTODEBIT_REJECT_7D, 'ESCALATED_30D', ESCALATED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:ESCALATED::FLOAT, 4) AS ESCALATION_PROB_7D,
         CASE WHEN PRED:probability:ESCALATED::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:ESCALATED::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
