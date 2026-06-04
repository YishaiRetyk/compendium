---
id: financial-models-numerical-methods
title: Financial-Models-Numerical-Methods
type: entity
status: active
summary: "Educational quantitative finance Jupyter notebook collection (22 notebooks).
  Covers derivatives pricing, stochastic processes, Fourier inversion, Lévy processes,
  Kalman filtering, Ornstein-Uhlenbeck pairs trading, and mean-variance optimization.
  Ships no technical-analysis indicators and no fundamental-analysis content."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
- src-2026-05-04-financial-ai-repo-comparison-report
- src-2026-05-04-fmnm-investigation
epistemic_status: sourced
tags:
- quantitative-finance
- numerical-methods
- education
- derivatives-pricing
domains:
- quantitative-finance
- software
supersedes: null
superseded_by: null
aliases:
- "cantaro86/Financial-Models-Numerical-Methods"
- "Financial-Models-Numerical-Methods"
- "financial-models-numerical-methods"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Financial-Models-Numerical-Methods is a 22-notebook (1.1–7.1 plus appendices A.1–A.3) derivatives-pricing and stochastic-process pedagogy collection. It covers Black-Scholes, PDE/PIDE, Fourier inversion, Heston, Merton, Lévy processes (VG, NIG), American/exotic options, transaction costs, Kalman filtering, OU/Vasicek (with a pairs-trading example), and classical mean-variance optimization. It ships no technical-analysis indicators and no fundamental-analysis content.

## Key Facts

- The repository is a Jupyter notebook collection covering quantitative finance topics such as option pricing, SDEs, PDE/PIDE methods, Fourier methods, Kalman filtering, and mean-variance optimization [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:high-level-map|direct|2026-05-04] [epistemic:: sourced]
- The report frames it as not for absolute beginners because it assumes background in stochastic calculus, financial mathematics, statistics, and Python [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Repository inspection enumerated all 22 notebooks (1.1–7.1 plus appendices A.1–A.3); zero compute classical TA indicators, and the closest adjacency is `6.1 Ornstein-Uhlenbeck process and applications.ipynb`, which implements pairs-trading bands around a fitted OU SDE — model-based stat-arb, not chart-pattern TA [prov:src-2026-05-04-fmnm-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Zero notebooks parse financial statements, compute valuation ratios (P/E, ROE, debt/equity), build DCF/DDM models, or analyze earnings/balance-sheet/cash-flow data; macro indicators are absent [prov:src-2026-05-04-fmnm-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- The collection covers Black-Scholes, PDE/PIDE methods, Fourier inversion, Heston, Merton, VG and NIG Lévy processes, American/exotic options, transaction costs, Kalman filtering, OU/Vasicek, and classical mean-variance optimization (`7.1 Classical MVO.ipynb`) [prov:src-2026-05-04-fmnm-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]
- Its strengths are transparent formulas, inspectable code, and low black-box risk [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Its weaknesses are that it is not a platform, not an agent, not production research tooling, and mostly notebook-oriented [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]

## Detail

Financial-Models-Numerical-Methods fills the educational and mathematical foundation role. It helps a reader understand how quantitative finance models are numerically implemented: pricing equations, simulation, calibration, filtering, and optimization [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

The report treats it as complementary to FinRL. Financial-Models-Numerical-Methods explains the classical machinery behind financial modeling, while FinRL focuses on trainable reinforcement-learning trading pipelines [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

### Direct repository inspection (2026-05-04)

The notebook collection enumerated via the GitHub contents API contains no RSI, MACD, Bollinger Bands, moving averages, ATR, ADX, candlestick patterns, or chart-based price/volume signals. The closest TA adjacencies are model-based: `5.1 Linear regression - Kalman filter.ipynb` and `5.3 Volatility tracking.ipynb` extract latent state from price series (signal extraction, not indicators), and `6.1 Ornstein-Uhlenbeck process and applications.ipynb` includes a "Trading strategy" subsection implementing pairs-trading / statistical-arbitrage bands around the long-term mean of a fitted OU SDE — stat-arb on a calibrated stochastic process [prov:src-2026-05-04-fmnm-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]

The repository is a numerical-methods-for-quant-finance pedagogy repo, not a TA, FA, or trading-system repo. It operates exclusively on price/return time series and synthetic SDE paths and never touches issuer fundamentals [prov:src-2026-05-04-fmnm-investigation#sec:fundamental-analysis|direct|2026-05-04] [prov:src-2026-05-04-fmnm-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Related Pages

- [[financial-ai-repository-landscape|Financial AI Repository Landscape]]
- [[financial-ai-repository-tradeoffs|Financial AI Repository Tradeoffs]]
- [[finrl|FinRL]]

## Sources

- [[src-2026-05-04-financial-ai-repo-comparison-report|Financial AI and Quant Finance Repository Comparison Report]]: "Financial AI and Quant Finance Repository Comparison Report" (2026-05-04)
- [[src-2026-05-04-fmnm-investigation|Financial-Models-Numerical-Methods Repository Investigation Snapshot]]: "Financial-Models-Numerical-Methods Repository Investigation Snapshot" (2026-05-04)
