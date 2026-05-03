---
id: src-2026-05-04-finrl-investigation
title: "FinRL Repository Investigation Snapshot"
type: source
status: active
summary: "Direct repository inspection capturing FinRL's TA-indicator-as-RL-state-input pipeline and partial fundamentals example."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: sourced
tags:
  - reinforcement-learning
  - repository-investigation
  - quantitative-finance
domains:
  - quantitative-finance
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - FinRL Investigation
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-04-finrl-investigation.md
url: "https://github.com/AI4Finance-Foundation/FinRL"
content_hash: "sha256:daa1508f881c88ed17e2994d675b3efab7c0e6990aefc44edaa3f2e4f6ae60f4"
ingested_at: 2026-05-04
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:daa1508f881c88ed17e2994d675b3efab7c0e6990aefc44edaa3f2e4f6ae60f4"
compiled_targets:
  - finrl
  - financial-ai-repository-tradeoffs
  - financial-ai-repository-landscape
---

## TL;DR

FinRL feeds a default TA-indicator list (MACD, Bollinger upper/lower, RSI-30, CCI-30, DX-30, 30/60-day SMAs) and VIX/turbulence features into the RL state via an `add_technical_indicator` method backed by `stockstats`. Fundamentals exist only as a single application example consuming a static WRDS-derived CSV.

## Key Takeaways

- Technical indicators are first-class engineered features fed into the RL state, not optional add-ons [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- The `INDICATORS` default list and `FeatureEngineer.add_technical_indicator` are present across the data-processor implementations [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Fundamentals appear in a single example (`fundamental_stock_trading.py`) consuming a static Compustat/WRDS CSV; no fundamentals module, no `add_fundamental_indicator` method, no DCF/comparables/DDM logic [prov:src-2026-05-04-finrl-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- VIX and turbulence indices are shipped state features; sentiment/news/embedding features are absent from the core repo [prov:src-2026-05-04-finrl-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Extracted Claims

- "`finrl/config.py` ships a default `INDICATORS` list: `macd`, `boll_ub`, `boll_lb`, `rsi_30`, `cci_30`, `dx_30`, `close_30_sma`, `close_60_sma`" [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04]
- "`finrl/applications/stock_trading/fundamental_stock_trading.py` consumes a Compustat/WRDS-derived static CSV and computes ratios in-line: OPM, NPM, ROA, ROE, EPS, BPS, DPS, current ratio, quick ratio" [prov:src-2026-05-04-finrl-investigation#sec:fundamental-analysis|direct|2026-05-04]

## Notes

Compiled into [[FinRL]], [[Financial AI Repository Tradeoffs]], and [[Financial AI Repository Landscape]]. Refines the comparison-report-derived framing of FinRL by clarifying that TA features are core to the RL pipeline; FA is a single example.

## Source Metadata

- **Source type:** article (repository inspection snapshot)
- **Authors:** investigation agent (via direct GitHub fetch)
- **Published:** 2026-05-04
- **Path:** `sources/2026/2026-05/2026-05-04-finrl-investigation.md`
- **URL:** https://github.com/AI4Finance-Foundation/FinRL
