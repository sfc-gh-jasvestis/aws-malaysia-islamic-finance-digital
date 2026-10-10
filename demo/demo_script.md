# Islamic Financing Collections Operations

**Malaysia - Digital Islamic Bank Collections**
Use case: Financing arrears, escalation to restructuring review and collections controls

> Collections monitoring for 40 financing portfolios at a fictional Malaysian digital Islamic bank across 5 cities: dynamic tables, a holdout-evaluated escalation classifier, an arrears-volume forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile installments due, arrears cases, escalations, contact SLA breaches and account review compliance from RAW portfolio data, with checks in `run_core.py`
- **Escalation classification** gives a holdout-evaluated next-7-day probability per portfolio
- **Arrears forecast** projects 14 days of bank-wide arrears volume with prediction intervals, for collections staffing
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live installments**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.PORTFOLIOS` (40 rows) |
| Fact table | `RAW.PORTFOLIO_DAILY` (3,600 portfolio-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `ARREARS_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.ESCALATION_RISK_SCORES`, `ML.ESCALATION_RISK_HOLDOUT_METRICS`, `ML.ARREARS_FORECAST`, `ML.AUTODEBIT_REJECT_ANOMALIES` |

Cities: Kuala Lumpur, Johor Bahru, George Town, Kota Kinabalu, Kuching (MYR).
Financing products: Tawarruq personal, SME murabahah, Musharakah mutanaqisah home, Ijarah equipment, Mudarabah working capital.

Product notes, for the presenter: tawarruq is a commodity-based sale arrangement used for personal financing; murabahah is a sale at cost plus a disclosed margin, paid in installments; ijarah is a lease; musharakah mutanaqisah is a diminishing partnership in which the customer buys out the bank's share over time; mudarabah is a profit-sharing arrangement in which one party provides capital and the other manages the business. The demo describes collections operations only; it makes no religious or regulatory rulings.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| On-Time Collection Rate | 99.92% |
| Arrears Cases | 598 |
| Escalated to Restructuring Review | 214 |
| Escalation Rate | 35.8% |
| Contact SLA Breaches | 106 |
| Scheduled Value (MYR M) | 974 |
| Installments Due | 763,283 |
| Account Review Compliance | 77.1% |
| Portfolios Monitored | 40 |
| Financing File Coverage | 66.7% |
| Financing Documents Pending | 15 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily arrears cases against escalations, arrears and escalations by reason, portfolio table
2. Predictive: holdout metrics, risk bands, 14-day arrears forecast, auto-debit rejection rate anomalies
3. Controls: account review compliance, financing file coverage and pending documents, review compliance against escalated cases, then generate the action memo
4. Live Installments: run `CALL APP.SIMULATE_INSTALLMENTS(20)` (Snowflake only) or `python aws/publish_installments.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ARREARS_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.92% of installments are collected without an arrears case; the 598 arrears cases are where collections time goes, and 35.8% of them are escalated to restructuring review.
- Auto-debit insufficient balance produces the most escalations (84 of 202 cases). Payment channel disruptions hit every portfolio in a city at once and always resolve without escalation.
- The risk model is evaluated on a time-based holdout: precision 0.34 and recall 0.32 at 0.5, against a 0.22 base rate. Present it as triage, not a verdict.
- Payment channel disruptions are excluded from model training, because they are not portfolio-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
