-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Digital Islamic Banking Intelligence
-- ============================================================================
USE DATABASE ISLAMIC_DIGITAL_BANKING;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.DIGITAL_BANKING_AGENT
  COMMENT = 'Digital Islamic Banking Intelligence AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'ISLAMIC_DIGITAL_BANKING.APP.DIGITAL_BANKING_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'ISLAMIC_DIGITAL_BANKING.SEARCH.FEEDBACK_SEARCH', TOOL_DESCRIPTION => 'Search documents for Islamic Finance information')
  )
  SYSTEM_PROMPT = 'You are the Digital Islamic Banking Intelligence Agent for a Malaysian digital bank processing 2M transactions monthly. You help monitor fraud, optimize products, and understand customer behavior.';
