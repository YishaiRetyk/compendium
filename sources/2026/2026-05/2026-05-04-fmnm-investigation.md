# Financial-Models-Numerical-Methods repository investigation snapshot

Captures the actual scope of the Financial-Models-Numerical-Methods repository, observed via direct repository inspection on 2026-05-04.

## sec:repository

cantaro86/Financial-Models-Numerical-Methods on GitHub. A Jupyter notebook collection enumerated via the GitHub contents API: 22 notebooks (1.1–7.1 plus appendices A.1–A.3).

## sec:technical-analysis

No notebook computes classical technical-analysis indicators. There is no RSI, MACD, Bollinger Bands, moving-average crossovers, ATR, ADX, candlestick-pattern detection, or chart-based price/volume signal logic anywhere in the collection.

The closest adjacencies are model-based, not chart-based:

- `6.1 Ornstein-Uhlenbeck process and applications.ipynb` includes a "Trading strategy" section implementing pairs-trading / statistical-arbitrage bands around the long-term mean of a fitted OU SDE. This is stat-arb on a calibrated stochastic process, not chart-pattern TA.
- `5.1 Linear regression - Kalman filter.ipynb` and `5.3 Volatility tracking.ipynb` extract latent state from price series — signal extraction, not TA indicators.

## sec:fundamental-analysis

Zero notebooks parse financial statements, compute valuation ratios (P/E, ROE, debt/equity), build DCF/DDM models, or analyze earnings/balance-sheet/cash-flow data. The repository never touches issuer fundamentals. Macro indicators are absent.

## sec:other

The repository is a derivatives-pricing and stochastic-process pedagogy collection:

- Black-Scholes, PDE/PIDE methods, Fourier inversion
- Heston, Merton, Variance Gamma (VG), Normal Inverse Gaussian (NIG) Lévy processes
- American and exotic options
- Transaction costs
- Kalman filtering of price-series latent states
- Ornstein-Uhlenbeck and Vasicek processes (with the pairs-trading example noted above)
- Classical mean-variance optimization (`7.1 Classical MVO.ipynb`)

It is a numerical-methods-for-quant-finance pedagogy repo, not a TA, FA, or trading-system repo.
