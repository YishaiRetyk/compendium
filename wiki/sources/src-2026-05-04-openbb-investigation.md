---
id: src-2026-05-04-openbb-investigation
title: "OpenBB Repository Investigation Snapshot"
type: source
status: active
summary: "Direct repository inspection capturing OpenBB's shipped TA, FA, and other extension surface."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: sourced
tags:
  - financial-ai
  - repository-investigation
  - data-infrastructure
domains:
  - financial-ai
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "OpenBB Investigation"
  - "OpenBB Repository Investigation Snapshot"
  - "src-2026-05-04-openbb-investigation"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-04-openbb-investigation.md
url: "https://github.com/OpenBB-finance/OpenBB"
content_hash: "sha256:1cd497d045aa0a2e14e66bdf622ed2bb3d8f3ad59e2296bc4dadfc02ed1f4bf7"
ingested_at: 2026-05-04
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:1cd497d045aa0a2e14e66bdf622ed2bb3d8f3ad59e2296bc4dadfc02ed1f4bf7"
compiled_targets:
  - openbb
  - financial-ai-repository-tradeoffs
  - financial-ai-repository-landscape
---

## TL;DR

OpenBB ships a dedicated `technical` extension with named indicator endpoints (Bollinger Bands, MACD, SMA/HMA/ZLMA, ATR, OBV, VWAP, Aroon, Fisher, Chaikin, Fibonacci, DeMark, Relative Rotation) and a dedicated `fundamental` submodule under `equity` with statement, growth, ratios, metrics, EPS, filings, and earnings-transcript endpoints. It is not only a data-infrastructure layer.

## Key Takeaways

- OpenBB ships TA indicator computations as first-class router endpoints, not provider passthroughs [prov:src-2026-05-04-openbb-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- OpenBB ships FA endpoints for financial statements, growth, ratios, metrics, dividends, EPS, filings, transcripts, and ESG; ratio formulas are largely delegated to upstream provider APIs [prov:src-2026-05-04-openbb-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- No DCF or valuation-model endpoint is shipped natively in OpenBB [prov:src-2026-05-04-openbb-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- Sentiment analysis is not a shipped first-class extension; only news data exposure [prov:src-2026-05-04-openbb-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Extracted Claims

- "Ships a dedicated `technical` extension at `openbb_platform/extensions/technical/openbb_technical/technical_router.py`" [prov:src-2026-05-04-openbb-investigation#sec:technical-analysis|direct|2026-05-04]
- "Ships a dedicated `fundamental` submodule under the `equity` extension at `openbb_platform/extensions/equity/openbb_equity/fundamental/fundamental_router.py`" [prov:src-2026-05-04-openbb-investigation#sec:fundamental-analysis|direct|2026-05-04]
- "Indicator computations are real Python implementations, not provider passthroughs" [prov:src-2026-05-04-openbb-investigation#sec:technical-analysis|direct|2026-05-04]

## Notes

Compiled into [[OpenBB]], [[Financial AI Repository Tradeoffs]], and [[Financial AI Repository Landscape]]. Supersedes the comparison-report-derived claim that OpenBB users must build "financial reasoning" on top of the data layer — the reasoning surface for TA and basic FA is shipped.

## Source Metadata

- **Source type:** article (repository inspection snapshot)
- **Authors:** investigation agent (via direct GitHub fetch)
- **Published:** 2026-05-04
- **Path:** `sources/2026/2026-05/2026-05-04-openbb-investigation.md`
- **URL:** https://github.com/OpenBB-finance/OpenBB
