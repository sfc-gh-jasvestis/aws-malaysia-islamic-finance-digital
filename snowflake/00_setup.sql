-- ============================================================================
-- Digital Islamic Banking Intelligence
-- Real-time transaction monitoring for Malaysia's digital Islamic banks — Snowpipe Streaming ingests millions of transactions, ML.ANOMALY_DETECTION catches suspicious activity, and Cortex Complete generates personalized Shariah-compliant offers.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS ISLAMIC_DIGITAL_BANKING;
CREATE WAREHOUSE IF NOT EXISTS DIGITAL_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE ISLAMIC_DIGITAL_BANKING;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE DIGITAL_WH;
