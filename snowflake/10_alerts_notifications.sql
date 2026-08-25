-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Digital Islamic Banking Intelligence
-- ============================================================================
USE DATABASE ISLAMIC_DIGITAL_BANKING;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_malaysia_islamic_finance_digital_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: SUSPICIOUS_TRANSACTION_ALERT
CREATE OR REPLACE ALERT APP.SUSPICIOUS_TRANSACTION_ALERT
  WAREHOUSE = DIGITAL_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Suspicious high-value transaction detected'
IF (EXISTS (
  SELECT 1 FROM CURATED.TRANSACTION_METRICS
  WHERE 1=1 -- Condition: Transaction anomaly score > 0.9 and amount > RM 10,000
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_islamic_finance_digital_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Digital Islamic Banking Intelligence: Suspicious high-value transaction detected',
    'Suspicious high-value transaction detected'
  );

ALTER ALERT APP.SUSPICIOUS_TRANSACTION_ALERT RESUME;

-- Alert: VELOCITY_ANOMALY_ALERT
CREATE OR REPLACE ALERT APP.VELOCITY_ANOMALY_ALERT
  WAREHOUSE = DIGITAL_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Account velocity anomaly — potential account takeover'
IF (EXISTS (
  SELECT 1 FROM CURATED.TRANSACTION_METRICS
  WHERE 1=1 -- Condition: Account transaction velocity exceeds 5x normal in 1 hour
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_malaysia_islamic_finance_digital_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Digital Islamic Banking Intelligence: Account velocity anomaly — potential account takeover',
    'Account velocity anomaly — potential account takeover'
  );

ALTER ALERT APP.VELOCITY_ANOMALY_ALERT RESUME;

