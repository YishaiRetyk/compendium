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
  - "AI4Finance-Foundation/FinRL"
  - "FinRL"
  - "finrl"
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

FinRL is the deep-reinforcement-learning trading framework in this comparison. Technical indicators are first-class engineered features fed into the RL state via a default `INDICATORS` list (MACD, Bollinger upper/lower, RSI-30, CCI-30, DX-30, 30/60-day SMAs) plus VIX and turbulence indices, all backed by `stockstats`. Fundamentals exist as a single application example consuming a static Compustat/WRDS CSV — there is no shipped FA module. Training data is fetched live from 14+ external market-data APIs (no bundled OHLCV); RL agents train from scratch with random initialization on A2C/DDPG/PPO/TD3/SAC across three swappable backends (Stable-Baselines3, ElegantRL, RLlib).

## Key Facts

- FinRL is organized around market environments, DRL agents, and financial applications [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- The report notes that current project positioning treats this repository as the original educational and research framework while pointing production-oriented users to FinRL-X/FinRL-Trading [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Technical indicators are first-class engineered features for the RL state: `finrl/config.py` ships a default `INDICATORS` list (`macd`, `boll_ub`, `boll_lb`, `rsi_30`, `cci_30`, `dx_30`, `close_30_sma`, `close_60_sma`); `FeatureEngineer.add_technical_indicator` is implemented across the data processors via `stockstats` (and `talib` in the Sinopac processor) [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Fundamentals are present as a single example only: `finrl/applications/stock_trading/fundamental_stock_trading.py` consumes a Compustat/WRDS-derived static CSV and computes ratios in-line (OPM, NPM, ROA, ROE, EPS, BPS, DPS, current ratio, quick ratio); no fundamentals module, `add_fundamental_indicator` method, or DCF/comparables logic is shipped [prov:src-2026-05-04-finrl-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- Its strengths are statistically trainable policies, reproducible experiments, backtest framing, and usefulness for reinforcement-learning research [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Its weaknesses are an older coupled architecture, not being the recommended production path, reinforcement-learning overfitting and data-leakage risks, and less natural-language explainability than LLM agents [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Training data is fetched live from external market-data APIs at runtime via per-provider processors under `finrl/meta/data_processors/` (Yahoo via `yfinance`, Alpaca, WRDS/TAQ, CCXT, EODHD, JoinQuant/Tushare, QuantConnect, Sinopac, IBKR); no OHLCV bundle ships with the repo [prov:src-2026-05-04-finrl-investigation#sec:data-sources|direct|2026-05-04] [epistemic:: sourced]
- RL agents are trained from scratch with random initialization, not fine-tuned: `agent.get_model(name)` at `finrl/agents/stablebaselines3/models.py:108-123` returns a brand-new SB3 instance; `*.load` calls appear only in backtest and paper-trading inference scripts, never in training [prov:src-2026-05-04-finrl-investigation#sec:training-paradigm|direct|2026-05-04] [epistemic:: sourced]
- Supported algorithms are A2C, DDPG, PPO, TD3, SAC across three swappable backends (Stable-Baselines3, ElegantRL, RLlib) selectable via `drl_lib`; transfer learning and curriculum learning are absent from the standard pipeline [prov:src-2026-05-04-finrl-investigation#sec:training-paradigm|direct|2026-05-04] [epistemic:: sourced]
- The repository states no hardware requirements (only Python ≥3.7 and macOS/Ubuntu/Windows 10 OS support); training runs CPU-only out of the box because SB3 defaults to `device="auto"` and the example notebooks never request CUDA — a GPU is recommended but not required, and only meaningfully helps the ElegantRL backend and long SB3 runs at the `1e6`-step default [prov:src-2026-05-04-finrl-investigation#sec:hardware-requirements|direct|2026-05-04] [epistemic:: sourced]
- Vectorization is single-process `DummyVecEnv` (no `SubprocVecEnv`, no `n_envs` parameter); the largest memory line item at default hyperparameters is the 1M-step TD3 replay buffer (`finrl/config.py:41-49`), on the order of hundreds of MB [prov:src-2026-05-04-finrl-investigation#sec:hardware-requirements|direct|2026-05-04] [epistemic:: sourced]

## Detail

FinRL fills the formal reinforcement-learning trading experiment role. It is stronger than LLM-agent frameworks when the research question is whether a policy can learn from market states under a defined reward and environment. It is weaker for natural-language explanation and qualitative synthesis [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

The report treats FinRL as complementary to Financial-Models-Numerical-Methods for learning. The notebook collection explains classical financial model mechanics, while FinRL provides an end-to-end sequential decision pipeline [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

### Direct repository inspection (2026-05-04)

The training pipeline in `finrl/train.py` and `finrl/meta/paper_trading/common.py` calls `dp.add_technical_indicator(data, technical_indicator_list)` and feeds `tech_array` into the RL environment, alongside `add_vix` and `add_turbulence`. The same `add_technical_indicator` method appears across 5+ data-processor implementations: `processor_yahoofinance.py`, `processor_alpaca.py`, `processor_wrds.py`, `processor_ccxt.py`, and `processor_sinopac.py` (the last via `talib.get_functions()`) [prov:src-2026-05-04-finrl-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]

The `fundamental_stock_trading.py` example is the only fundamentals usage in the repository. `processor_eodhd.py` references EODHD's `/fundamentals/` endpoint, but only to fetch index *components* (ticker lists), not financial statements. Other applications (cryptocurrency, portfolio allocation, high-frequency, default `stock_trading`) use only TA features. Sentiment, news, and embedding features are absent from the core repo and live in sibling repositories such as FinRL-Meta and FinGPT [prov:src-2026-05-04-finrl-investigation#sec:fundamental-analysis|direct|2026-05-04] [prov:src-2026-05-04-finrl-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

OHLCV ingestion supports 14+ providers (Yahoo, Alpaca, Binance, CCXT, WRDS, EODHD, Sinopac, etc.) [prov:src-2026-05-04-finrl-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

### Training data sources (2026-05-04)

Data-provider modules under `finrl/meta/data_processors/` are unified by `finrl/meta/data_processor.py`: `processor_yahoofinance.py` (Yahoo via `yfinance`, OHLCV daily/intraday), `processor_alpaca.py` (Alpaca US stocks/ETFs OHLCV at 1-min), `processor_wrds.py` (WRDS intraday trades/TAQ), `processor_ccxt.py` (CCXT crypto OHLCV), `processor_eodhd.py` (EOD Historical Data US OHLCV), `processor_joinquant.py` and `processor_tushare` (CN securities OHLCV), `processor_quantconnect.py` and `processor_sinopac.py` (QuantConnect / Taiwan OHLCV). Lighter downloaders under `finrl/meta/preprocessor/` include `yahoodownloader.py`, `tusharedownloader.py`, `shioajidownloader.py`, and `ibkrdownloader.py`. All paths return OHLCV plus derived technicals; the only fundamentals path is a remote CSV (`dow_30_fundamental_wrds.csv`) pulled by `fundamental_stock_trading.py`. Typical flow: `examples/FinRL_StockTrading_2026_1_data.py` → `YahooDownloader.fetch_data()` → `FeatureEngineer.preprocess_data()` at `finrl/applications/stock_trading/stock_trading.py:43-54` [prov:src-2026-05-04-finrl-investigation#sec:data-sources|direct|2026-05-04] [epistemic:: sourced]

### Training paradigm (2026-05-04)

RL agents are trained from scratch with random initialization on each environment. The standard pipeline calls `agent.get_model(name)` at `finrl/agents/stablebaselines3/models.py:108-123` — which returns `MODELS[model_name](policy="MlpPolicy", env=self.env, ...)`, a brand-new SB3 instance — and then `agent.train_model(...)`. `train.py:78-91` (SB3 branch) and `train.py:48-57` (ElegantRL) follow the same pattern. `PPO.load` and `*.load` calls appear only in `examples/FinRL_StockTrading_2026_3_Backtest.py`, `Stock_NeurIPS2018_3_Backtest.ipynb`, and `finrl/meta/paper_trading/alpaca.py` — inference and deployment, never training. A repository-wide grep for `set_parameters` returns zero hits [prov:src-2026-05-04-finrl-investigation#sec:training-paradigm|direct|2026-05-04] [epistemic:: sourced]

The `actor.pth` files shipped at `finrl/applications/cryptocurrency_trading/actor.pth` and `finrl/applications/high_frequency_trading/actor.pth` are demo outputs of prior ElegantRL training runs — they are loaded only by the Alpaca paper-trading deployment script, not by any training pipeline. The only adjacent surface is `finrl/applications/imitation_learning/` (Stock_Selection / Weight_Initialization / Imitation_Sandbox notebooks), an opt-in imitation-then-RL research workflow that is not invoked by `train.py` or any stock_trading example [prov:src-2026-05-04-finrl-investigation#sec:training-paradigm|direct|2026-05-04] [epistemic:: sourced]

### Hardware requirements (2026-05-04)

The repository states no hardware requirements. The README only specifies Python ≥3.7 (`setup.py:50`) and OS support for macOS, Ubuntu, Windows 10 (`README.md:275`); there is no GPU/CPU/RAM section, no training-time commentary, and no Colab badge. `requirements.txt` pulls `stable-baselines3[extra]`, `elegantrl`, and `ray[default]`/`ray[tune]` with no `tensorflow` and no explicit CUDA pin. The `gputil` GPU-monitoring library is included, suggesting authors expect a GPU is sometimes present but do not require one [prov:src-2026-05-04-finrl-investigation#sec:hardware-requirements|direct|2026-05-04] [epistemic:: sourced]

Implicit hardware behavior: the SB3 path at `finrl/agents/stablebaselines3/models.py:125-133` constructs models without passing a `device=` argument, so SB3's default `device="auto"` applies — CUDA if available, else CPU. The ElegantRL path does not set `gpu_id`/`learner_gpus` in `get_model`; the only hardcoded `gpu_id = 0` is inside `DRL_prediction` (evaluation, not training). Vectorization is single-process `DummyVecEnv`. Default hyperparameters are modest: `examples/FinRL_StockTrading_2026_2_train.py` uses `total_timesteps=20000`, while `finrl/train.py:91` defaults to `1e6` (SB3) / `break_step=1e6` (ElegantRL). Replay-buffer sizes are TD3 `1M`, SAC `100k`, DDPG `50k` (`finrl/config.py:41-49`); ElegantRL `batch_size=2048`, `net_dimension=512` (`config.py:50-58`). Bottom line: training runs CPU-only out of the box; a GPU is recommended but not required and only meaningfully helps the ElegantRL backend and long SB3 runs [prov:src-2026-05-04-finrl-investigation#sec:hardware-requirements|direct|2026-05-04] [epistemic:: sourced]

## Related Pages

- [[financial-ai-repository-landscape|Financial AI Repository Landscape]]
- [[financial-ai-repository-tradeoffs|Financial AI Repository Tradeoffs]]
- [[tradingagents|TradingAgents]]
- [[financial-models-numerical-methods|Financial-Models-Numerical-Methods]]
- [[openbb|OpenBB]]

## Sources

- [[src-2026-05-04-financial-ai-repo-comparison-report|Financial AI and Quant Finance Repository Comparison Report]]: "Financial AI and Quant Finance Repository Comparison Report" (2026-05-04)
- [[src-2026-05-04-finrl-investigation|FinRL Repository Investigation Snapshot]]: "FinRL Repository Investigation Snapshot" (2026-05-04)
