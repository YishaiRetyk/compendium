---
id: src-2026-05-04-fmnm-investigation
title: "Financial-Models-Numerical-Methods Repository Investigation Snapshot"
type: source
status: active
summary: "Direct repository inspection of all 22 notebooks confirming the repository covers derivatives pricing and stochastic processes — no TA, no FA."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: sourced
tags:
  - quantitative-finance
  - repository-investigation
  - numerical-methods
domains:
  - quantitative-finance
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - "FMNM Investigation"
  - "Financial-Models-Numerical-Methods Repository Investigation Snapshot"
  - "src-2026-05-04-fmnm-investigation"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-04-fmnm-investigation.md
url: "https://github.com/cantaro86/Financial-Models-Numerical-Methods"
content_hash: "sha256:b2aa5b8bd0e1044e0662da898ea2c518fa4d1262b3013ac6f47f246fe2b13bdf"
ingested_at: 2026-05-04
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:b2aa5b8bd0e1044e0662da898ea2c518fa4d1262b3013ac6f47f246fe2b13bdf"
compiled_targets:
  - financial-models-numerical-methods
  - financial-ai-repository-tradeoffs
  - financial-ai-repository-landscape
---

## TL;DR

All 22 notebooks (1.1–7.1 plus appendices A.1–A.3) are derivatives-pricing and stochastic-process pedagogy. None compute classical TA indicators; none parse financial statements or compute valuation ratios. The closest TA adjacency is a model-based pairs-trading example on a fitted Ornstein-Uhlenbeck SDE.

## Key Takeaways

- Zero notebooks compute classical TA indicators (RSI, MACD, Bollinger Bands, moving averages, ATR, ADX, candlestick patterns); the closest adjacency is a model-based OU pairs-trading example [prov:src-2026-05-04-fmnm-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Zero notebooks parse financial statements, compute valuation ratios, build DCF/DDM models, or analyze earnings/balance-sheet/cash-flow data [prov:src-2026-05-04-fmnm-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- The repository covers Black-Scholes/PDE/PIDE, Fourier inversion, Heston, Merton, VG and NIG Lévy processes, American/exotic options, transaction costs, Kalman filtering, OU/Vasicek, and classical mean-variance optimization [prov:src-2026-05-04-fmnm-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Extracted Claims

- "I enumerated all 22 notebooks (1.1–7.1 plus appendices A.1–A.3) directly via the GitHub contents API. None compute classical TA indicators" [prov:src-2026-05-04-fmnm-investigation#sec:technical-analysis|direct|2026-05-04]
- "Zero notebooks parse financial statements, compute valuation ratios (P/E, ROE, debt/equity), build DCF/DDM models, or analyze earnings/balance-sheet/cash-flow data" [prov:src-2026-05-04-fmnm-investigation#sec:fundamental-analysis|direct|2026-05-04]

## Notes

Compiled into [[financial-models-numerical-methods|Financial-Models-Numerical-Methods]], [[financial-ai-repository-tradeoffs|Financial AI Repository Tradeoffs]], and [[financial-ai-repository-landscape|Financial AI Repository Landscape]]. Confirms the comparison-report framing.

## Source Metadata

- **Source type:** article (repository inspection snapshot)
- **Authors:** investigation agent (via direct GitHub fetch)
- **Published:** 2026-05-04
- **Path:** `sources/2026/2026-05/2026-05-04-fmnm-investigation.md`
- **URL:** https://github.com/cantaro86/Financial-Models-Numerical-Methods
