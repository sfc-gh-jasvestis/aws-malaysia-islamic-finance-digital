-- Validate the producer contract before building downstream objects.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

EXECUTE IMMEDIATE $$
DECLARE
  violations INTEGER;
  invalid_source EXCEPTION (-20001, 'Synthetic source failed grain or measure validation');
BEGIN
  SELECT COUNT(*) INTO :violations FROM (
    SELECT ENTITY_ID, EVENT_DATE
    FROM RAW.PORTFOLIO_DAILY
    GROUP BY ENTITY_ID, EVENT_DATE HAVING COUNT(*) <> 1
    UNION ALL
    SELECT observation.ENTITY_ID, observation.EVENT_DATE
    FROM RAW.PORTFOLIO_DAILY observation
    LEFT JOIN RAW.PORTFOLIOS portfolio ON portfolio.ID = observation.ENTITY_ID
    WHERE portfolio.ID IS NULL OR observation.INSTALLMENT_COUNT < 0
       OR observation.VALUE_MYR < 0
       OR observation.ESCALATED_COUNT < 0 OR observation.ESCALATED_COUNT > observation.ARREARS_COUNT
       OR observation.ARREARS_COUNT > observation.INSTALLMENT_COUNT
       OR observation.SLA_BREACHED > observation.ESCALATED_COUNT
       OR observation.REVIEW_COMPLETED > observation.REVIEW_DUE
  );
  IF (violations > 0) THEN
    RAISE invalid_source;
  END IF;
END;
$$;
