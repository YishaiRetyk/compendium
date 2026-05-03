---
id: openbb
title: OpenBB
type: entity
status: active
summary: "Open-source financial data platform that exposes data via Python, REST, CLI, MCP, and Excel, and also ships native technical-analysis and fundamental-analysis router modules."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-04-financial-ai-repo-comparison-report
  - src-2026-05-04-openbb-investigation
epistemic_status: sourced
tags:
  - financial-data
  - data-infrastructure
  - mcp
  - technical-analysis
  - fundamental-analysis
domains:
  - financial-ai
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - OpenBB-finance/OpenBB
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

OpenBB is the financial-data infrastructure layer in this comparison, exposing data through Python, REST, CLI, MCP, and Excel. It also ships native financial-reasoning modules: a `technical` extension with named indicator endpoints (Bollinger Bands, MACD, SMA/HMA/ZLMA, ATR, OBV, VWAP, Aroon, Fisher, Chaikin, Fibonacci, DeMark, Relative Rotation) and a `fundamental` submodule under `equity` (statements, growth, ratios, metrics, EPS, filings, transcripts). It is not a trading-decision or report-generation system.

## Key Facts

- OpenBB is open-source tooling for integrating proprietary, licensed, and public financial data into downstream applications such as AI copilots and dashboards [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- It exposes financial data through Python, CLI, Workspace and Excel integrations, MCP servers, and REST APIs [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- A dedicated `technical` extension at `openbb_platform/extensions/technical/openbb_technical/technical_router.py` ships indicator endpoints (`bbands`, `macd`, `sma`/`hma`/`zlma`, `atr`, `obv`, `vwap`, `aroon`, `fisher`, `adosc`, `fib`, `demark`, `relative_rotation`) as real Python implementations, installable as `openbb-technical` [prov:src-2026-05-04-openbb-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- A dedicated `fundamental` submodule under the `equity` extension ships statement, growth, ratios, metrics, EPS, dividends, filings, transcript, and ESG endpoints; ratio formulas are largely delegated to upstream providers, and no DCF endpoint is shipped natively [prov:src-2026-05-04-openbb-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- Its strengths are breadth of integrations, Python and REST surfaces, MCP relevance for agents, and a large community [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Its weaknesses are that data normalization and provider credential management remain hard, the enterprise UI is separate, and financial reasoning must be built on top [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: stale] (the "financial reasoning must be built on top" portion is superseded by the 2026-05-04 inspection findings — OpenBB ships TA indicator endpoints and basic FA endpoints natively)

## Detail

OpenBB is the strongest candidate for a centralized data layer when building a serious financial research stack. The report warns against scattering data-fetch logic across agents and recommends centralizing provider access through OpenBB or an equivalent data layer when provider breadth, shared credentials, and multiple downstream consumers matter [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

OpenBB overlaps with the embedded connectors in Dexter, TradingAgents, and FinRL, but the overlap is infrastructural rather than workflow-level. Embedded connectors are simpler for demos and narrow apps; OpenBB is better suited to reusable platform construction [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

### Direct repository inspection (2026-05-04)

OpenBB ships first-class TA and FA reasoning surfaces, partially contradicting the comparison report's framing that financial reasoning must be built on top of OpenBB. The `technical` extension is installable as a standalone package and registers indicator commands via `@router.command()`. The `equity/fundamental` router exposes named endpoints for the three financial statements, period-over-period growth, an "extensive set of financial and accounting ratios", per-segment and per-geography revenue, EPS history, dividends, filings, and earnings-call transcripts. Indicator computations are real Python implementations rather than provider passthroughs, while FA ratio formulas are largely delegated to upstream provider APIs (Intrinio, FMP, etc.) [prov:src-2026-05-04-openbb-investigation#sec:technical-analysis|direct|2026-05-04] [prov:src-2026-05-04-openbb-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]

No DCF or valuation-model endpoint is shipped natively. Sentiment analysis is not a shipped first-class extension — only news data exposure. Additional extensions cover quantitative analytics (`quantitative/` performance, rolling, stats), econometrics, macro economy data, derivatives (options chains and Greeks via providers), fixed income, ETF, crypto, currency, Fama-French factors, and regulators [prov:src-2026-05-04-openbb-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Related Pages

- [[Financial AI Repository Landscape]]
- [[Financial AI Repository Tradeoffs]]
- [[Dexter]]
- [[TradingAgents]]
- [[FinRL]]

## Sources

- [[Financial AI and Quant Finance Repository Comparison Report]]: "Financial AI and Quant Finance Repository Comparison Report" (2026-05-04)
- [[OpenBB Repository Investigation Snapshot]]: "OpenBB Repository Investigation Snapshot" (2026-05-04)
