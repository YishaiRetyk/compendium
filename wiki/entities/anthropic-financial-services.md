---
id: anthropic-financial-services
title: Anthropic Financial Services
type: entity
status: active
summary: "Claude Code plugin marketplace for professional finance workflows. Ships populated SKILL.md prompts for DCF, comps, 3-statement, LBO, merger model, initiating coverage, earnings analysis, and tear-sheet — alongside Python validators, Excel templates, and an Office add-in bootstrap."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-05-04-financial-ai-repo-comparison-report
  - src-2026-05-04-anthropic-financial-services-investigation
epistemic_status: sourced
tags:
  - financial-ai
  - claude-plugin
  - professional-workflows
  - fundamental-analysis
  - investment-banking
domains:
  - financial-ai
  - software
supersedes:
superseded_by:
privacy: cloud_safe
aliases:
  - anthropics/financial-services
  - financial-services-plugins
has_contradictions: false
knowledge_domain: software
example: false
---

## TL;DR

Anthropic Financial Services packages Claude-native finance workflows as a plugin marketplace. It ships five in-house plugins (`financial-analysis`, `investment-banking`, `equity-research`, `private-equity`, `wealth-management`) plus partner plugins (LSEG, S&P Global) and a `claude-in-office` Excel/PowerPoint add-in bootstrap. Fundamental-analysis workflows are first-class artifacts: DCF, comps, 3-statement, LBO, merger model, initiating coverage, earnings analysis, model update, tear-sheet — each a populated SKILL.md with supporting Python validators and Excel templates. No technical-analysis indicators or chart-pattern skills are shipped.

## Key Facts

- The repository is described as Claude plugins for workflows including core financial analysis, investment banking, equity research, private equity, wealth management, partner-built data plugins, and Office add-in deployment [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Its method is file-based plugin packaging with skills, connectors, slash commands, sub-agents, and MCP integrations [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:high-level-map|direct|2026-05-04] [epistemic:: sourced]
- FA workflows are implemented as populated SKILL.md prompts plus supporting code: `financial-analysis/skills/{dcf-model, comps-analysis, 3-statement-model, lbo-model, competitive-analysis}`, `equity-research/skills/{initiating-coverage, earnings-analysis, model-update}`, `investment-banking/skills/merger-model` (accretion/dilution), `partner-built/spglobal/skills/tear-sheet`, and `partner-built/lseg/skills/equity-research` (IBES consensus + fundamentals) [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]
- The repository ships actual code beyond prompts: Python validators (e.g., `scripts/validate_dcf.py`), Excel templates (e.g., `examples/LBO_Model.xlsx`), Office-JS integration via `claude-in-office`, and slash-command and hook configurations [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:other|direct|2026-05-04] [epistemic:: sourced]
- No equity-chart technical-analysis indicators or chart-pattern skills are shipped; the closest adjacencies are LSEG quantitative-derivatives skills (`option-vol-analysis`, `bond-futures-basis`, `swap-curve-strategy`, `fx-carry-trade`) covering rates and derivatives strategy [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]
- Its strengths are direct mapping to finance professional deliverables, templates, commands, and firm-customizable workflows [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: sourced]
- Its weaknesses are Claude ecosystem specificity, possible subscription requirements for connectors, and the fact that it is mostly instructions and configuration rather than standalone compute or modeling code [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:repo-evaluations|direct|2026-05-04] [epistemic:: stale] (the "mostly instructions and configuration" portion is superseded by the 2026-05-04 inspection findings — populated SKILL.md prompts ship alongside Python validators, Excel templates, and Office-JS integration)

## Detail

Anthropic Financial Services overlaps with Dexter as an AI-assisted financial research and analysis workflow, but the report distinguishes them by packaging layer. Dexter is a standalone autonomous research agent, while Anthropic Financial Services provides Claude-embedded workflows for reports, models, memos, decks, and role-specific deliverables [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:overlapping-purpose-tradeoffs|direct|2026-05-04] [epistemic:: sourced]

The intended use is strongest in teams that already operate inside Claude and want standardized financial-services outputs. Its customization surface is workflow and firm process definition, not model-training or data-platform construction [prov:src-2026-05-04-financial-ai-repo-comparison-report#sec:practical-selection|direct|2026-05-04] [epistemic:: sourced]

### Direct repository inspection (2026-05-04)

The repository (`anthropics/financial-services-plugins`) is a Claude Code plugin marketplace. Each plugin is a directory of populated SKILL.md prompts, slash commands, hooks, and supporting Python/Office-JS scripts and reference assets. `financial-analysis/skills/dcf-model/SKILL.md` ships a full DCF with WACC, terminal value, sensitivity, and Excel/Office-JS output, plus `scripts/validate_dcf.py` and `commands/dcf.md`. `lbo-model/SKILL.md` adds Sources & Uses, debt schedule, and returns calculations, with `commands/lbo.md` and an `examples/LBO_Model.xlsx` template. `comps-analysis` adds comparable-company analysis with multiples and statistical benchmarking, and `3-statement-model` adds linked IS/BS/CF template completion with formula integrity checks [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]

The `equity-research/skills/initiating-coverage` skill follows a 5-task workflow with `task2-financial-modeling.md`, `task3-valuation.md`, and `valuation-methodologies.md`. `equity-research/skills/{earnings-analysis, model-update}` and `investment-banking/skills/merger-model` (accretion/dilution) round out the in-house coverage. Partner-built plugins from S&P Global (`tear-sheet`) and LSEG (`equity-research` with IBES consensus and fundamentals) extend the surface [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:fundamental-analysis|direct|2026-05-04] [epistemic:: sourced]

A repo-wide grep for TA indicator names returns only false positives ("version", "conversion", "diversified"). The closest TA adjacencies are LSEG partner skills covering options vol surfaces, bond-futures basis, swap curves, and FX carry — quantitative rates and derivatives strategy, not equity-chart TA. The `equity-research/SKILL.md` references OHLCV, beta, and "recent momentum" as a brief context line inside a fundamentals snapshot, not as an indicator computation [prov:src-2026-05-04-anthropic-financial-services-investigation#sec:technical-analysis|direct|2026-05-04] [epistemic:: sourced]

## Related Pages

- [[Financial AI Repository Landscape]]
- [[Financial AI Repository Tradeoffs]]
- [[Dexter]]
- [[TradingAgents]]
- [[OpenBB]]

## Sources

- [[Financial AI and Quant Finance Repository Comparison Report]]: "Financial AI and Quant Finance Repository Comparison Report" (2026-05-04)
- [[Anthropic Financial Services Repository Investigation Snapshot]]: "Anthropic Financial Services Repository Investigation Snapshot" (2026-05-04)
