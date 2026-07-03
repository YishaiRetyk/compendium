---
id: index
title: Index
type: overview
status: active
summary: "Skeleton index — ingested content will appear here organized by knowledge
  domain."
created_at: 2026-04-15
updated_at: 2026-07-03
sources: []
epistemic_status: sourced
tags:
- meta
domains:
- wiki-infrastructure
knowledge_domain: software
neutrality_exempt: true  # The ## Decisions section must reference dr-2026-04-15-kahneman-to-examples by its canonical slug; the wikilink target is structurally fixed and §8 rule 3 forbids display aliases. Narrow exemption for the DR catalog.
---

# Index

Content is organized by page type. See `AGENTS.md §2 Directory Structure` for layout conventions.

## Entities

- [[hack-agentive-stack|Hack (Agentive Stack)]] — Product engineer turned founder; YouTube creator publishing on AI-assisted software engineering practices (sourced, 2026-05-04)
- [[eric-evans|Eric Evans]] — Author of *Domain-Driven Design* (2003) (mixed, 2026-05-04)
- [[peter-naur|Peter Naur]] — Danish computer scientist; author of *Programming as Theory Building* (1985) (mixed, 2026-05-04)
- [[openbb|OpenBB]] — Open-source financial data platform with native TA and FA router modules (sourced, 2026-05-04)
- [[dexter|Dexter]] — Autonomous financial research agent specialized for fundamentals and DCF valuation (sourced, 2026-05-04)
- [[finrl|FinRL]] — Deep reinforcement-learning trading framework with TA features as RL state inputs (sourced, 2026-05-04)
- [[tradingagents|TradingAgents]] — Multi-agent LLM trading research framework with grounded TA and FA agents (sourced, 2026-05-04)
- [[anthropic-financial-services|Anthropic Financial Services]] — Claude Code plugin marketplace for professional FA workflows (sourced, 2026-05-06)
- [[financial-models-numerical-methods|Financial-Models-Numerical-Methods]] — Educational quantitative finance notebook collection covering derivatives pricing and stochastic processes (sourced, 2026-05-04)
- [[anthropic|Anthropic]] — AI safety company that builds Claude; ships the Claude API, Claude Code, and Claude.ai plus pre-built and Custom Agent Skills (sourced, 2026-05-06)
- [[claude-code|Claude Code]] — Anthropic's CLI for Claude (terminal, desktop, web, IDE); custom-only Agent Skills mounted at ~/.claude/skills/ or .claude/skills/ (sourced, 2026-05-06)
- [[claude-api|Claude API]] — Anthropic's HTTP API surface; pre-built and custom Agent Skills via container.skills + code_execution_20250825 tool with three required betas (sourced, 2026-05-06)
- [[geoffrey-huntley|Geoffrey Huntley]] — Software engineer who originated the "Ralph" autonomous-coding-loop technique (sourced, 2026-05-06)
- [[olmocr|olmOCR]] — Ai2's open-source self-hostable VLM document converter (Qwen2.5-VL-7B fine-tune); headline PDF-to-Markdown self-hosting pick, 82.4 on olmOCR-Bench (mixed, 2026-06-09)
- [[omnidocbench|OmniDocBench]] — Authoritative CVPR 2025 benchmark for diverse PDF document parsing (~1,651 pages, ~10 doc types, end-to-end/task/attribute modes) (mixed, 2026-06-09)
- [[spec-kit|Spec Kit]] — GitHub's official spec-driven-development toolkit (CLI "Specify"); tool-agnostic across 20+ agents, spec is the version-controlled source of truth (mixed, 2026-06-09)
- [[superpowers|Superpowers]] — Jesse Vincent's Claude Code framework enforcing a mandatory brainstorm→plan→implement→review skill chain with a SessionStart re-priming hook (mixed, 2026-06-09)
- [[gsd|GSD (Get-Shit-Done)]] — Context-engineering orchestrator (originated by TÂCHES, continued as GSD Core under OpenGSD): every task in a fresh 200K subagent context, coordinated via a .planning/ artifact tree (mixed, 2026-07-03)
- [[demis-hassabis|Demis Hassabis]] — Co-founder and CEO of Google DeepMind; took the more cautious side on AGI timelines in a 2026 stage debate (sourced, 2026-06-14)
- [[dario-amodei|Dario Amodei]] — Co-founder and CEO of Anthropic; took the faster side on AGI timelines and reiterated his no-chips-to-adversaries policy (sourced, 2026-06-14)
- [[elastic|Elastic]] — Search company behind Elasticsearch and its ES|QL query language; frames agentic-search tool design around a low-floor/high-ceiling stack (sourced, 2026-07-03)
- [[leonie-monigatti|Leonie Monigatti]] — Retrieval/search practitioner at Elastic; argued context engineering is "about 80% agentic search" in an AI Engineer conference talk (sourced, 2026-07-03)
- [[symphony|Symphony]] — OpenAI's spec-first coding-agent orchestration service: a long-running daemon that turns Linear issues into isolated per-issue Codex runs via a single-authority orchestrator; shipped as a SPEC.md you regenerate into code (mixed, 2026-07-03)
- [[openai|OpenAI]] — The AI company behind Symphony, the Codex coding agent, and the "harness engineering" framing; stub sourced via the Symphony spec (mixed, 2026-07-03)
- [[codex|Codex]] — OpenAI's coding agent, integrated via an app-server protocol (stdio subprocess, thread/turn session model); the agent Symphony drives (mixed, 2026-07-03)
- [[matt-pocock|Matt Pocock]] — Developer educator and author of the "Matt Pocock Skills" repo; proposed the four-part skill checklist (Trigger/Structure/Steering/Pruning) and a prefer-user-invoked authoring stance (sourced, 2026-07-03)

## Concepts

- [[systems-thinking|Systems Thinking]] — The day-one skill for AI-assisted software development: reasoning about how parts of a system affect each other (sourced, 2026-05-04)
- [[comprehension-debt|Comprehension Debt]] — Cumulative cost of shipping AI-generated code the team doesn't understand; aliased to "cognitive debt" (sourced, 2026-05-04)
- [[programming-as-theory-building|Programming as Theory Building]] — Peter Naur's 1985 paper: the program is the theory in the head, the code is its shadow (mixed, 2026-05-04)
- [[jagged-frontier|Jagged Frontier]] — AI capability shape: sharp in some places, dull in others, sometimes within a single session (mixed, 2026-05-04)
- [[ubiquitous-language|Ubiquitous Language]] — DDD artifact: project glossary functioning as a contract between humans, code, and AI (sourced, 2026-05-04)
- [[bounded-context|Bounded Context]] — DDD artifact: a distinct area of a system with its own rules and stable term meanings (sourced, 2026-05-04)
- [[documented-contract|Documented Contract]] — DDD artifact: written-down handshake between bounded contexts (sourced, 2026-05-04)
- [[progressive-disclosure|Progressive Disclosure]] — Three-level loading pattern in Anthropic Agent Skills (metadata always, instructions when triggered, resources as needed); also a general context-engineering principle shared by the Ralph autonomous-loop playbook, now with an explicit skill-eviction step from Elastic's agentic-search practice (mixed, 2026-07-03)
- [[ralph-loop|Ralph (Autonomous Coding Loop)]] — Geoffrey Huntley's minimal autonomous-coding pattern: bash `while` loop + fixed PROMPT.md + IMPLEMENTATION_PLAN.md on disk as cross-iteration shared state (sourced, 2026-05-06)
- [[backpressure|Backpressure]] — Downstream rejection signals (tests, typechecks, lints, builds, LLM-as-judge) that block invalid agent output before commit (sourced, 2026-05-06)
- [[vlm-ocr-hallucination|VLM OCR Hallucination]] — Vision-language models default to linguistic priors on degraded document images, emitting plausible-but-wrong text instead of flagging unreadability (sourced, 2026-06-09)
- [[spec-driven-development|Spec-Driven Development]] — Methodology where the spec is the version-controlled source of truth and code is a regenerable expression; implemented by Spec Kit, and taken to the distribution layer by OpenAI's Symphony (mixed, 2026-07-03)
- [[subagents|Subagents]] — Isolated Claude instances with their own context window; process 100K tokens and return a distilled summary, keeping the parent context clean (mixed, 2026-06-09)
- [[llm-agent-scientific-discovery|LLM Agents for Scientific Discovery]] — Paradigm of coordinated LLM agents automating the scientific method (hypothesis generation, experiment planning, data analysis) in a human-in-the-loop cycle (sourced, 2026-06-12)
- [[ai-for-drug-repurposing|AI for Drug Repurposing]] — Using LLM/agentic systems to surface non-obvious new indications for existing drugs by connecting insights already in the literature (sourced, 2026-06-12)
- [[agi-timelines|AGI Timelines]] — How soon AI will match human capability across domains; Amodei (faster) vs Hassabis (cautious) agree on direction, differ on timescale (mixed, 2026-06-14)
- [[ai-self-improvement-loop|AI Self-Improvement Loop]] — Models good at coding and AI research help build the next generation, compressing the development cycle; its closure rate sets AGI timelines (mixed, 2026-06-14)
- [[context-engineering|Context Engineering]] — The discipline of filling an LLM's context window with the right information, structured so the model can use it; named by Karpathy (2025) as a broader frame than prompt engineering, with write/select/compress/isolate strategies and a practitioner framing as ~80% agentic search (mixed, 2026-07-03)
- [[interpretable-context-methodology|Interpretable Context Methodology]] — Replaces framework-level agent orchestration with filesystem structure: numbered folders as stages, markdown CONTEXT.md files as stage contracts, one agent reading the right files at each step; a five-layer context hierarchy for sequential human-reviewed workflows (mixed, 2026-06-17)
- [[agentic-search|Agentic Search]] — Retrieval driven by the agent: it chooses which search tool to call, with what parameters, and whether to search again; the RAG → agentic RAG → agentic-search arc and a curated low-floor/high-ceiling tool stack (sourced, 2026-07-03)
- [[skill-checklist|Skill Checklist]] — Matt Pocock's four-part rubric for authoring and auditing agent skills (Trigger, Structure, Steering, Pruning); introduces user-invoked vs model-invoked, context pointers, leading words, sediment, and no-ops (sourced, 2026-07-03)

## Sources

- [[src-2026-04-16-claude-code-frameworks-report|Claude Code Frameworks & Patterns: A Comparative Report]] — April 2026 — Synthesis of 8 web-research investigations comparing Spec Kit, Superpowers, and GSD plus the Claude Code building blocks unified by progressive disclosure (mixed, 2026-06-09)
- [[src-2026-05-03-is-this-the-only-skill-left|Is this the only skill left?]] — Hack (Agentive Stack), 2026-05-03 — YouTube transcript on systems thinking as the durable skill in AI-assisted development (sourced, 2026-05-04)
- [[src-2026-05-04-three-artifacts-build-with-ai|Three artifacts that changed how I build with AI]] — Hack (Agentive Stack), 2026-05-04 — YouTube transcript on DDD reduced to three artifacts for AI-coding workflows (sourced, 2026-05-04)
- [[src-2026-05-04-financial-ai-repo-comparison-report|Financial AI and Quant Finance Repository Comparison Report]] — Comparison report mapping six finance-related open-source repositories (sourced, 2026-05-04)
- [[src-2026-05-04-openbb-investigation|OpenBB Repository Investigation Snapshot]] — Direct repository inspection capturing OpenBB's TA, FA, and other extension surface (sourced, 2026-05-04)
- [[src-2026-05-04-finrl-investigation|FinRL Repository Investigation Snapshot]] — Direct repository inspection capturing FinRL's TA-indicator-as-RL-state pipeline (sourced, 2026-05-04)
- [[src-2026-05-04-tradingagents-investigation|TradingAgents Repository Investigation Snapshot]] — Direct repository inspection of TradingAgents' market_analyst and fundamentals_analyst agents (sourced, 2026-05-04)
- [[src-2026-05-04-fmnm-investigation|Financial-Models-Numerical-Methods Repository Investigation Snapshot]] — Direct repository inspection of all 22 notebooks confirming derivatives focus (sourced, 2026-05-04)
- [[src-2026-05-04-dexter-investigation|Dexter Repository Investigation Snapshot]] — Direct repository inspection confirming Dexter is FA-only with a DCF skill (sourced, 2026-05-04)
- [[src-2026-05-04-anthropic-financial-services-investigation|Anthropic Financial Services Repository Investigation Snapshot]] — Direct repository inspection confirming populated FA SKILL.md prompts plus Python validators and Excel templates (sourced, 2026-05-04)
- [[src-2026-05-06-anthropic-agent-skills-overview|Anthropic Agent Skills Overview]] — Anthropic's docs page introducing Agent Skills as filesystem-based directories with three-level progressive disclosure across Claude API, Claude Code, and Claude.ai (sourced, 2026-05-06)
- [[src-2026-05-06-anthropic-agent-skills-quickstart|Anthropic Agent Skills Quickstart]] — Anthropic's API tutorial for invoking pre-built Agent Skills via the Messages API container parameter and downloading generated files via the Files API (sourced, 2026-05-06)
- [[src-2026-05-06-anthropic-agent-skills-best-practices|Anthropic Agent Skills Best Practices]] — Anthropic's authoring guide for SKILL.md: under 500 lines, third-person descriptions, references one level deep, evals before docs, Claude-A-writes-for-Claude-B iteration loop (sourced, 2026-05-06)
- [[src-2026-05-06-anthropic-claude-cookbook-skills-introduction|Introduction to Claude Skills (claude-cookbooks notebook 01)]] — Anthropic claude-cookbooks notebook with concrete SDK call shape (client.beta.messages.create + betas= parameter), required SDK version (anthropic>=0.71.0), and observed generation times (sourced, 2026-05-06)
- [[src-2026-05-06-anthropic-claude-cookbook-skills-custom-development|Building Custom Skills for Claude (claude-cookbooks notebook 03)]] — Anthropic claude-cookbooks notebook on custom-Skill upload (skills.create + files_from_dir), display_title workspace-uniqueness, type:'custom' container discriminator, versioning lifecycle, and skill composition (sourced, 2026-05-06)
- [[src-2026-05-06-ralph-playbook|The Ralph Playbook (Clayton Farr's how-to-ralph-wiggum)]] — Clayton Farr, 2026-05-06 — Long-form synthesis of Geoffrey Huntley's Ralph autonomous-coding-loop technique: 3 phases / 2 prompts / 1 loop, with five proposed enhancements (sourced, 2026-05-06)
- [[src-2026-06-09-pdf-to-text-llm-ingestion-sota|PDF-to-Text Extraction and LLM PDF Ingestion: State of the Art (2025–2026)]] — Synthesized deep-research report: three-camp taxonomy, extraction-vs-native-vision paradigms, OmniDocBench/olmOCR-Bench, per-page cost, VLM hallucination, pipeline recommendation (mixed, 2026-06-09)
- [[src-2026-06-12-multi-agent-scientific-discovery|A Multi-Agent System for Automating Scientific Discovery (Robin)]] — Ghareeb et al., Nature (2026) — first end-to-end multi-agent system automating hypothesis generation + data analysis; identified ripasudil/KL001 for dAMD (first PDF-acquired source, born-digital) (mixed, 2026-06-12)
- [[src-2026-06-14-hassabis-amodei-day-after-agi|FULL DISCUSSION: Google's Demis Hassabis, Anthropic's Dario Amodei Debate the World After AGI]] — DRM News, 2026-01-20 — YouTube transcript (video sub-case) on AGI timelines, the self-improvement loop, jobs, chip policy, and AI-safety risk; first video-acquired transcript with mended multi-speaker labels (sourced, 2026-06-14)
- [[src-2026-06-17-interpretable-context-methodology|Interpretable Context Methodology: Folder Structure as Agent Architecture]] — Van Clief & McDermott, arXiv:2603.16021v2 [cs.AI], March 2026 — ICM as filesystem-native orchestration for sequential, human-reviewed workflows; born-digital PDF extracted via pdftotext (tool-agnostic D-04 contract, no OCR needed) (mixed, 2026-06-17)
- [[src-2026-07-03-gsd-core-repo|open-gsd/gsd-core — GSD Core repository snapshot]] — Snapshot at commit `69fef7c0` (branch `next`) — first repository-type source: rename/lineage evidence (get-shit-done → GSD Core under OpenGSD), v1.7.0-rc.1 package metadata, first-party context-rot docs, curated code excerpts with `#path:` anchors (sourced, 2026-07-03)
- [[src-2026-07-03-agentic-search-context-engineering|Agentic Search for Context Engineering — Leonie Monigatti, Elastic]] — AI Engineer, 2026-05-08 — YouTube transcript (video sub-case): context engineering as ~80% agentic search, four search-interface demos (semantic, ES|QL, shell, semantic-grep), and low-floor/high-ceiling tool curation (sourced, 2026-07-03)
- [[src-2026-07-03-openai-symphony-spec|openai/symphony — Symphony Service Specification repository snapshot]] — Snapshot at commit `4cbe3a9` (branch `main`) — OpenAI's spec-first coding-agent orchestration service: long-running Linear-polling daemon, isolated per-issue Codex workspaces, single-authority orchestrator, hot-reloaded WORKFLOW.md contract, filesystem safety invariants; Apache-2.0/Elixir, engineering preview (sourced, 2026-07-03)
- [[src-2026-07-03-building-great-agent-skills|Building Great Agent Skills: The Missing Manual — Matt Pocock]] — AI Engineer, 2026-06-29 — YouTube transcript (video sub-case): a four-part "skill checklist" (Trigger/Structure/Steering/Pruning) for authoring and auditing agent skills, framed as the way out of "skill hell" (sourced, 2026-07-03)

## Comparisons

- [[financial-ai-repository-tradeoffs|Financial AI Repository Tradeoffs]] — Tradeoff comparison for finance repositories with TA/FA analysis-style coverage (mixed, 2026-05-04)
- [[claude-code-orchestration-frameworks|Claude Code Orchestration Frameworks]] — Head-to-head of Spec Kit (spec gate) vs Superpowers (execution discipline) vs GSD (context engineering): constraint, workflow, context strategy, and composability (mixed, 2026-06-09)
- [[ocr-pipeline-vs-vlm-ingestion|OCR Pipeline vs VLM Ingestion]] — The two competing PDF-to-Markdown paradigms — extraction/OCR pipelines vs native multimodal VLM ingestion — on accuracy, cost, determinism, and hallucination (mixed, 2026-06-09)

## Overviews

- [[domain-driven-design|Domain-Driven Design]] — 2003 methodology by Eric Evans, re-discovered for AI-assisted development as a remedy for context loss between AI sessions (mixed, 2026-05-04)
- [[financial-ai-repository-landscape|Financial AI Repository Landscape]] — Synthesis of six finance-related repositories as a layered ecosystem (mixed, 2026-05-04)
- [[agent-skills|Agent Skills]] — Filesystem-based capability packages (SKILL.md + bundled code/refs) loaded via three-level progressive disclosure across Claude API, Claude Code, and Claude.ai; also usable as just-in-time tool documentation to fix parameter generation (sourced, 2026-07-03)
- [[ralph-loop-creator-skill|Ralph Loop Creator Skill]] — Specification for a custom Agent Skill that scaffolds Ralph prompts, loop scripts, specs, implementation-plan state, AGENTS.md operational guidance, and backpressure checks without running the autonomous loop (mixed, 2026-05-06)
- [[pdf-text-extraction-for-llm-ingestion|PDF-to-Text Extraction for LLM Ingestion]] — 2025–2026 landscape for PDF-to-Markdown: three-camp taxonomy, paradigm debate, self-hosted vs commercial tiers, and a concrete ingestion-pipeline recommendation (mixed, 2026-06-09)
- [[robin-multi-agent-discovery-system|Robin (Multi-Agent Discovery System)]] — FutureHouse's multi-agent LLM system automating hypothesis generation + experimental data analysis; demonstrated by discovering ROCK-inhibitor phagocytosis enhancers for dry AMD (mixed, 2026-06-12)

## Decisions

- [[dr-2026-04-14-phase6-decision-type|dr-2026-04-14-phase6-decision-type]] — Introduce Decision Record Page Type (schema-update, 2026-04-14)
- [[dr-2026-04-15-kahneman-to-examples|dr-2026-04-15-kahneman-to-examples]] — Relocate the personal-domain test-fixture cluster from wiki/ to examples/ (schema-update, 2026-04-15)
- [[dr-2026-04-16-progressive-disclosure-extraction|dr-2026-04-16-progressive-disclosure-extraction]] — Extract §4 Worked Examples and §16 Appendices (schema-update, 2026-04-16)
- [[dr-2026-04-20-brownfield-apply-vs-advisory|Brownfield Apply-vs-Advisory Architecture + Review-Manifest Pattern]] — Captures the apply-class vs advisory-class split, review-manifest pattern, bootstrap_stage lifecycle gate, and cross-AI review-feedback hardenings (items 1–11) (sourced, 2026-04-20)
- [[dr-2026-05-01-complementary-systems-boundary|dr-2026-05-01-complementary-systems-boundary]] — Compendium owns durable, provenance-backed wiki memory and review support; complementary systems own task execution, reminders, calendars, and transactional state. (sourced, 2026-05-01)
- [[dr-2026-06-02-sc1-examples-isolable-subgraph|dr-2026-06-02-sc1-examples-isolable-subgraph]] — SC1 reframed from "graph not contaminated by examples/" to "examples/ forms a visually isolable sub-graph" (Obsidian's single Excluded-files mechanism cannot both index the fixtures for Dataview and hide them from the graph). (sourced, 2026-06-02)
- [[dr-2026-06-02-obsidian-filename-alias-resolution|Obsidian Filename + Alias Resolution: Self-Alias Invariant]] — Corrects §8 Obsidian resolution rule; mandates self-alias invariant; adds linkres lint enforcement (superseded, 2026-06-02)
- [[dr-2026-06-03-uniform-piped-links|Uniform Piped Links: Correcting the Obsidian Link Resolution Convention]] -- Corrects §8 to mandate uniform `[[id|Title]]` piped links; supersedes the wrong-premise self-alias DR. (sourced, 2026-06-03)
- [[dr-2026-06-04-privacy-asymmetric-two-dir|Asymmetric Two-Directory Privacy: wiki-cloud/ + wiki-local/]] -- Converts per-page privacy frontmatter to structural directory-tier enforcement; removes the privacy field, seven-row table, three-level precedence, and page-inheritance machinery. (sourced, 2026-06-04)
- [[dr-2026-06-04-reference-extraction|Reference Extraction: AGENTS.md Monolith to schema/reference/ + schema/workflows/]] — Extracts static reference sections into standalone leaf files; evolves the spec to a router-plus-per-section-authority model (D-09). (sourced, 2026-06-04)
- [[dr-2026-06-05-workflow-extraction|Workflow Extraction: AGENTS.md §9–§12 to schema/workflows/ + routing guard + inclusion tripwire]] — Extracts workflow procedures into standalone files; abolishes cross-file §N refs via the routing lint category; adds inclusion-audit baseline header. (sourced, 2026-06-07)
- [[dr-2026-06-08-skills-overlay|Skills Overlay: Four Generated SKILL.md Routers + bin/gen-skills.sh Drift Gate]] — Introduces four thin SKILL.md pointer routers generated by bin/gen-skills.sh with a --check drift gate; records the two-layer SOT model and model-invocation choice. (sourced, 2026-06-08)
- [[dr-2026-06-10-source-type-contract|Source-Type Extension Contract + research-report Secondary Source Type]] — Formalizes the 5-dimension source-type extension contract and adds source_type: research-report with derived-only provenance and lint enforcement against epistemic laundering. (sourced, 2026-06-10)
- [[dr-2026-06-11-pdf-ingestion|PDF as Format-Orthogonal Source Sub-Case + First Local-Model Acquisition Script]] — Records PDF as a format-orthogonal acquisition sub-case (not a new source_type): lazy-loaded pdf-ingestion.md, four flat extraction fields under conditional lint, tiered VLM-hallucination epistemics with support_type direct, and bin/pdf-extract.sh as the first local-model script. (sourced, 2026-06-11)
- [[dr-2026-06-14-video-ingestion|Video as Sub-Case of Transcript + Tool-Generic Acquisition (No Repo Script)]] — Records video as a sub-case of transcript (not a new source_type): lazy-loaded video-ingestion.md, and four deliberate divergences from the PDF sub-case — tool-generic acquisition with no repo script, transcript-only single-file commit with no asset, plain link-rot stance, and convention-only extraction fields that are not lint-enforced. (sourced, 2026-06-14)
- [[dr-2026-07-03-repository-source-type|Repository as a New Primary Source Type (#path/#commit Locators + Excerpt Registry)]] — Records repository as a first-class source_type (the contract's first primary new-type instance): #path:/#commit: locators resolvable via a curated-snapshot Excerpts registry, within-source epistemic split, required drift-anchor frontmatter, mechanical-only acquisition glue. (sourced, 2026-07-03)
- [[dr-2026-07-03-external-source-drift|External Source Drift: Surface, Don't Mark (Opt-in --network Lint Checks)]] — Records external drift detection as opt-in review-only lint --network checks (repository HEAD-vs-commit_sha, URL reachability with videos excluded, registry link-rot ratios) and the conscious narrowing of the backlog sketch's auto-stale-marking to surfacing only. (sourced, 2026-07-03)
- [[dr-2026-07-03-python-migration|Bash-to-Python Migration: Shim-and-Swap Behind a Byte-Parity Oracle]] — Records the v1.5 re-platform of bin/ to a Python package behind .sh exec-shims: byte-parity as the acceptance bar (4-channel oracle), frozen common/ core retiring the lint/audit byte-copy, two-layer test strategy, the two retirements, and the template allowlist extension. (sourced, 2026-07-03)
