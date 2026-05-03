# TradingAgents repository investigation snapshot

Captures the shipped agent and tool implementations of the TradingAgents repository, observed via direct repository inspection on 2026-05-04.

## sec:repository

TauricResearch/TradingAgents on GitHub. "Multi-Agents LLM Financial Trading Framework" orchestrated via LangGraph (`tradingagents/graph/trading_graph.py` and `setup.py`). Agents are real Python files that bind specific tools to LLM nodes via `langchain_core`.

## sec:technical-analysis

A dedicated technical-analyst agent is shipped:

- Agent: `tradingagents/agents/analysts/market_analyst.py` (factory `create_market_analyst`).
- Tools bound: `get_stock_data`, `get_indicators`.
- Tool implementation: `tradingagents/agents/utils/technical_indicators_tools.py` `get_indicators` routes to a configured vendor; default path is `tradingagents/dataflows/stockstats_utils.py`, which loads OHLCV via `yfinance` and computes indicators via the `stockstats` library. An Alpha Vantage indicator path is also shipped: `tradingagents/dataflows/alpha_vantage_indicator.py`.
- Indicator math is in real Python code, not LLM prompts. The system prompt enumerates 11 specific indicators the agent picks from: `close_50_sma`, `close_200_sma`, `close_10_ema`, `macd`, `macds` (signal), `macdh` (histogram), `rsi`, `boll`/`boll_ub`/`boll_lb` (Bollinger), `atr`, `vwma`. The LLM selects up to 8 indicators per analysis and calls `get_indicators` per name; numeric values come from `stockstats` or Alpha Vantage.

## sec:fundamental-analysis

A dedicated fundamentals-analyst agent is shipped:

- Agent: `tradingagents/agents/analysts/fundamentals_analyst.py` (factory `create_fundamentals_analyst`).
- Tools bound: `get_fundamentals`, `get_balance_sheet`, `get_cashflow`, `get_income_statement`.
- Tool implementations: `tradingagents/agents/utils/fundamental_data_tools.py`; vendor implementation `tradingagents/dataflows/alpha_vantage_fundamentals.py` calls Alpha Vantage `OVERVIEW`, `BALANCE_SHEET`, `CASH_FLOW`, `INCOME_STATEMENT` endpoints, with look-ahead-bias filtering on `fiscalDateEnding`.
- An insider-transactions tool is also imported (`get_insider_transactions`).
- Real financial-statement data flows in. Ratio and valuation interpretation is the LLM's job — there is no DCF or comparables model in code — but the data grounding is concrete.

## sec:other

Other shipped agents (all real `langchain_core` tool-bound LLM nodes):

- `news_analyst.py` — tools `get_news`, `get_global_news`.
- `social_media_analyst.py` — sentiment role; tool `get_news`. Sentiment is LLM-inferred; there is no FinBERT or lexicon scoring in code.
- `researchers/bull_researcher.py` and `bear_researcher.py` — debate roles.
- `managers/research_manager.py`, `managers/portfolio_manager.py`.
- `risk_mgmt/aggressive_debator.py`, `conservative_debator.py`, `neutral_debator.py`.
- `trader/trader.py` — final BUY/HOLD/SELL synthesis.
