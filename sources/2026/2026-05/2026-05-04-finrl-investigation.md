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
