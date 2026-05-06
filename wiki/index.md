---
id: index
title: Index
type: overview
status: active
summary: "Skeleton index — ingested content will appear here organized by knowledge domain."
created_at: 2026-04-15
updated_at: 2026-05-06
sources: []
epistemic_status: sourced
tags:
  - meta
domains:
  - wiki-infrastructure
privacy: cloud_safe
knowledge_domain: software
neutrality_exempt: true  # The ## Decisions section must reference dr-2026-04-15-kahneman-to-examples by its canonical slug; the wikilink target is structurally fixed and §8 rule 3 forbids display aliases. Narrow exemption for the DR catalog.
---

# Index

Content is organized by page type. See `AGENTS.md §2 Directory Structure` for layout conventions.

## Entities

- [[Hack (Agentive Stack)]] — Product engineer turned founder; YouTube creator publishing on AI-assisted software engineering practices (sourced, 2026-05-04)
- [[Eric Evans]] — Author of *Domain-Driven Design* (2003) (mixed, 2026-05-04)
- [[Peter Naur]] — Danish computer scientist; author of *Programming as Theory Building* (1985) (mixed, 2026-05-04)
- [[OpenBB]] — Open-source financial data platform with native TA and FA router modules (sourced, 2026-05-04)
- [[Dexter]] — Autonomous financial research agent specialized for fundamentals and DCF valuation (sourced, 2026-05-04)
- [[FinRL]] — Deep reinforcement-learning trading framework with TA features as RL state inputs (sourced, 2026-05-04)
- [[TradingAgents]] — Multi-agent LLM trading research framework with grounded TA and FA agents (sourced, 2026-05-04)
- [[Anthropic Financial Services]] — Claude Code plugin marketplace for professional FA workflows (sourced, 2026-05-06)
- [[Financial-Models-Numerical-Methods]] — Educational quantitative finance notebook collection covering derivatives pricing and stochastic processes (sourced, 2026-05-04)
- [[Anthropic]] — AI safety company that builds Claude; ships the Claude API, Claude Code, and Claude.ai plus pre-built and Custom Agent Skills (sourced, 2026-05-06)
- [[Claude Code]] — Anthropic's CLI for Claude (terminal, desktop, web, IDE); custom-only Agent Skills mounted at ~/.claude/skills/ or .claude/skills/ (sourced, 2026-05-06)
- [[Claude API]] — Anthropic's HTTP API surface; pre-built and custom Agent Skills via container.skills + code_execution_20250825 tool with three required betas (sourced, 2026-05-06)

## Concepts

- [[Systems Thinking]] — The day-one skill for AI-assisted software development: reasoning about how parts of a system affect each other (sourced, 2026-05-04)
- [[Comprehension Debt]] — Cumulative cost of shipping AI-generated code the team doesn't understand; aliased to "cognitive debt" (sourced, 2026-05-04)
- [[Programming as Theory Building]] — Peter Naur's 1985 paper: the program is the theory in the head, the code is its shadow (mixed, 2026-05-04)
- [[Jagged Frontier]] — AI capability shape: sharp in some places, dull in others, sometimes within a single session (mixed, 2026-05-04)
- [[Ubiquitous Language]] — DDD artifact: project glossary functioning as a contract between humans, code, and AI (sourced, 2026-05-04)
- [[Bounded Context]] — DDD artifact: a distinct area of a system with its own rules and stable term meanings (sourced, 2026-05-04)
- [[Documented Contract]] — DDD artifact: written-down handshake between bounded contexts (sourced, 2026-05-04)
- [[Progressive Disclosure]] — Three-level loading pattern in Anthropic Agent Skills: metadata always, instructions when triggered, resources as needed (sourced, 2026-05-06)

## Sources

- [[Is this the only skill left?]] — Hack (Agentive Stack), 2026-05-03 — YouTube transcript on systems thinking as the durable skill in AI-assisted development (sourced, 2026-05-04)
- [[Three artifacts that changed how I build with AI]] — Hack (Agentive Stack), 2026-05-04 — YouTube transcript on DDD reduced to three artifacts for AI-coding workflows (sourced, 2026-05-04)
- [[Financial AI and Quant Finance Repository Comparison Report]] — Comparison report mapping six finance-related open-source repositories (sourced, 2026-05-04)
- [[OpenBB Repository Investigation Snapshot]] — Direct repository inspection capturing OpenBB's TA, FA, and other extension surface (sourced, 2026-05-04)
- [[FinRL Repository Investigation Snapshot]] — Direct repository inspection capturing FinRL's TA-indicator-as-RL-state pipeline (sourced, 2026-05-04)
- [[TradingAgents Repository Investigation Snapshot]] — Direct repository inspection of TradingAgents' market_analyst and fundamentals_analyst agents (sourced, 2026-05-04)
- [[Financial-Models-Numerical-Methods Repository Investigation Snapshot]] — Direct repository inspection of all 22 notebooks confirming derivatives focus (sourced, 2026-05-04)
- [[Dexter Repository Investigation Snapshot]] — Direct repository inspection confirming Dexter is FA-only with a DCF skill (sourced, 2026-05-04)
- [[Anthropic Financial Services Repository Investigation Snapshot]] — Direct repository inspection confirming populated FA SKILL.md prompts plus Python validators and Excel templates (sourced, 2026-05-04)
- [[Anthropic Agent Skills Overview]] — Anthropic's docs page introducing Agent Skills as filesystem-based directories with three-level progressive disclosure across Claude API, Claude Code, and Claude.ai (sourced, 2026-05-06)
- [[Anthropic Agent Skills Quickstart]] — Anthropic's API tutorial for invoking pre-built Agent Skills via the Messages API container parameter and downloading generated files via the Files API (sourced, 2026-05-06)
- [[Anthropic Agent Skills Best Practices]] — Anthropic's authoring guide for SKILL.md: under 500 lines, third-person descriptions, references one level deep, evals before docs, Claude-A-writes-for-Claude-B iteration loop (sourced, 2026-05-06)
- [[Introduction to Claude Skills (claude-cookbooks notebook 01)]] — Anthropic claude-cookbooks notebook with concrete SDK call shape (client.beta.messages.create + betas= parameter), required SDK version (anthropic>=0.71.0), and observed generation times (sourced, 2026-05-06)
- [[Building Custom Skills for Claude (claude-cookbooks notebook 03)]] — Anthropic claude-cookbooks notebook on custom-Skill upload (skills.create + files_from_dir), display_title workspace-uniqueness, type:'custom' container discriminator, versioning lifecycle, and skill composition (sourced, 2026-05-06)

## Comparisons

- [[Financial AI Repository Tradeoffs]] — Tradeoff comparison for finance repositories with TA/FA analysis-style coverage (mixed, 2026-05-04)

## Overviews

- [[Domain-Driven Design]] — 2003 methodology by Eric Evans, re-discovered for AI-assisted development as a remedy for context loss between AI sessions (mixed, 2026-05-04)
- [[Financial AI Repository Landscape]] — Synthesis of six finance-related repositories as a layered ecosystem (mixed, 2026-05-04)
- [[Agent Skills]] — Filesystem-based capability packages (SKILL.md + bundled code/refs) loaded via three-level progressive disclosure across Claude API, Claude Code, and Claude.ai (sourced, 2026-05-06)

## Decisions

- [[dr-2026-04-14-phase6-decision-type]] — Introduce Decision Record Page Type (schema-update, 2026-04-14)
- [[dr-2026-04-15-kahneman-to-examples]] — Relocate the personal-domain test-fixture cluster from wiki/ to examples/ (schema-update, 2026-04-15)
- [[dr-2026-04-16-progressive-disclosure-extraction]] — Extract §4 Worked Examples and §16 Appendices (schema-update, 2026-04-16)
- [[Brownfield Apply-vs-Advisory Architecture + Review-Manifest Pattern]] — Captures the apply-class vs advisory-class split, review-manifest pattern, bootstrap_stage lifecycle gate, and cross-AI review-feedback hardenings (items 1–11) (sourced, 2026-04-20)
- [[dr-2026-05-01-complementary-systems-boundary]] — Compendium owns durable, provenance-backed wiki memory and review support; complementary systems own task execution, reminders, calendars, and transactional state. (sourced, 2026-05-01)
