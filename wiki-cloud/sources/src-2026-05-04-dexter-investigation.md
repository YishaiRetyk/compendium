---
id: src-2026-05-04-dexter-investigation
title: "Dexter Repository Investigation Snapshot"
type: source
status: active
summary: "Direct repository inspection of virattt/dexter confirming Dexter is a fundamentals-and-valuation
  research agent backed by the Financial Datasets API, with no technical-analysis
  surface."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: sourced
tags:
- financial-ai
- repository-investigation
- autonomous-agent
domains:
- financial-ai
- software
supersedes: null
superseded_by: null
aliases:
- "Dexter Investigation"
- "Dexter Repository Investigation Snapshot"
- "src-2026-05-04-dexter-investigation"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-04-dexter-investigation.md
url: "https://github.com/virattt/dexter"
content_hash: "sha256:f77403be3a7459a6ec7d9c1712dcf31d96b2f9b92a6fcd79a214ad21e6d2e358"
ingested_at: 2026-05-04
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:f77403be3a7459a6ec7d9c1712dcf31d96b2f9b92a6fcd79a214ad21e6d2e358"
compiled_targets:
- dexter
- financial-ai-repository-tradeoffs
- financial-ai-repository-landscape
---

## TL;DR

Dexter is FA-only by design. It ships `key-ratios`, `fundamentals` (income/balance/cash-flow), `filings` (10-K/10-Q/8-K item retrieval), `analyst-estimates`, `earnings`, `financial-segments`, `insider-trades`, and a full `skills/dcf` valuation skill with sector-WACC adjustments. Stock and crypto prices are returned only as raw OHLCV — never transformed into TA indicators or signals.

## Key Takeaways

- Repository-wide grep for TA indicator names returns zero matches across `src/tools/finance/*.ts` and the agent prompts/types; `stock-price.ts` returns raw OHLCV only [prov:src-2026-05-04-dexter-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- The `screen-stocks.ts` filter list (lines 113–118) is purely fundamental: P/E, P/B, EV/EBITDA, margins, ROE, ROA, growth, dividend yield, sector [prov:src-2026-05-04-dexter-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Dexter ships a full DCF skill at `src/skills/dcf/SKILL.md` (FCF projection, WACC discount, terminal value, sensitivity) and `src/skills/dcf/sector-wacc.md` providing sector-by-sector WACC ranges [prov:src-2026-05-04-dexter-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- Issuer-fundamental tools include `get_key_ratios`, `get_income_statements`, `get_balance_sheets`, `get_cash_flow_statements`, `get_10K_filing_items`, `get_10Q_filing_items`, `get_8K_filing_items`, `get_analyst_estimates`, `get_earnings`, `get_financial_segments`, `get_insider_trades` [prov:src-2026-05-04-dexter-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]

## Extracted Claims

- "`src/tools/finance/stock-price.ts` returns raw OHLCV snapshots/historical bars from the Financial Datasets API verbatim — no indicator computation, no signal generation, no pattern detection" [prov:src-2026-05-04-dexter-investigation#sec:technical-analysis|direct|2026-05-04]
- "`src/skills/dcf/SKILL.md` is a full DCF valuation skill (FCF projection, WACC discount, terminal value, sensitivity); `src/skills/dcf/sector-wacc.md` gives sector-by-sector WACC ranges" [prov:src-2026-05-04-dexter-investigation#sec:fundamental-analysis|direct|2026-05-04]

## Notes

Compiled into [[dexter|Dexter]], [[financial-ai-repository-tradeoffs|Financial AI Repository Tradeoffs]], and [[financial-ai-repository-landscape|Financial AI Repository Landscape]]. Refines the comparison-report framing of Dexter as generic "analyst-style research" by surfacing the FA-and-valuation specialization (DCF skill) and the absence of any TA surface.

## Source Metadata

- **Source type:** article (repository inspection snapshot)
- **Authors:** investigation agent (via direct GitHub fetch)
- **Published:** 2026-05-04
- **Path:** `sources/2026/2026-05/2026-05-04-dexter-investigation.md`
- **URL:** https://github.com/virattt/dexter
