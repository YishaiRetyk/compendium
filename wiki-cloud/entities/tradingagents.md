---
id: tradingagents
title: TradingAgents
type: entity
status: active
summary: "Multi-agent LLM trading research framework, orchestrated via LangGraph,
  with shipped market_analyst (TA via stockstats/Alpha Vantage) and fundamentals_analyst
  (statements via Alpha Vantage) agents plus news, sentiment, bull/bear, risk, and
  trader roles."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
- src-2026-05-04-financial-ai-repo-comparison-report
- src-2026-05-04-tradingagents-investigation
epistemic_status: sourced
tags:
- financial-ai
- llm-agents
- trading-research
- technical-analysis
- fundamental-analysis
domains:
- financial-ai
- software
supersedes: null
superseded_by: null
aliases:
- "TauricResearch/TradingAgents"
- "TradingAgents"
- "tradingagents"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

TradingAgents is the LLM trading-decision research framework in this set, orchestrated via LangGraph. It ships real role-specialized agents: a `market_analyst` that calls `get_indicators` (routed through `stockstats` or Alpha Vantage to compute 11 named indicators) and a `fundamentals_analyst` that calls `get_balance_sheet`/`get_cashflow`/`get_income_statement`/`get_fundamentals` against Alpha Vantage. Indicator math runs in code; ratio and valuation interpretation is the LLM's job. Sentiment is LLM-inferred without scoring code.

## Key Facts

- TradingAgents models a trading firm with role-specialized LLM agents for fundamentals, sentiment, news, technical analysis, bullish and bearish research, trading, risk management, and portfolio management [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- The report identifies it as the most direct LLM trading-decision project in the compared set [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- The market_analyst agent at `tradingagents/agents/analysts/market_analyst.py` is bound to `get_stock_data` and `get_indicators`, computing 11 named indicators (`close_50_sma`, `close_200_sma`, `close_10_ema`, `macd`, `macds`, `macdh`, `rsi`, `boll`/`boll_ub`/`boll_lb`, `atr`, `vwma`) via `stockstats` or Alpha Vantage in real Python code, not LLM prompts [prov:src-2026-05-04-tradingagents-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- The fundamentals_analyst agent at `tradingagents/agents/analysts/fundamentals_analyst.py` is bound to `get_fundamentals`, `get_balance_sheet`, `get_cashflow`, and `get_income_statement`, backed by Alpha Vantage `OVERVIEW`/`BALANCE_SHEET`/`CASH_FLOW`/`INCOME_STATEMENT` endpoints with look-ahead-bias filtering on `fiscalDateEnding`; no DCF or comparables model code is shipped [prov:src-2026-05-04-tradingagents-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- Its strengths are a richer deliberative structure than Dexter for trading-specific decisions, explicit risk and portfolio-manager layers, configurable debates, and persistent memory [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Its weaknesses are high variance, LLM cost, causal-validation difficulty, and the risk that debate creates persuasive narratives without statistical edge [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]

## Detail

TradingAgents is intended for research into LLM committees and structured financial debate. It differs from Dexter by focusing on trading decisions rather than general financial research Q&A, and it differs from FinRL by using LLM deliberation rather than trained reinforcement-learning policies [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

The report treats TradingAgents as qualitatively broad and naturally explainable, but also nondeterministic and difficult to validate causally. That makes it useful for studying LLM-based decision formation, not sufficient as a standalone evidence of trading edge [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

### Direct repository inspection (2026-05-04)

Agents are real Python files that bind specific tools to LLM nodes via `langchain_core` and are orchestrated via LangGraph in `tradingagents/graph/trading_graph.py` and `setup.py`. The market_analyst's `get_indicators` tool is implemented in `tradingagents/agents/utils/technical_indicators_tools.py` and routes to a configured vendor — default path `tradingagents/dataflows/stockstats_utils.py` (loads OHLCV via `yfinance`, computes via `stockstats`) or `tradingagents/dataflows/alpha_vantage_indicator.py`. The system prompt enumerates the 11 indicators above; the LLM selects up to 8 per analysis [prov:src-2026-05-04-tradingagents-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]

The fundamentals_analyst's tools are defined in `tradingagents/agents/utils/fundamental_data_tools.py` with vendor implementation in `tradingagents/dataflows/alpha_vantage_fundamentals.py`. An insider-transactions tool is also imported (`get_insider_transactions`) [prov:src-2026-05-04-tradingagents-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]

Other shipped agents include `news_analyst.py` (tools `get_news`, `get_global_news`), `social_media_analyst.py` for sentiment (tool `get_news`; sentiment is LLM-inferred — no FinBERT or lexicon scoring in code), `researchers/bull_researcher.py` and `bear_researcher.py` for debate, `managers/research_manager.py` and `managers/portfolio_manager.py`, `risk_mgmt/aggressive_debator.py`/`conservative_debator.py`/`neutral_debator.py`, and `trader/trader.py` for the final BUY/HOLD/SELL synthesis [prov:src-2026-05-04-tradingagents-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Related Pages

- [[financial-ai-repository-landscape|Financial AI Repository Landscape]]
- [[financial-ai-repository-tradeoffs|Financial AI Repository Tradeoffs]]
- [[dexter|Dexter]]
- [[finrl|FinRL]]
- [[openbb|OpenBB]]

## Sources

- [[src-2026-05-04-financial-ai-repo-comparison-report|Financial AI and Quant Finance Repository Comparison Report]]: "Financial AI and Quant Finance Repository Comparison Report" (2026-05-04)
- [[src-2026-05-04-tradingagents-investigation|TradingAgents Repository Investigation Snapshot]]: "TradingAgents Repository Investigation Snapshot" (2026-05-04)
