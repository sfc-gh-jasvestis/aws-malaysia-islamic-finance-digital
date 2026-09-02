# Digital Islamic Banking Intelligence

**Malaysia - Islamic Finance**
Use case: Digital Banking Intelligence

> Real-time transaction monitoring for Malaysia's digital Islamic banks — Snowpipe Streaming ingests millions of transactions, ML.ANOMALY_DETECTION catches suspicious activity, and Cortex Complete generates personalized Shariah-compliant offers.

## Why Snowflake

Snowflake powers digital Islamic banking — Snowpipe Streaming ingests 2M transactions/month, ML detects fraud in real time, anomaly detection catches suspicious patterns, and Cortex Complete generates personalized Shariah-compliant offers

- **Snowpipe Streaming for real-time Islamic banking transactions** - Only demo ingesting 2M monthly transactions with sub-second latency for fraud scoring
- **ML.ANOMALY_DETECTION on transaction velocity** - Detects account takeover and money mule patterns in real time
- **ML.CLASSIFICATION for customer segmentation** - Segments 100K customers for Shariah-compliant product recommendations
- **Cortex Complete for Shariah-compliant offers** - Only demo generating personalized Islamic banking product recommendations with AI
- **Customer feedback analysis with Cortex Search** - 20,000 feedback entries searchable by sentiment, topic, and product
- **Malaysian digital banking context** - BNM digital bank license context with authentic Malaysian customer names and MYR transactions

## What is deployed

| | |
|---|---|
| Database | `MY_ISLAMIC_FINANCE_DIGITAL` |
| Service | `MY_ISLAMIC_FINANCE_DIGITAL_APP` |
| Compute pool | `SEA_DEMOS_MALAYSIA_POOL` |
| Dimension table | `RAW.PRODUCTS` (20 rows) |
| Fact table | `RAW.TRANSACTIONS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | MYR (RM) |

Regions in play: Selangor, Johor, Penang, Sabah, Sarawak
Segments: Retail Current Account, Wealth Management, SME Banking, Corporate

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh MY_ISLAMIC_FINANCE_DIGITAL
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Digital Islamic AUM | `RM 12.4B` | total across Products |
| Active Users | `1.8M` | total across Products |
| Shariah Compliance | `100%` | average per event |
| Products | `14` | average per event |
| App DAU | `420K` | total across Products |
| Conversion | `18%` | average per event |
| Avg Investment | `RM 8.4K` | average per event |


## Demo flow

1. Operations Overview
2. Fraud Monitoring
3. AI Personalization
4. Ask AI
5. Architecture & Data

## Talking points

- **2M transactions** - processed monthly through digital Islamic bank
- **RM 890M** - monthly transaction volume
- **127 suspicious** - transactions flagged by ML.ANOMALY_DETECTION
- **99.2%** - straight-through processing rate
- **4.2 stars** - average app rating from 20,000 reviews

## Business impact

- BNM licensed 5 digital banks in 2022 targeting 9.6M unbanked/underserved Malaysians (Bank Negara Malaysia)
- Real-time fraud detection reduces financial crime losses by 50-70% vs batch processing (McKinsey Banking)
- AI personalization in banking drives 20-30% improvement in product conversion rates (Accenture Banking)
- Malaysia's digital payment transactions reached 9.4 billion in 2023, growing 28% YoY (BNM Payment Statistics)

---
Generated from `generator/demo_specs/aws-malaysia-islamic-finance-digital.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-malaysia-islamic-finance-digital` instead.
