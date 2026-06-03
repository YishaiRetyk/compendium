---
id: dexter
title: Dexter
type: entity
status: active
summary: "Autonomous financial research agent specialized for fundamentals-and-valuation work — financial statements, key ratios, SEC filing item retrieval, analyst estimates, insider trades, and a DCF valuation skill — with no technical-analysis surface."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-04-financial-ai-repo-comparison-report
  - src-2026-05-04-dexter-investigation
epistemic_status: sourced
tags:
  - financial-ai
  - autonomous-agent
  - research-assistant
  - fundamental-analysis
  - dcf-valuation
domains:
  - financial-ai
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "virattt/dexter"
  - "Dexter"
  - "dexter"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Dexter is a TypeScript autonomous financial research agent specialized for fundamentals-and-valuation work. Its finance-specific tool surface covers financial statements, key ratios, SEC 10-K/10-Q/8-K item retrieval, analyst estimates, earnings, insider trades, and a full DCF valuation skill with sector-WACC adjustments. It returns raw OHLCV via the Financial Datasets API but ships no TA indicators or chart-pattern logic.

## Key Facts

- Dexter decomposes complex financial questions into research steps, gathers data through tools, checks its work, and iterates toward an answer [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- The report identifies Dexter's strongest fit as analyst-style research synthesis rather than systematic backtesting or portfolio execution [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Dexter's reported strengths include a human-facing research loop, scratchpad JSONL logs, an evaluation harness, and modern LLM provider support [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Dexter's finance-specific tool surface is FA-only: `key-ratios`, `fundamentals` (income/balance/cash-flow), `filings` (10-K/10-Q/8-K item retrieval), `analyst-estimates`, `earnings`, `financial-segments`, `insider-trades`, plus a full `skills/dcf` valuation skill with sector-WACC adjustments at `src/skills/dcf/sector-wacc.md` [prov:src-2026-05-04-dexter-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- Dexter ships no technical-analysis functionality: no indicator computation, no signal generation, no chart-pattern detection; `stock-price.ts` returns raw OHLCV verbatim from the Financial Datasets API [prov:src-2026-05-04-dexter-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Its reported weaknesses are dependence on LLM judgment and external APIs, less rigor than quantitative backtesting, and the limits of single-agent planning [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]

## Detail

Dexter fills the "autonomous financial research Q&A" role in the compared set. It is useful when the output is an explained answer to a financial question, with supporting tool traces and a research loop that can gather market or company information. The report explicitly contrasts this with systems intended for systematic backtesting, reinforcement-learning policy training, or reusable data-provider infrastructure [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]

Compared with Anthropic Financial Services, Dexter is more app-like and owns the interactive agent loop itself. Compared with OpenBB, it is an agent that consumes financial data rather than a generalized data access layer [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

### Direct repository inspection (2026-05-04)

The repository (virattt/dexter) is a TypeScript implementation backed by the Financial Datasets API. The finance-specific surface is concentrated in `src/tools/finance/` and `src/skills/dcf/` and is fundamentals-and-valuation oriented. `key-ratios.ts` enumerates P/E, P/B, P/S, EV/EBITDA, PEG, ROE, ROA, ROIC, current/quick/cash, debt/equity, debt/assets, EPS, book value, FCF, and growth rates for revenue, earnings, EPS, FCF, and EBITDA. `fundamentals.ts` ships statement-retrieval tools. `filings.ts` ships SEC 10-K/10-Q/8-K item retrieval (Item-1 Business, Item-1A Risk Factors, Item-7 MD&A, etc.) plus an LLM-routed reader. `screen-stocks.ts` filters on valuation, profitability, growth, dividend yield, and sector — all fundamental [prov:src-2026-05-04-dexter-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]

The `skills/dcf/SKILL.md` skill performs FCF projection, WACC discount, terminal value, and sensitivity, with sector-by-sector WACC ranges in `sector-wacc.md`. There is no comparable skill for technical analysis: a repository-wide grep for indicator names returns zero matches, and `stock-price.ts` is a thin OHLCV passthrough [prov:src-2026-05-04-dexter-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]

Everything outside `src/tools/finance/` and `src/skills/dcf/` (agent loop, scratchpad in `.dexter/scratchpad/`, evals at `src/evals/run.ts`, browser/fetch/filesystem/memory tools) is general research-agent plumbing [prov:src-2026-05-04-dexter-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Related Pages

- [[Financial AI Repository Landscape]]
- [[Financial AI Repository Tradeoffs]]
- [[Anthropic Financial Services]]
- [[OpenBB]]

## Sources

- [[Financial AI and Quant Finance Repository Comparison Report]]: "Financial AI and Quant Finance Repository Comparison Report" (2026-05-04)
- [[Dexter Repository Investigation Snapshot]]: "Dexter Repository Investigation Snapshot" (2026-05-04)
