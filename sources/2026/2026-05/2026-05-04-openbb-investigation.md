# OpenBB repository investigation snapshot

Captures the shipped financial-reasoning surface of the OpenBB platform repository, observed via direct repository inspection on 2026-05-04.

## sec:repository

OpenBB-finance/OpenBB on GitHub. Open-source financial platform organized as a Python package (`openbb_platform/`) with a router-based extension model: each functional area (equity, technical, fundamental, quantitative, derivatives, news, etc.) is a separate extension package that can be installed independently and registers commands via `@router.command()`.

## sec:technical-analysis

Ships a dedicated `technical` extension at `openbb_platform/extensions/technical/openbb_technical/technical_router.py`. The router exposes named indicator commands as first-class API endpoints:

- Bollinger Bands: `bbands`
- MACD: `macd`
- Moving averages: `sma`, `hma`, `zlma`
- Average True Range: `atr`
- On Balance Volume: `obv`
- Volume-weighted average price: `vwap`
- Aroon: `aroon`
- Fisher Transform: `fisher`
- Chaikin Oscillator: `adosc`
- Fibonacci Retracement: `fib`
- DeMark: `demark`
- Relative Rotation: `relative_rotation`

Installable as a standalone package: `pip install openbb-technical`. A sibling `charting` extension consumes these endpoints. Indicator computations are real Python implementations, not provider passthroughs.

## sec:fundamental-analysis

Ships a dedicated `fundamental` submodule under the `equity` extension at `openbb_platform/extensions/equity/openbb_equity/fundamental/fundamental_router.py`. Router commands include:

- Financial statements: `balance`, `income`, `cash`
- Period-over-period growth: `balance_growth`, `income_growth`, `cash_growth`
- `ratios` (described as "extensive set of financial and accounting ratios")
- `metrics` (fundamental metrics)
- `dividends`, `historical_eps`, `trailing_dividend_yield`
- `management_compensation`, `revenue_per_geography`, `revenue_per_segment`
- `filings` (SEC filings)
- `transcript` (earnings call transcripts)
- `esg_score`

Caveat: ratio formulas and growth calculations are largely delegated to upstream provider APIs (Intrinio, FMP, etc.) via the standardized provider interface. OpenBB ships the schema, router, and data normalization. No DCF or valuation-model endpoint is shipped natively.

## sec:other

Additional first-class extensions: `quantitative/` (performance, rolling stats), `econometrics/`, `economy/` (macro indicators), `derivatives/` (options chains and Greeks via providers), `news/` (headline data), `fixedincome/`, `etf/`, `crypto/`, `currency/`, `famafrench/` (factor data), `regulators/`. Sentiment analysis is not a shipped first-class extension — only news data exposure.
