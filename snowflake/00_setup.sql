-- Generated from generator/demo_specs/aws-malaysia-islamic-finance-digital.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-malaysia-islamic-finance-digital
-- This is the schema that is actually deployed for MY_ISLAMIC_FINANCE_DIGITAL.

-- MY_ISLAMIC_FINANCE_DIGITAL  (Digital Islamic Banking Intelligence)
-- generated from generator/demo_specs/aws-malaysia-islamic-finance-digital.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS MY_ISLAMIC_FINANCE_DIGITAL;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_DIGITAL.RAW;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_DIGITAL.CURATED;
CREATE SCHEMA IF NOT EXISTS MY_ISLAMIC_FINANCE_DIGITAL.APP;
USE DATABASE MY_ISLAMIC_FINANCE_DIGITAL;

-- 5 real regions; entity names carry their region so the two always agree
