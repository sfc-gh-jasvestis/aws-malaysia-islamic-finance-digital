# Demo Script: Digital Islamic Banking Intelligence
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake powers digital Islamic banking — Snowpipe Streaming ingests 2M transactions/month, ML detects fraud in real time, anomaly detection catches suspicious patterns, and Cortex Complete generates personalized Shariah-compliant offers"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Encik Hafiz bin Abdullah** | Chief Digital Officer | React App (SPCS) | Transaction volume, digital adoption, customer satisfaction, fraud losses, product conversion rates |
| **Priya Devi a/p Raman** | Anti-Fraud Analyst | Amazon QuickSight | Real-time fraud alerts, suspicious transaction patterns, account takeover attempts, money mule networks |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 5 tables | TRANSACTIONS (2000000), ACCOUNTS (100000), ALERTS (5000), PRODUCTS (50), CUSTOMER_FEEDBACK (20000) |
| **CURATED** | 4 Dynamic Tables | TRANSACTION_METRICS, FRAUD_ALERTS_LIVE, CUSTOMER_SEGMENTS, PRODUCT_PERFORMANCE |
| **ML** | ML.ANOMALY_DETECTION + ML.CLASSIFICATION | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 20000 documents indexed |
| **Agent** | DIGITAL_BANKING_AGENT | Semantic View + Search tools |


---

## The Story

Bank Negara Malaysia licensed 5 digital banks in 2022, creating a new wave of Shariah-compliant fintech innovation. A leading digital Islamic bank processes 2 million transactions monthly, but legacy fraud systems flag too late and personalization requires manual campaign builds. With Snowpipe Streaming for real-time ingestion and ML.ANOMALY_DETECTION for instant scoring, suspicious transactions are caught in minutes — while Cortex Complete generates personalized Shariah-compliant offers that drive 2x conversion.

---

## Script

### [0:00–0:45] OPERATIONS OVERVIEW

**Show**: Operations Overview tab

> "Two million transactions per month — RM 890 million in monthly volume through our digital Islamic bank."

**Action**: Point at 2M transactions KPI

### [0:45–1:30] FRAUD MONITORING

**Show**: Fraud Monitoring tab

> "ML.ANOMALY_DETECTION scores every transaction — 127 flagged suspicious this month."

**Action**: Show real-time fraud alert feed

### [1:30–2:15] AI PERSONALIZATION

**Show**: AI Personalization tab

> "ML.CLASSIFICATION segments 100,000 customers into 5 behavioral cohorts."

**Action**: Show customer segment breakdown

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Encik Hafiz asks: 'Which customer segment has the highest financing conversion rate?'"

**Action**: Type segment conversion question

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Seven Snowflake capabilities, five AWS services in the dual-build."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **Snowpipe Streaming for real-time Islamic banking transactions** — Only demo ingesting 2M monthly transactions with sub-second latency for fraud scoring
2. **ML.ANOMALY_DETECTION on transaction velocity** — Detects account takeover and money mule patterns in real time
3. **ML.CLASSIFICATION for customer segmentation** — Segments 100K customers for Shariah-compliant product recommendations
4. **Cortex Complete for Shariah-compliant offers** — Only demo generating personalized Islamic banking product recommendations with AI
5. **Customer feedback analysis with Cortex Search** — 20,000 feedback entries searchable by sentiment, topic, and product
6. **Malaysian digital banking context** — BNM digital bank license context with authentic Malaysian customer names and MYR transactions


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_DIGITAL_BANKING.RAW.TRANSACTIONS` → 2000000
- [ ] `SELECT COUNT(*) FROM ISLAMIC_DIGITAL_BANKING.RAW.ACCOUNTS` → 100000
- [ ] `SELECT COUNT(*) FROM ISLAMIC_DIGITAL_BANKING.RAW.CUSTOMER_FEEDBACK` → 20000

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_DIGITAL_BANKING.ML.TRANSACTION_FRAUD_RESULTS WHERE IS_ANOMALY = TRUE` → >=127
- [ ] `SELECT COUNT(DISTINCT SEGMENT_LABEL) FROM ISLAMIC_DIGITAL_BANKING.ML.CUSTOMER_SEGMENT_RESULTS` → 5

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM ISLAMIC_DIGITAL_BANKING.AI.FEEDBACK_CLASSIFICATION` → 20000

