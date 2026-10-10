-- Synthetic portfolio-day observations for a fictional Malaysian digital Islamic bank.
-- A portfolio is one financing product booked in one city branch network.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild
-- is reproducible: per-portfolio arrears propensity, drift between customer
-- account reviews, missed reviews, product-weighted arrears reasons, arrears
-- cases resolved without escalation, and two city-wide payment channel disruptions.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.PORTFOLIOS AS
WITH portfolios AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS PORTFOLIO_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT PORTFOLIO_INDEX,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-review')), 1000000) / 1e6 AS U_REVIEW,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(PORTFOLIO_INDEX, 'my-tier')), 1000000) / 1e6 AS U_TIER
  FROM portfolios
)
SELECT 'PRT-' || LPAD(PORTFOLIO_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic portfolio ' || LPAD(PORTFOLIO_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every city and product
       -- is present. All portfolios are booked in Malaysia (MYR).
       CASE MOD(PORTFOLIO_INDEX, 5) WHEN 0 THEN 'Kuala Lumpur' WHEN 1 THEN 'Johor Bahru'
            WHEN 2 THEN 'George Town' WHEN 3 THEN 'Kota Kinabalu' ELSE 'Kuching' END AS REGION,
       CASE MOD(PORTFOLIO_INDEX, 8) WHEN 0 THEN 'Tawarruq personal' WHEN 1 THEN 'Tawarruq personal'
            WHEN 2 THEN 'Tawarruq personal' WHEN 3 THEN 'SME murabahah' WHEN 4 THEN 'SME murabahah'
            WHEN 5 THEN 'Musharakah mutanaqisah home' WHEN 6 THEN 'Ijarah equipment'
            ELSE 'Mudarabah working capital' END AS CATEGORY,
       PORTFOLIO_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.2 + U_AGE * 5.8, 1) AS PORTFOLIO_AGE_YEARS,
       -- Base daily probability of an escalated arrears case 0.4%-3%; ~15% of
       -- portfolios are chronically weak (x3).
       (0.004 + U_RATE * 0.026) * IFF(U_RATE > 0.85, 3, 1) AS BASE_ESCALATION_RATE,
       7 * (1 + FLOOR(U_REVIEW * 3)) AS REVIEW_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS REVIEW_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.PORTFOLIO_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide payment channel disruptions; every portfolio in the city
  -- raises an arrears case that resolves once the channel recovers.
  SELECT * FROM VALUES (33, 'Johor Bahru'), (71, 'Kuching') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT r.ID AS ENTITY_ID, r.PORTFOLIO_INDEX, r.CATEGORY, r.REGION, r.PORTFOLIO_AGE_YEARS,
         r.BASE_ESCALATION_RATE, r.REVIEW_INTERVAL_DAYS, r.REVIEW_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + r.PORTFOLIO_INDEX * 5, r.REVIEW_INTERVAL_DAYS) AS DAYS_SINCE_REVIEW,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-fail')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-clear')), 1000000) / 1e6 AS U_CLEAR,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'my-sla')), 1000000) / 1e6 AS U_SLA,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.PORTFOLIOS r CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = r.REGION
), review AS (
  SELECT *,
         IFF(DAYS_SINCE_REVIEW = 0, 1, 0) AS REVIEW_DUE,
         IFF(DAYS_SINCE_REVIEW = 0 AND U_DONE < REVIEW_COMPLETION_PROB, 1, 0) AS REVIEW_COMPLETED,
         -- Early-warning drift rises between customer account reviews; weak
         -- review discipline carries it over.
         DAYS_SINCE_REVIEW / REVIEW_INTERVAL_DAYS + (1 - REVIEW_COMPLETION_PROB) AS DRIFT
  FROM base
), stress AS (
  SELECT *,
         CASE WHEN U_FAIL < LEAST(0.5, BASE_ESCALATION_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PORTFOLIO_AGE_YEARS))) / 4 THEN 2
              WHEN U_FAIL < LEAST(0.5, BASE_ESCALATION_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PORTFOLIO_AGE_YEARS))) THEN 1
              ELSE 0 END AS STRESS_COUNT
  FROM review
), cases AS (
  SELECT *,
         -- About 85% of stressed accounts are opened as arrears cases and
         -- escalated to restructuring review; the rest catch up without a case.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.85, STRESS_COUNT, 0)) AS ESCALATED_COUNT,
         -- Arrears cases resolved by the collections team without escalation.
         IFF(CITY_EVENT, 1, IFF(U_CLEAR < CASE CATEGORY WHEN 'Musharakah mutanaqisah home' THEN 0.20
                                                      WHEN 'Ijarah equipment' THEN 0.12
                                                      WHEN 'Mudarabah working capital' THEN 0.14 ELSE 0.08 END, 1, 0)) AS RESOLVED_COUNT
  FROM stress
), measured AS (
  SELECT *,
         ESCALATED_COUNT + RESOLVED_COUNT AS ARREARS_COUNT,
         ROUND(CASE CATEGORY WHEN 'Tawarruq personal' THEN 420 WHEN 'SME murabahah' THEN 60
                             WHEN 'Musharakah mutanaqisah home' THEN 150 WHEN 'Ijarah equipment' THEN 45 ELSE 12 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.8 * STRESS_COUNT)) AS INSTALLMENT_COUNT,
         CASE CATEGORY WHEN 'Tawarruq personal' THEN 650 WHEN 'SME murabahah' THEN 4800
                       WHEN 'Musharakah mutanaqisah home' THEN 1900 WHEN 'Ijarah equipment' THEN 2400
                       ELSE 22000 END
           * (0.8 + 0.4 * U_NOISE) AS AVG_INSTALLMENT_MYR
  FROM cases
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       INSTALLMENT_COUNT,
       ROUND(INSTALLMENT_COUNT * AVG_INSTALLMENT_MYR, 0) AS VALUE_MYR,
       ARREARS_COUNT, ESCALATED_COUNT,
       IFF(ESCALATED_COUNT > 0 AND U_SLA < 0.6, 1, 0) AS SLA_BREACHED,
       CASE WHEN ARREARS_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Payment channel disruption'
            WHEN CATEGORY = 'Tawarruq personal' THEN IFF(U_TYPE < 0.5, 'Auto-debit insufficient balance', IFF(U_TYPE < 0.8, 'Income disruption', 'Customer unreachable'))
            WHEN CATEGORY = 'SME murabahah' THEN IFF(U_TYPE < 0.45, 'Business cash-flow shortfall', IFF(U_TYPE < 0.8, 'Auto-debit insufficient balance', 'Customer unreachable'))
            WHEN CATEGORY = 'Musharakah mutanaqisah home' THEN IFF(U_TYPE < 0.55, 'Auto-debit insufficient balance', 'Income disruption')
            WHEN CATEGORY = 'Ijarah equipment' THEN IFF(U_TYPE < 0.45, 'Leased asset downtime', IFF(U_TYPE < 0.8, 'Business cash-flow shortfall', 'Customer unreachable'))
            ELSE IFF(U_TYPE < 0.5, 'Business cash-flow shortfall', IFF(U_TYPE < 0.75, 'Late business report', 'Customer unreachable')) END AS ARREARS_REASON,
       REVIEW_DUE, REVIEW_COMPLETED,
       ROUND(0.5 + 2.0 * DRIFT + 3.0 * STRESS_COUNT + U_NOISE * 0.8, 2) AS AUTODEBIT_REJECT_PCT,
       ROUND(18 + 12 * DRIFT + 14 * STRESS_COUNT + U_NOISE * 6, 1) AS AVG_DAYS_PAST_DUE,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Financing file document coverage per portfolio (snapshot).
CREATE TABLE RAW.FINANCING_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Tawarruq personal' THEN 'Tawarruq contract and cost disclosure'
                     WHEN 'SME murabahah' THEN 'Business financial statements'
                     WHEN 'Musharakah mutanaqisah home' THEN 'Property valuation report'
                     WHEN 'Ijarah equipment' THEN 'Leased asset insurance certificate'
                     ELSE 'Business performance report' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'my-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'my-file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'my-file')), 5) < 1 + MOD(ABS(HASH(ID, 'my-req')), 4),
           MOD(ABS(HASH(ID, 'my-pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.PORTFOLIOS;
