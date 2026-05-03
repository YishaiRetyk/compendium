# FinRL repository investigation snapshot

Captures the shipped feature-engineering and analytical surface of the FinRL repository, observed via direct repository inspection on 2026-05-04.

## sec:repository

AI4Finance-Foundation/FinRL on GitHub (default branch `master`). Deep reinforcement learning trading framework organized around three layers: market environments, DRL agents, and financial applications. Data ingestion goes through a `DataProcessor` interface implemented by per-provider modules under `finrl/meta/preprocessor/` and `finrl/meta/data_processors/`.

## sec:technical-analysis

Technical indicators are first-class engineered features fed into the RL state, not optional add-ons.

- `finrl/config.py` ships a default `INDICATORS` list: `macd`, `boll_ub`, `boll_lb`, `rsi_30`, `cci_30`, `dx_30`, `close_30_sma`, `close_60_sma` (MACD, Bollinger upper/lower, RSI-30, CCI-30, DX-30, 30/60-day simple moving averages).
- `finrl/meta/preprocessor/preprocessors.py` defines `FeatureEngineer.add_technical_indicator(...)` using the `stockstats` package.
- The same method is implemented across data processors: `processor_yahoofinance.py`, `processor_alpaca.py`, `processor_wrds.py`, `processor_ccxt.py`, and `processor_sinopac.py` (which calls `talib.get_functions()`).
- The training pipeline in `finrl/train.py` and `finrl/meta/paper_trading/common.py` calls `dp.add_technical_indicator(data, technical_indicator_list)` and feeds `tech_array` into the RL environment, alongside `add_vix` (volatility) and `add_turbulence`.

## sec:fundamental-analysis

Fundamentals exist as a single example, not a shipped FA module.

- `finrl/applications/stock_trading/fundamental_stock_trading.py` consumes a Compustat/WRDS-derived static CSV (`mariko-sawada/FinRL_with_fundamental_data/dow_30_fundamental_wrds.csv`) and computes ratios in-line: OPM, NPM, ROA, ROE, EPS, BPS, DPS, current ratio, quick ratio (and additional leverage and valuation ratios). These features are appended to the RL state.
- There is no fundamentals module, no `add_fundamental_indicator` method on the data processors, no DCF/comparables/DDM logic, no general-purpose financial-statement parser.
- Other applications (cryptocurrency, portfolio allocation, high-frequency, default `stock_trading`) use only TA features.
- `processor_eodhd.py` references EODHD's `/fundamentals/` endpoint, but only to fetch index *components* (ticker lists), not financial statements.

## sec:other

Volatility and turbulence indices: `add_vix`, `add_turbulence`. OHLCV ingestion supports 14+ providers (Yahoo, Alpaca, Binance, CCXT, WRDS, EODHD, Sinopac, etc.). No sentiment/news/embedding features in the core repo; those live in sibling repositories such as FinRL-Meta and FinGPT.

## sec:data-sources

FinRL fetches data live at runtime from external market-data APIs — no OHLCV bundle ships in the repo. Data-provider modules under `finrl/meta/data_processors/` (raw OHLCV fetchers, all unified by `finrl/meta/data_processor.py`):

- `processor_yahoofinance.py` — Yahoo via `yfinance`, OHLCV daily/intraday
- `processor_alpaca.py` — Alpaca US stocks/ETFs OHLCV (1-min)
- `processor_wrds.py` — WRDS intraday trades / TAQ
- `processor_ccxt.py` — CCXT crypto OHLCV
- `processor_eodhd.py` — EOD Historical Data US OHLCV
- `processor_joinquant.py` / `processor_tushare` (in `preprocessor/`) — CN securities OHLCV
- `processor_quantconnect.py`, `processor_sinopac.py` — QuantConnect / Taiwan OHLCV

Lighter downloaders under `finrl/meta/preprocessor/`: `yahoodownloader.py`, `tusharedownloader.py`, `shioajidownloader.py`, `ibkrdownloader.py`. `preprocessors.py` adds technical indicators (MACD, RSI, Bollinger via `stockstats`), VIX, and turbulence — not raw fetch.

All paths are OHLCV + derived technicals. The only fundamentals path is a remote CSV (`dow_30_fundamental_wrds.csv`) pulled by `fundamental_stock_trading.py`. Typical flow: `examples/FinRL_StockTrading_2026_1_data.py` → `YahooDownloader.fetch_data()` → `FeatureEngineer.preprocess_data()` at `finrl/applications/stock_trading/stock_trading.py:43-54`.

## sec:training-paradigm

RL agents are trained from scratch with random initialization. Every standard pipeline calls `agent.get_model(name)` to instantiate a fresh SB3 / ElegantRL / RLlib model, then `agent.train_model(...)`. No checkpoint is loaded into training.

- `finrl/agents/stablebaselines3/models.py:108-123` — `get_model` returns `MODELS[model_name](policy="MlpPolicy", env=self.env, ...)`, a brand-new SB3 instance.
- `train.py:78-91` (SB3 branch) and `train.py:48-57` (ElegantRL) follow the same pattern.
- `PPO.load` / `*.load` calls appear only in `examples/FinRL_StockTrading_2026_3_Backtest.py`, `Stock_NeurIPS2018_3_Backtest.ipynb`, and `finrl/meta/paper_trading/alpaca.py` — inference and deployment, never training.
- `grep set_parameters` returns zero hits across the repo.

Shipped checkpoints are demo *outputs*, not training inputs: `finrl/applications/cryptocurrency_trading/actor.pth` and `finrl/applications/high_frequency_trading/actor.pth` (plus `recorder.npy`). They are loaded only by the Alpaca paper-trading deployment script, not by any training pipeline.

Algorithms: A2C, DDPG, PPO, TD3, SAC. Three backends selectable via `drl_lib`: Stable-Baselines3 (`finrl/agents/stablebaselines3/models.py`, `MODELS = {a2c, ddpg, td3, sac, ppo}`), ElegantRL (`finrl/agents/elegantrl/models.py`), RLlib (`finrl/agents/rllib/models.py`). All three listed in `requirements.txt`.

Transfer learning and curriculum learning are absent from the standard RL pipeline. The only related surface is `finrl/applications/imitation_learning/` (Stock_Selection / Weight_Initialization / Imitation_Sandbox notebooks) — an opt-in imitation-then-RL research workflow that is not invoked by `train.py` or any stock_trading example.
