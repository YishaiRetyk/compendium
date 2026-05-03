# Dexter repository investigation snapshot

Captures the shipped tool surface of the Dexter (virattt/dexter) repository, observed via direct repository inspection on 2026-05-04.

## sec:repository

virattt/dexter on GitHub. TypeScript autonomous financial research agent matching the description in the upstream comparison report: research loop, scratchpad JSONL logs in `.dexter/scratchpad/`, evaluation harness in `src/evals/run.ts`, multi-LLM provider support. Backed by the Financial Datasets API for issuer-level data.

## sec:technical-analysis

Dexter ships no technical-analysis functionality.

- A repository-wide grep for `RSI|MACD|bollinger|ATR|ADX|stochastic|candlestick|VWAP|ichimoku|technical indicator|chart pattern` across all of `src/tools/finance/*.ts` and the agent prompts/types returned zero matches.
- `src/tools/finance/stock-price.ts` returns raw OHLCV snapshots and historical bars from the Financial Datasets API verbatim — no indicator computation, no signal generation, no pattern detection.
- No charting, plotting, or indicator-library dependency in the package code.
- The `screen-stocks.ts` filter list (lines 113–118) is purely fundamental: "valuation (P/E, P/B, EV/EBITDA)", "profitability (margins, ROE, ROA)", "growth rates", "dividend yield", "sector".

## sec:fundamental-analysis

Dexter is a fundamentals-and-valuation research agent by design.

- `src/tools/finance/key-ratios.ts` `get_key_ratios` description explicitly enumerates: P/E, P/B, P/S, EV/EBITDA, PEG; ROE, ROA, ROIC; current/quick/cash ratios; debt/equity, debt/assets; EPS, book value, FCF; revenue, earnings, EPS, FCF, EBITDA growth.
- `src/tools/finance/fundamentals.ts` ships `get_income_statements`, `get_balance_sheets`, `get_cash_flow_statements`, `get_all_financial_statements`.
- `src/tools/finance/filings.ts` ships `get_10K_filing_items`, `get_10Q_filing_items`, `get_8K_filing_items` (Item-1 Business, Item-1A Risk Factors, Item-7 MD&A, etc.); `read-filings.ts` adds an LLM-routed reader.
- `src/skills/dcf/SKILL.md` is a full DCF valuation skill (FCF projection, WACC discount, terminal value, sensitivity); `src/skills/dcf/sector-wacc.md` provides sector-by-sector WACC ranges.
- Additional FA tools: `get_analyst_estimates`, `get_earnings`, `get_financial_segments`, `get_insider_trades`.

## sec:other

Everything outside `src/tools/finance/` and `src/skills/dcf/` (agent loop, scratchpad, evals, browser/fetch/filesystem/memory tools) is general research-agent plumbing. The finance-specific surface is FA-only: financial-statement retrieval, ratio/metric snapshots and history, SEC filing item retrieval and reading, analyst estimates / earnings / segments / insider trades, and a DCF valuation skill with sector-WACC adjustments.
