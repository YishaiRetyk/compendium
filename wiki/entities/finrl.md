---
id: finrl
title: FinRL
type: entity
status: active
summary: "Deep reinforcement-learning trading framework with technical-indicator features as first-class RL state inputs (MACD, Bollinger, RSI, CCI, DX, SMA, VIX, turbulence) and a single fundamentals example using a static WRDS-derived CSV."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-04-financial-ai-repo-comparison-report
  - src-2026-05-04-finrl-investigation
epistemic_status: sourced
tags:
  - reinforcement-learning
  - trading-research
  - quantitative-finance
  - technical-analysis
domains:
  - quantitative-finance
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - AI4Finance-Foundation/FinRL
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

FinRL is the deep-reinforcement-learning trading framework in this comparison. Technical indicators are first-class engineered features fed into the RL state via a default `INDICATORS` list (MACD, Bollinger upper/lower, RSI-30, CCI-30, DX-30, 30/60-day SMAs) plus VIX and turbulence indices, all backed by `stockstats`. Fundamentals exist as a single application example consuming a static Compustat/WRDS CSV — there is no shipped FA module.

## Key Facts

- FinRL is organized around market environments, DRL agents, and financial applications [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- The report notes that current project positioning treats this repository as the original educational and research framework while pointing production-oriented users to FinRL-X/FinRL-Trading [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Technical indicators are first-class engineered features for the RL state: `finrl/config.py` ships a default `INDICATORS` list (`macd`, `boll_ub`, `boll_lb`, `rsi_30`, `cci_30`, `dx_30`, `close_30_sma`, `close_60_sma`); `FeatureEngineer.add_technical_indicator` is implemented across the data processors via `stockstats` (and `talib` in the Sinopac processor) [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Fundamentals are present as a single example only: `finrl/applications/stock_trading/fundamental_stock_trading.py` consumes a Compustat/WRDS-derived static CSV and computes ratios in-line (OPM, NPM, ROA, ROE, EPS, BPS, DPS, current ratio, quick ratio); no fundamentals module, `add_fundamental_indicator` method, or DCF/comparables logic is shipped [prov:src-2026-05-04-finrl-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- Its strengths are statistically trainable policies, reproducible experiments, backtest framing, and usefulness for reinforcement-learning research [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Its weaknesses are an older coupled architecture, not being the recommended production path, reinforcement-learning overfitting and data-leakage risks, and less natural-language explainability than LLM agents [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]

## Detail

FinRL fills the formal reinforcement-learning trading experiment role. It is stronger than LLM-agent frameworks when the research question is whether a policy can learn from market states under a defined reward and environment. It is weaker for natural-language explanation and qualitative synthesis [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

The report treats FinRL as complementary to Financial-Models-Numerical-Methods for learning. The notebook collection explains classical financial model mechanics, while FinRL provides an end-to-end sequential decision pipeline [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

### Direct repository inspection (2026-05-04)

The training pipeline in `finrl/train.py` and `finrl/meta/paper_trading/common.py` calls `dp.add_technical_indicator(data, technical_indicator_list)` and feeds `tech_array` into the RL environment, alongside `add_vix` and `add_turbulence`. The same `add_technical_indicator` method appears across 5+ data-processor implementations: `processor_yahoofinance.py`, `processor_alpaca.py`, `processor_wrds.py`, `processor_ccxt.py`, and `processor_sinopac.py` (the last via `talib.get_functions()`) [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]

The `fundamental_stock_trading.py` example is the only fundamentals usage in the repository. `processor_eodhd.py` references EODHD's `/fundamentals/` endpoint, but only to fetch index *components* (ticker lists), not financial statements. Other applications (cryptocurrency, portfolio allocation, high-frequency, default `stock_trading`) use only TA features. Sentiment, news, and embedding features are absent from the core repo and live in sibling repositories such as FinRL-Meta and FinGPT [prov:src-2026-05-04-finrl-investigation#sec:fundamental-analysis|direct|2026-05-04] [prov:src-2026-05-04-finrl-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

OHLCV ingestion supports 14+ providers (Yahoo, Alpaca, Binance, CCXT, WRDS, EODHD, Sinopac, etc.) [prov:src-2026-05-04-finrl-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Related Pages

- [[Financial AI Repository Landscape]]
- [[Financial AI Repository Tradeoffs]]
- [[TradingAgents]]
- [[Financial-Models-Numerical-Methods]]
- [[OpenBB]]

## Sources

- [[Financial AI and Quant Finance Repository Comparison Report]]: "Financial AI and Quant Finance Repository Comparison Report" (2026-05-04)
- [[FinRL Repository Investigation Snapshot]]: "FinRL Repository Investigation Snapshot" (2026-05-04)
