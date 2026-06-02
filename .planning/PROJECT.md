# LLM Wiki Compiler

## What This Is

A personal knowledge management system where LLM agents incrementally build and maintain a persistent, interlinked Obsidian wiki from raw source documents. Instead of re-deriving knowledge from scratch on every query (like RAG), the LLM compiles sources into structured wiki pages — summaries, entity pages, concept pages, comparisons — and keeps them current as new sources arrive. The human curates sources and asks questions; the LLM does all the bookkeeping.

## Core Value

The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested. Knowledge accumulates rather than being re-derived.

## Current Milestone: v1.1.1 Graph Integrity

**Goal:** Make the wiki's Obsidian graph actually connect. The "Obsidian-first" premise is silently broken: Obsidian resolves `[[X]]` by **filename + `aliases`**, never by the `title` frontmatter — but pages are named by slug (`id == filename`) and linked by spaced `[[Title]]` that isn't in `aliases`, so 31 of 49 wiki pages render as graph orphans. Fix the defect at all three layers — correct the convention, enforce it mechanically, and remediate existing `wiki/` + `examples/` data — so the graph connects and stays connected as new pages are ingested.

**Type:** Patch milestone (correctness fix to shipped v1.1). Sequenced **before** the v1.2 schema progressive-disclosure refactor (backlog 999.4), which it de-risks by correcting §8 in place first.

**Target outcomes:**

- **Correct convention** — `CLAUDE.md` §8 states the real resolution rule (filename + aliases, not `title`) and mandates the self-alias invariant (every page's `aliases` includes its `title` and `id` slug); §5 checklist + page templates updated; `AGENTS.md` stays byte-identical; a decision record captures the reality.
- **Mechanical enforcement** — a new `bin/lint.sh` Obsidian-accurate link-resolution check flags unreachable page titles and should-resolve-but-mismatched body links (distinct from intentional knowledge-gap red links), with `--fix` to auto-backfill the self-alias; the existing `orphan` check is reconciled so it no longer masks the problem.
- **Data remediation** — all `wiki/` and `examples/` pages carry self-aliases; link-text variants (plural/parens/casing) reconciled; the resolution check exits 0 and the graph visibly connects in Obsidian.

**Audience:** Same as v1.1 — technically comfortable early adopters who browse the compiled vault in Obsidian. This makes the shipped "Obsidian-first" promise true.

**Deferred to backlog:** Obsidian plugin distribution, one-command installer (`curl|bash`), hosted docs site, brownfield `--apply` mode, and the v1.2 schema progressive-disclosure refactor (999.4) — all sequenced after this patch.

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
- [x] `bin/brownfield.sh suggest` — hybrid script-copy + vault-specific classifier emitting `candidates.yaml` + `decisions.yaml` review manifest — Validated in Phase 11: brownfield-suggest-verify
- [x] `bin/brownfield.sh review-typing` — EOF-safe deterministic page-typing review surface (TTY small-batch + AI-handoff large-batch) — Validated in Phase 11: brownfield-suggest-verify
- [x] `bin/brownfield.sh verify` (+ `--promote`) — read-only lint wrapper with 5-gate `bootstrapped → verified` promotion — Validated in Phase 11: brownfield-suggest-verify
- [x] Four canonical migration scripts — 01 page-typing + 02 provenance-bootstrap (apply-class), 03 cross-link-inference + 04 privacy-review (advisory-class) — Validated in Phase 11: brownfield-suggest-verify
- [x] Complementary-systems boundary decision record — compendium owns durable wiki memory; task / calendar / reminder / inbox layers belong to complementary systems (BOUND-01) — Validated in Phase 12: complementary-systems-boundary-gtd-alignment
- [x] Three-layer reference doc — task / working-memory / wiki-compiler split with capture/clarify/organize/review routing rules and explicit anti-features (BOUND-02) — Validated in Phase 12: complementary-systems-boundary-gtd-alignment
- [x] Reviewed-match boundary audit — README + AGENTS.md + docs/ + wiki/decisions/ verified to contain zero "all-in-one PKM/task" framing (BOUND-03) — Validated in Phase 12: complementary-systems-boundary-gtd-alignment

### Validated (v1.1 Shareability — shipped 2026-06-02)

- ✓ Template-based starter repo with four-track `/docs/` (quickstart, guided setup, manual setup, reference) — v1.1 (Phase 7)
- ✓ Kahneman cluster moved to `examples/`; starter vault neutral — v1.1 (Phase 7)
- ✓ `bin/brownfield.sh scan` — dry-run markdown report — v1.1 (Phase 10)
- ✓ `bin/brownfield.sh bootstrap` — mechanical-only auto (sentinel frontmatter, hashes, skeleton, YAML normalization) — v1.1 (Phase 10)
- ✓ Multi-agent validation — Codex agent-parity audited (blocked-on-host-runtime per AppArmor; Claude-vs-golden EXACT structural match carries the verdict) — v1.1 (Phases 13.1/13.2)
- ✓ Obsidian render/Dataview verification (deferred from v1.0 Phase 4) — v1.1 (Phase 13.2; live Dataview counts 3/2/2/2/5)

Closure gate (Phase 13.2, CLOSE-01..04): `bin/requirements-sync.sh --strict --require-complete` exits 0 milestone-wide (0 drift of 97 requirements; all 97 Complete).

### Active (v1.1.1 Graph Integrity — formal REQ-IDs in REQUIREMENTS.md)

- [ ] Obsidian-accurate link-resolution convention: §8 corrected + self-alias invariant (`title`, `id` ∈ `aliases`) (LINK-01..03)
- [ ] `bin/lint.sh` resolution check (`linkres`) with `--fix`; reconcile masking `orphan` check (LINK-04..06)
- [ ] Backfill `wiki/` + `examples/` self-aliases; reconcile link-text variants; graph connects in Obsidian (LINK-07..10)

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
*Last updated: 2026-06-02 — Milestone v1.1.1 Graph Integrity started. Patch milestone correcting the Obsidian wikilink-resolution defect (Obsidian resolves `[[X]]` by filename + `aliases`, not `title`; 31/49 wiki pages render as graph orphans). Three phases (14–16): convention + DR, lint enforcement (`linkres` + `--fix`), data remediation across `wiki/` + `examples/`. Sequenced before the v1.2 schema refactor (999.4). Requirements LINK-01..10.*

*Last updated: 2026-06-02 after v1.1 Shareability milestone — SHIPPED + ARCHIVED. All 15 v1.1 phase directories (Phases 7–13.2, 52 plans) complete; 97/97 v1.1 requirements Complete with zero drift (`bin/requirements-sync.sh --strict --require-complete` exits 0). Phase 13.2 closure gate (CLOSE-01..04): Obsidian render re-run (Dataview 3/2/2/2/5), Codex agent-parity accepted blocked-on-host-runtime, write-back audited, docs consistency + scope-leak clean. Archived to `.planning/milestones/v1.1-*`; ROADMAP collapsed (Backlog preserved); `REQUIREMENTS.md` removed for a fresh next-milestone; git tag `v1.1`. Deferred: 1 post-v1.1 todo (a1 lexical-dedup lint), backlog 999.3–999.6, v1.2 items (Obsidian plugin, installer, hosted docs, brownfield `--apply`). Next: `/gsd-new-milestone`.*

*Last updated: 2026-05-03 — Phase 12.1 (NEUT-08 Personal-Term Denylist Curation) complete: 7-term defense-in-depth expansion appended to `.neutrality-denylist.txt` under unified `# Category: Personal-vault terms expanded curation (NEUT-08, 2026-05-02)` header (kept set: pre-committing, physical flinch, pre-mortem, pre-mortems, decision fatigue, decision-fatigue, meta-observation). Rubric revised from "hyphenated identifier unique to vault" to include (a) spaced multi-word phrases coined in archived journal sources (precedent: existing denylist uses spaced forms `loss aversion`, `system 1`) and (b) popular cog-bias terms used heavily in vault that would betray vault provenance via LLM-mediated example-leak. NEUT-08 flipped to Complete in REQUIREMENTS.md (line 36 + matrix line 215); 12.1-VERIFICATION.md authored with verbatim D-10 evidence; `bin/requirements-sync.sh --strict --phase 12.1` and `--require-complete --phase 12.1` both exit 0; `bin/check-neutrality.sh` source unchanged across the entire phase. First v1.1 partial-requirement closure, clearing the path for Phase 13.2 v1.1 closure verification gate.*

*Last updated: 2026-06-01 — Phase 13 (Claim Faithfulness Audit) complete: shipped `bin/audit-claims.sh` (FAITH-01 high-risk claim selectors → FAITH-02 raw-source locator→passage resolver → 9-key structured findings → FAITH-04 fail-closed privacy chokepoint → stdin-only `shlex.split` verifier dispatch with supports/weak/contradicts/insufficient verdicts) and `bin/lib/privacy_resolve.py` (§13 three-level fail-closed + strictest-wins effective-claim privacy). Review-only by default — no auto-fix, no CI gate, severity never `error`. AGENTS/CLAUDE §6 document the optional `<!-- page: N -->` page-marker convention and the Audit as a review-only workflow (four-operation framing preserved). FAITH-01..04 → Complete; verifier PASS 6/6 SC + 4/4 REQ; tests 33/33; `bin/requirements-sync.sh --strict/--require-complete --phase 13` both exit 0; code review 0 critical / 0 high (advisory MD-01: `--format json` omits the `--emit-worklist` HIGH-C metadata redaction — passage text not leaked). Remaining v1.1: Phase 13.1 (docs + Obsidian starter), Phase 13.2 (closure verification gate).*

*Previous: 2026-05-01 — Phase 12 (Complementary Systems Boundary + GTD Alignment) complete: `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (BOUND-01) + `docs/reference/three-layer-model.md` (BOUND-02) + reviewed-match audit over README/AGENTS.md/docs/wiki/decisions (BOUND-03) — 6/6 grep hits all `negative-framing`, zero `positive-claim`. SPEC-anchored phase-base SHA `ef3afec`; zero `bin/`/`schema/` content drift; AGENTS.md §4 page-type enum unchanged (still 6); `bin/requirements-sync.sh --strict --phase 12` exits 0.*
