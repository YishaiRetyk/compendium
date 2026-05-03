---
id: src-2026-05-04-tradingagents-investigation
title: "TradingAgents Repository Investigation Snapshot"
type: source
status: active
summary: "Direct repository inspection capturing TradingAgents' shipped market_analyst and fundamentals_analyst agents, their bound tools, and the LangGraph orchestration."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: sourced
tags:
  - financial-ai
  - repository-investigation
  - llm-agents
domains:
  - financial-ai
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - TradingAgents Investigation
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-04-tradingagents-investigation.md
url: "https://github.com/TauricResearch/TradingAgents"
content_hash: "sha256:f26f4aeeb7b71ae39373dbb3b21d13ea27708ce87afe9b8a1163dfafc4524beb"
ingested_at: 2026-05-04
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:f26f4aeeb7b71ae39373dbb3b21d13ea27708ce87afe9b8a1163dfafc4524beb"
compiled_targets:
  - tradingagents
  - financial-ai-repository-tradeoffs
  - financial-ai-repository-landscape
---

## TL;DR

TradingAgents ships a real `market_analyst` agent that calls a `get_indicators` tool routed through `stockstats` or Alpha Vantage to compute 11 named indicators, and a real `fundamentals_analyst` agent that calls `get_balance_sheet` / `get_cashflow` / `get_income_statement` / `get_fundamentals` against the Alpha Vantage API. Indicator math runs in code; ratio and valuation interpretation is the LLM's job. Sentiment is LLM-inferred without any FinBERT or lexicon scoring.

## Key Takeaways

- The market_analyst agent and `get_indicators` tool compute 11 named indicators (`close_50_sma`, `close_200_sma`, `close_10_ema`, `macd`, `macds`, `macdh`, `rsi`, `boll`/`boll_ub`/`boll_lb`, `atr`, `vwma`) via real Python code, not LLM prompts [prov:src-2026-05-04-tradingagents-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- The fundamentals_analyst agent retrieves real financial-statement data through tools backed by Alpha Vantage's `OVERVIEW`, `BALANCE_SHEET`, `CASH_FLOW`, and `INCOME_STATEMENT` endpoints, with look-ahead-bias filtering on `fiscalDateEnding` [prov:src-2026-05-04-tradingagents-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- No DCF or comparables model code is shipped; ratio interpretation is left to the LLM [prov:src-2026-05-04-tradingagents-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- The full agent set is orchestrated via LangGraph in `tradingagents/graph/trading_graph.py`; sentiment is LLM-inferred with no scoring code [prov:src-2026-05-04-tradingagents-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Extracted Claims

- "`tradingagents/agents/analysts/market_analyst.py` `create_market_analyst`. Bound tools: `get_stock_data`, `get_indicators`" [prov:src-2026-05-04-tradingagents-investigation#sec:technical-analysis|direct|2026-05-04]
- "`tradingagents/agents/analysts/fundamentals_analyst.py` `create_fundamentals_analyst`. Bound tools: `get_fundamentals`, `get_balance_sheet`, `get_cashflow`, `get_income_statement`" [prov:src-2026-05-04-tradingagents-investigation#sec:fundamental-analysis|direct|2026-05-04]

## Notes

Compiled into [[TradingAgents]], [[Financial AI Repository Tradeoffs]], and [[Financial AI Repository Landscape]]. Confirms and concretizes the comparison-report claim that TradingAgents uses role-specialized agents for fundamentals and technical analysis.

## Source Metadata

- **Source type:** article (repository inspection snapshot)
- **Authors:** investigation agent (via direct GitHub fetch)
- **Published:** 2026-05-04
- **Path:** `sources/2026/2026-05/2026-05-04-tradingagents-investigation.md`
- **URL:** https://github.com/TauricResearch/TradingAgents
