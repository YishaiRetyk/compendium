# Anthropic Financial Services repository investigation snapshot

Captures the shipped artifact set of the anthropics/financial-services-plugins repository, observed via direct repository inspection on 2026-05-04.

## sec:repository

anthropics/financial-services-plugins on GitHub. A Claude Code plugin marketplace of five in-house plugins (`financial-analysis`, `investment-banking`, `equity-research`, `private-equity`, `wealth-management`) plus partner plugins (LSEG, S&P Global) and a `claude-in-office` Excel/PowerPoint add-in bootstrap. Each plugin is a directory of populated SKILL.md prompts, slash commands, hooks, and supporting Python/Office-JS scripts and reference assets.

## sec:technical-analysis

No technical-analysis indicators or chart-pattern skills are shipped. A repo-wide grep for `RSI|MACD|bollinger|moving average|candlestick|chart pattern|ATR|ADX|stochastic|ichimoku|fibonacci|technical analysis|technical indicator` returned only false positives on words like "version", "conversion", "diversified".

The closest adjacencies are LSEG partner-built quantitative-derivatives skills, not equity-chart TA:

- `option-vol-analysis/SKILL.md` (vol surfaces, Greeks, implied-vs-realized, skew/butterflies)
- `bond-futures-basis/SKILL.md` (CTD, implied repo, DV01)
- `swap-curve-strategy/SKILL.md` (2s10s, swap spreads)
- `fx-carry-trade/SKILL.md` (carry-to-vol)
- `bond-relative-value`, `macro-rates-monitor`

The `equity-research/SKILL.md` references OHLCV, beta, and "recent momentum" as a brief context line inside a fundamentals snapshot, not as an indicator computation.

## sec:fundamental-analysis

Fundamental-analysis workflows are first-class implemented artifacts. Real, populated SKILL.md prompts that template the workflow:

- `financial-analysis/skills/dcf-model/SKILL.md` — full DCF with WACC, terminal value, sensitivity; outputs to Excel/Office-JS; supporting `scripts/validate_dcf.py` and `commands/dcf.md`.
- `financial-analysis/skills/comps-analysis/SKILL.md` — comparable-company analysis with multiples and statistical benchmarking; `commands/comps.md`.
- `financial-analysis/skills/3-statement-model/SKILL.md` — IS/BS/CF linked-template completion with formula integrity checks; `commands/3-statement-model.md`.
- `financial-analysis/skills/lbo-model/SKILL.md` — LBO with Sources & Uses, debt schedule, returns; `commands/lbo.md`; `examples/LBO_Model.xlsx` template.
- `financial-analysis/skills/competitive-analysis/`.
- `equity-research/skills/initiating-coverage/` — 5-task workflow including `task2-financial-modeling.md`, `task3-valuation.md`, `valuation-methodologies.md`.
- `equity-research/skills/earnings-analysis/`, `equity-research/skills/model-update/`.
- `investment-banking/skills/merger-model/` — accretion/dilution.
- `partner-built/spglobal/skills/tear-sheet/`.
- `partner-built/lseg/skills/equity-research/` — IBES consensus + fundamentals.

## sec:other

The repository ships actual code beyond prompts: Python validators (e.g., `validate_dcf.py`), Excel templates (e.g., `examples/LBO_Model.xlsx`), Office-JS integration via the `claude-in-office` bootstrap, and slash-command and hook configurations. Plugins are firm-customizable workflow definitions, but they are not "mostly instructions" in the sense of being purely declarative — there is real validation and template scaffolding code shipped alongside.
