# LLM Wiki Compiler

## What This Is

A personal knowledge management system where LLM agents incrementally build and maintain a persistent, interlinked Obsidian wiki from raw source documents. Instead of re-deriving knowledge from scratch on every query (like RAG), the LLM compiles sources into structured wiki pages — summaries, entity pages, concept pages, comparisons — and keeps them current as new sources arrive. The human curates sources and asks questions; the LLM does all the bookkeeping.

## Core Value

The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested. Knowledge accumulates rather than being re-derived.

## Current Milestone: v1.1 Shareability

**Goal:** Make the v1.0 starter kit usable by technically comfortable early adopters — a template-based starter repo with a two-track setup, git-based collaborative curation, and a safe path for onboarding existing Obsidian vaults.

**Target features:**

- **Template-based starter repo on GitHub** — cloneable structure with in-repo `/docs/` organized into four explicit tracks (quickstart, guided setup, manual setup, reference), Kahneman cluster moved to `examples/`, empty vault by default.
- **Two-track setup** — guided wizard (prompts for domain, privacy defaults, LLM agent, generates personalized `AGENTS.md`) *and* a manual hand-edit track for power users; each track has its own docs page.
- **Git-based collaborative curation** — PR workflow where contributors fork, ingest on a branch, open PR; merge conflicts handled by git + lint gate. Attribution: git commit authorship is the source of truth; `log.md` ingest entries carry a contributor field as a convenience index.
- **Brownfield vault onboarding** — `bin/brownfield.sh` with four subcommands: `scan` (dry-run markdown report), `bootstrap` (mechanical-only auto: sentinel frontmatter, SHA hashing, `index.md`/`log.md` skeleton, YAML normalization), `suggest` (writes `.brownfield/REPORT.md` plus `.brownfield/migrations/*.sh` — one idempotent staged shell script per transformation class, each printing what it changed), `verify` (runs existing lint after user-applied migrations). Strict mechanical/judgment boundary — page typing, provenance bootstrapping, cross-reference inference, and privacy classification stay in `suggest` only.
- **Domain-agnostic defaults** — neutral starter content; `AGENTS.md` stripped of Kahneman-specific examples (kept in `examples/` for reference).

**Audience:** Technically comfortable early adopters first, with a guided setup path that reduces friction for less technical Obsidian users.

**Deferred to backlog:** Obsidian plugin distribution, one-command installer (`curl|bash`), hosted docs site, brownfield `--apply` mode for judgment-heavy operations (→ v1.2 after the dry-run path is battle-tested).

**v1.0 revisit flags threaded in:** Obsidian render/Dataview verification (deferred from Phase 4) and multi-agent validation (Codex, etc.) — folded into v1.1 verification gates.

## Requirements

### Validated

- [x] Agent-agnostic schema (CLAUDE.md / AGENTS.md) that tells any LLM how to maintain the wiki — Validated in Phase 01: schema-structure-conventions
- [x] Directory structure conventions for raw sources, wiki pages, index, and log — Validated in Phase 01: schema-structure-conventions
- [x] Typed page schemas: entity pages, concept pages, source summaries, comparisons, with type-specific templates — Validated in Phase 01: schema-structure-conventions
- [x] Structured operations layer: UPDATE, MERGE, SUPERSEDE, ARCHIVE instead of raw file rewrites — Validated in Phase 01: schema-structure-conventions
- [x] Progressive disclosure: shallow summaries for navigation, drill-down for detail — Validated in Phase 01: schema-structure-conventions
- [x] Obsidian integration: graph view compatibility, Dataview frontmatter, Marp slide generation, wikilinks — Validated in Phase 01: schema-structure-conventions
- [x] Page type templates for entity, concept, source summary, comparison, and overview — Validated in Phase 02: page-types-examples-navigation
- [x] Epistemic status markers: sourced, inferred, tentative, stale — inline syntax and documentation — Validated in Phase 02: page-types-examples-navigation
- [x] Example wiki pages demonstrating all conventions and page types — Validated in Phase 02: page-types-examples-navigation
- [x] Index system: content-oriented catalog with categories, summaries, metadata — Validated in Phase 02: page-types-examples-navigation
- [x] Log system: chronological, parseable, append-only activity record — Validated in Phase 02: page-types-examples-navigation
- [x] Ingest workflow: source classification, extraction, multi-page wiki updates, provenance tracking — Validated in Phase 03: ingestion-provenance-pipeline
- [x] Claim-level provenance: which sources support which claims, freshness tracking — Validated in Phase 03: ingestion-provenance-pipeline
- [x] Compilation pipeline: diff → extract → merge → lint, with optional follow-on passes — Validated in Phase 03: ingestion-provenance-pipeline
- [x] CLI helpers for common operations (search, ingest, lint) — Validated in Phase 03: ingestion-provenance-pipeline (ingest helper)
- [x] Query workflow: index-first search, synthesis with citations, delta compilation back into wiki — Validated in Phase 04: query-structured-operations
- [x] Structured operations enforcement: deterministic validator (bin/validate-op.sh), per-operation preconditions/postconditions, batch validation — Validated in Phase 04: query-structured-operations
- [x] CLI search helper (bin/search.sh) with index lookup, full-text grep, and query mode — Validated in Phase 04: query-structured-operations
- [x] Lint workflow: contradiction detection, stale claims, orphan pages, missing cross-references, data gaps — Validated in Phase 05: lint-quality
- [x] Reflect workflow: decision records, structural reasoning, reframing history — Validated in Phase 06: reflection-drift-detection
- [x] Cross-system drift detection between wiki, raw sources, and any external tools — Validated in Phase 06: reflection-drift-detection
- [x] Guided setup wizard generating personalized `AGENTS.md` (domain, privacy, LLM agent) — Validated in Phase 08: two-track-setup-wizard-manual
- [x] Manual setup track preserved for power users — Validated in Phase 08: two-track-setup-wizard-manual
- [x] Git-based PR workflow for collaborative curation with lint gate — Validated in Phase 09: collaborative-pr-workflow-ci-lint-gate
- [x] Per-ingest contributor field in `log.md` (git authorship remains source of truth) — Validated in Phase 09: collaborative-pr-workflow-ci-lint-gate

### Active (v1.1 focus areas — formal REQ-IDs in REQUIREMENTS.md)

- [ ] Template-based starter repo with four-track `/docs/` (quickstart, guided setup, manual setup, reference)
- [ ] Kahneman cluster moved to `examples/`; starter vault neutral
- [ ] `bin/brownfield.sh scan` — dry-run markdown report
- [ ] `bin/brownfield.sh bootstrap` — mechanical-only auto (sentinel frontmatter, hashes, skeleton, YAML normalization)
- [ ] `bin/brownfield.sh suggest` — staged idempotent migration scripts for judgment-heavy work
- [ ] `bin/brownfield.sh verify` — lint integration after user-applied migrations
- [ ] Multi-agent validation (Codex or other) against v1.0 workflows
- [ ] Obsidian render/Dataview verification (deferred from Phase 4)

### Out of Scope

- Building a hosted web application — this is a local, file-based system
- Embedding-based RAG infrastructure — index-first search is the v1 approach
- Real-time / concurrent multi-user editing — collaboration in v1.1 is asynchronous git PR workflow only; no shared-vault coordination, locking, or merge-coordination services
- Hosted multi-tenant service — local + git-hosted only; no servers
- Non-markdown output formats — markdown + Obsidian is the stack
- Mobile apps — desktop Obsidian + CLI agents only
- OAuth/auth — no authentication layer needed for a local system

## Context

The idea draws from Vannevar Bush's Memex (1945) — a personal, curated knowledge store with associative trails. The key insight is that LLMs eliminate the maintenance burden that causes humans to abandon wikis. The human's job is curation and thinking; the LLM handles summarizing, cross-referencing, filing, and consistency.

The system has three layers:
1. **Raw sources** — immutable input documents (articles, papers, images, journal entries, etc.)
2. **The wiki** — LLM-generated and maintained markdown pages (the compiled artifact)
3. **The schema** — the configuration document (CLAUDE.md/AGENTS.md) that governs LLM behavior

The first domain will be personal knowledge — goals, health, psychology, self-improvement, journal entries, articles, podcast notes. Obsidian is the primary browsing interface. The system must work with multiple LLM agents (Claude Code, Codex, others).

The v1 is a full starter kit: schema, workflows, conventions, page templates, example pages, index/log templates, and CLI helpers — everything needed to clone and start using immediately. The v2 (future) will be software that automates the compilation pipeline.

## Constraints

- **Agent-agnostic**: Schema must work with Claude Code (CLAUDE.md), Codex (AGENTS.md), and other agents — no agent-specific features in the core conventions
- **File-based**: Everything is markdown files in a git repo — no databases, no servers, no cloud dependencies for v1
- **Obsidian-first**: Wiki pages must be valid Obsidian markdown — wikilinks, frontmatter, graph-compatible structure
- **Local-only**: All data stays on disk — no external API calls required for core wiki operations (LLM calls are the exception)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Guide/template first, software tool second | Get the pattern right through personal use before automating | ✓ Good — v1.0 shipped as starter kit |
| Personal/self as first domain | Concrete use case to validate against, high personal motivation | ✓ Good — Kahneman cluster + journal entry validated ingest |
| Full framework from v1 (provenance, epistemic status, structured ops) | The advanced features are what differentiate this from "LLM writes notes" | ✓ Good — all three shipped and validated end-to-end |
| Obsidian as primary interface | Graph view, Dataview, Marp, plugin ecosystem — best-in-class for interlinked markdown | ⚠️ Revisit — Obsidian render/Dataview check deferred from Phase 4 |
| Agent-agnostic design | Avoid lock-in, test with multiple agents to find what works | — Pending — only Claude Code exercised in v1.0 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-16 — Phase 09.1 (Progressive Disclosure Extraction) complete: AGENTS.md/CLAUDE.md reduced 1,785 → 1,412 lines (~21%) by extracting §4 worked examples to schema/examples/ and §16 Appendices A/B to docs/reference/, with the "sole authoritative specification" framing preserved via uniform `See:` pointers.*
