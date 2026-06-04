---
id: src-2026-05-04-anthropic-financial-services-investigation
title: "Anthropic Financial Services Repository Investigation Snapshot"
type: source
status: active
summary: "Direct repository inspection of anthropics/financial-services-plugins confirming
  the repository ships populated FA SKILL.md prompts, Python validators, and Excel
  templates — not just instructions and configuration."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: sourced
tags:
- financial-ai
- repository-investigation
- claude-plugin
domains:
- financial-ai
- software
supersedes: null
superseded_by: null
aliases:
- "Anthropic Financial Services Investigation"
- "Anthropic Financial Services Repository Investigation Snapshot"
- "src-2026-05-04-anthropic-financial-services-investigation"
has_contradictions: false
knowledge_domain: software
example: false
path: 
  sources/2026/2026-05/2026-05-04-anthropic-financial-services-investigation.md
url: "https://github.com/anthropics/financial-services-plugins"
content_hash: "sha256:8d5c34d58f90738cd2831a4e942a2d9dd29d3e16f64279ed014127a6a55468c5"
ingested_at: 2026-05-04
source_type: article
compilation_status: compiled
compiled_against_hash: "sha256:8d5c34d58f90738cd2831a4e942a2d9dd29d3e16f64279ed014127a6a55468c5"
compiled_targets:
- anthropic-financial-services
- financial-ai-repository-tradeoffs
- financial-ai-repository-landscape
---

## TL;DR

The repository ships five in-house plugins (`financial-analysis`, `investment-banking`, `equity-research`, `private-equity`, `wealth-management`) plus partner plugins (LSEG, S&P Global) and a `claude-in-office` Excel/PowerPoint add-in bootstrap. FA workflows are first-class implemented artifacts: DCF, comps, 3-statement, LBO, merger model, initiating coverage, earnings analysis, model update, tear-sheet — each a populated SKILL.md with supporting Python validators and Excel templates. No TA indicators or chart-pattern skills are shipped.

## Key Takeaways

- A repo-wide grep for TA indicator names returns only false positives ("version", "conversion", "diversified"); no equity-chart TA is shipped [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- The closest TA adjacencies are LSEG partner-built quantitative-derivatives skills (option-vol-analysis, bond-futures-basis, swap-curve-strategy, fx-carry-trade) — rates and derivatives strategy, not equity-chart TA [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- FA workflows are implemented as populated SKILL.md prompts plus supporting code: dcf-model, comps-analysis, 3-statement-model, lbo-model, competitive-analysis, initiating-coverage, earnings-analysis, model-update, merger-model, tear-sheet, partner LSEG equity-research [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- The repository ships actual code beyond prompts: Python validators (e.g., `validate_dcf.py`), Excel templates (e.g., `examples/LBO_Model.xlsx`), and Office-JS integration via `claude-in-office` [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]

## Extracted Claims

- "`financial-analysis/skills/dcf-model/SKILL.md` — full DCF with WACC, terminal value, sensitivity, Excel/Office-JS output, plus `scripts/validate_dcf.py` and `commands/dcf.md`" [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:fundamental-analysis|direct|2026-05-04]
- "`investment-banking/skills/merger-model` (accretion/dilution); `partner-built/spglobal/skills/tear-sheet`; `partner-built/lseg/skills/equity-research` (IBES consensus + fundamentals)" [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:fundamental-analysis|direct|2026-05-04]

## Notes

Compiled into [[anthropic-financial-services|Anthropic Financial Services]], [[financial-ai-repository-tradeoffs|Financial AI Repository Tradeoffs]], and [[financial-ai-repository-landscape|Financial AI Repository Landscape]]. Supersedes the comparison-report-derived claim that the repository is "mostly instructions and configuration rather than standalone compute or modeling code" by documenting the validators, templates, and Office-JS integration shipped alongside the SKILL.md prompts.

## Source Metadata

- **Source type:** article (repository inspection snapshot)
- **Authors:** investigation agent (via direct GitHub fetch)
- **Published:** 2026-05-04
- **Path:** `sources/2026/2026-05/2026-05-04-anthropic-financial-services-investigation.md`
- **URL:** https://github.com/anthropics/financial-services-plugins
