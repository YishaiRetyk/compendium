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
  - "FinRL Investigation"
  - "FinRL Repository Investigation Snapshot"
  - "src-2026-05-04-finrl-investigation"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-05/2026-05-04-finrl-investigation.md
url: "https://github.com/AI4Finance-Foundation/FinRL"
content_hash: "sha256:bde68e632187f318c24d120fa4bc7c49621187e65ad9a7abc0f33f703b40c78e"
ingested_at: 2026-05-04
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:bde68e632187f318c24d120fa4bc7c49621187e65ad9a7abc0f33f703b40c78e"
compiled_targets:
  - finrl
  - financial-ai-repository-tradeoffs
  - financial-ai-repository-landscape
---

## TL;DR

FinRL feeds a default TA-indicator list (MACD, Bollinger upper/lower, RSI-30, CCI-30, DX-30, 30/60-day SMAs) and VIX/turbulence features into the RL state via an `add_technical_indicator` method backed by `stockstats`. Fundamentals exist only as a single application example consuming a static WRDS-derived CSV. Training data is fetched live from external market-data APIs (no bundled OHLCV); RL agents are trained from scratch with random initialization on each environment using A2C/DDPG/PPO/TD3/SAC across three backends (Stable-Baselines3, ElegantRL, RLlib). Shipped `actor.pth` files in two applications are demo outputs, not training inputs.

## Key Takeaways

- Technical indicators are first-class engineered features fed into the RL state, not optional add-ons [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- The `INDICATORS` default list and `FeatureEngineer.add_technical_indicator` are present across the data-processor implementations [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Fundamentals appear in a single example (`fundamental_stock_trading.py`) consuming a static Compustat/WRDS CSV; no fundamentals module, no `add_fundamental_indicator` method, no DCF/comparables/DDM logic [prov:src-2026-05-04-finrl-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- VIX and turbulence indices are shipped state features; sentiment/news/embedding features are absent from the core repo [prov:src-2026-05-04-finrl-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]
- Training data is fetched live from 14+ external market-data APIs at runtime via per-provider processors under `finrl/meta/data_processors/`; no OHLCV bundle ships in the repo [prov:src-2026-05-04-finrl-investigation#sec:data-sources|direct|2026-05-04] [epistemic:: sourced]
- RL agents are trained from scratch with random initialization: `agent.get_model(name)` at `finrl/agents/stablebaselines3/models.py:108-123` returns a brand-new SB3 instance; `PPO.load` and `*.load` appear only in inference and paper-trading scripts, never in training [prov:src-2026-05-04-finrl-investigation#sec:training-paradigm|direct|2026-05-04] [epistemic:: sourced]
- Algorithms supported: A2C, DDPG, PPO, TD3, SAC across three swappable backends (Stable-Baselines3, ElegantRL, RLlib); transfer/curriculum learning are absent from the standard pipeline (the imitation-learning workflow is opt-in research code) [prov:src-2026-05-04-finrl-investigation#sec:training-paradigm|direct|2026-05-04] [epistemic:: sourced]
- The repository states no hardware requirements (Python ≥3.7 only); training runs CPU-only out of the box because SB3 defaults to `device="auto"` and the example notebooks/scripts never request CUDA; a GPU is recommended but not required, and only meaningfully helps the ElegantRL backend and long SB3 runs at the `1e6`-step default [prov:src-2026-05-04-finrl-investigation#sec:hardware-requirements|direct|2026-05-04] [epistemic:: sourced]
- No `SubprocVecEnv` or `n_envs` parameter is exposed (single-process `DummyVecEnv` only); the 1M-step TD3 replay buffer is the largest memory line item at default hyperparameters (on the order of hundreds of MB) [prov:src-2026-05-04-finrl-investigation#sec:hardware-requirements|direct|2026-05-04] [epistemic:: sourced]

## Extracted Claims

- "`finrl/config.py` ships a default `INDICATORS` list: `macd`, `boll_ub`, `boll_lb`, `rsi_30`, `cci_30`, `dx_30`, `close_30_sma`, `close_60_sma`" [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04]
- "`finrl/applications/stock_trading/fundamental_stock_trading.py` consumes a Compustat/WRDS-derived static CSV and computes ratios in-line: OPM, NPM, ROA, ROE, EPS, BPS, DPS, current ratio, quick ratio" [prov:src-2026-05-04-finrl-investigation#sec:fundamental-analysis|direct|2026-05-04]
- "`get_model` returns `MODELS[model_name](policy=\"MlpPolicy\", env=self.env, ...)`, a brand-new SB3 instance" [prov:src-2026-05-04-finrl-investigation#sec:training-paradigm|direct|2026-05-04]
- "`PPO.load` / `*.load` calls appear only in `examples/FinRL_StockTrading_2026_3_Backtest.py`, `Stock_NeurIPS2018_3_Backtest.ipynb`, and `finrl/meta/paper_trading/alpaca.py` — inference and deployment, never training" [prov:src-2026-05-04-finrl-investigation#sec:training-paradigm|direct|2026-05-04]
- "Training runs CPU-only out of the box. A GPU is recommended but not required, and only meaningfully helps the ElegantRL backend and long SB3 runs at the `1e6`-step default" [prov:src-2026-05-04-finrl-investigation#sec:hardware-requirements|direct|2026-05-04]

## Notes

Compiled into [[finrl|FinRL]], [[financial-ai-repository-tradeoffs|Financial AI Repository Tradeoffs]], and [[financial-ai-repository-landscape|Financial AI Repository Landscape]]. Refines the comparison-report-derived framing of FinRL by clarifying that TA features are core to the RL pipeline; FA is a single example.

## Source Metadata

- **Source type:** article (repository inspection snapshot)
- **Authors:** investigation agent (via direct GitHub fetch)
- **Published:** 2026-05-04
- **Path:** `sources/2026/2026-05/2026-05-04-finrl-investigation.md`
- **URL:** https://github.com/AI4Finance-Foundation/FinRL
