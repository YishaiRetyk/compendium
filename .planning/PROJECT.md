# LLM Wiki Compiler

## What This Is

A personal knowledge management system where LLM agents incrementally build and maintain a persistent, interlinked Obsidian wiki from raw source documents. Instead of re-deriving knowledge from scratch on every query (like RAG), the LLM compiles sources into structured wiki pages — summaries, entity pages, concept pages, comparisons — and keeps them current as new sources arrive. The human curates sources and asks questions; the LLM does all the bookkeeping.

## Core Value

The wiki is a persistent, compounding artifact — cross-references are already there, contradictions already flagged, synthesis already reflects everything ingested. Knowledge accumulates rather than being re-derived.

## Current State

**Shipped:** v1.2 Schema Architecture (2026-06-08) — applied the project's own §7 progressive-disclosure principle to its own spec. The always-loaded `AGENTS.md`/`CLAUDE.md` monolith (**1,689 lines**) was reduced to a ~287-line resident core decided by an inclusion test (ambient / unscriptable-AND-unacceptable-miss / dispatch), with everything else extracted into `schema/reference/*.md` + `schema/workflows/*.md`. Four phases, 15 plans, 28/28 requirements Complete: **Phase 15 Privacy Architecture (`PRIV`)** — replaced per-page §13 privacy with the asymmetric two-directory `wiki-cloud/` / `wiki-local/` model (one-way permeability enforced as a harness `deny`-read permission, not a resident rule); **Phase 16 Reference Extraction (`REF`)** — §4/5/6/7/8/13 → `schema/reference/*.md`, §14/15 → `docs/reference/*.md`, §16 deleted, `IMPORTANT:`-flagged routing table added; **Phase 17 Workflow Extraction (`WF`)** — §9/10/11.1–11.7/12 → `schema/workflows/*.md` (incl. the 182-line brownfield miss), new `routing` lint category (LINT_VERSION 1.8.0) gates path-ref integrity; **Phase 18 Skills Overlay (`SKILL`)** — thin pointer-only `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` routers generated + drift-gated by `bin/gen-skills.sh --check`, zero authoritative content. Byte-equality (`sync-claude --check`), neutrality, and privacy gates all green throughout.

**Cumulative:** v1.0 MVP (Phases 1–6, shipped 2026-04-15) + v1.1 Shareability (Phases 7–13.2, shipped 2026-06-02) + v1.1.1 Graph Integrity (Phase 14, shipped 2026-06-04) + v1.2 Schema Architecture (Phases 15–18, shipped 2026-06-08). 73 plans total across 4 milestones.

**Active milestone:** v1.3 Source Ingestion (started 2026-06-10) — Phase 19 (Extension Contract + Research-Report Type) complete 2026-06-10; 9/9 requirements (EXT-01..03, RPT-01..06) verified 5/5 must-haves after one gap-closure cycle. Next: Phase 20 PDF Ingestion. See Current Milestone below. Live backlog (do not plan against superseded 999.1/999.2/999.7): 999.3 (template placeholder system, partially folded as the deferred Phase D/`WIZ`), 999.5 (external source drift detection — explicitly deferred from v1.3), 999.6 (observed GTD review patterns).

**Deferred to backlog:** Obsidian plugin distribution, one-command installer (`curl|bash`), hosted docs site, brownfield `--apply` mode, Phase D Wizard/Template fold-in (`WIZ`) — all carried forward.

<details>
<summary>✅ v1.2 Schema Architecture (Phases 15–18) — SHIPPED 2026-06-08</summary>

**Goal (delivered):** Apply the project's own §7 progressive-disclosure principle to its own spec — reduce the always-loaded `AGENTS.md`/`CLAUDE.md` (1,689 lines) to a resident core of only what genuinely belongs in every-turn context, decided by an **inclusion test** (ambient / unscriptable-AND-unacceptable-miss-cost / dispatch), not a line target. Outcome: ~287-line core; the rest extracted into `schema/reference/*.md` + `schema/workflows/*.md`, preserving a markdown-authoritative, harness-portable architecture.

**Phases (all complete):**
- **Phase 15 — Privacy Architecture (`PRIV`):** per-vault asymmetric two-directory model (`wiki-cloud/` / `wiki-local/`; one-way permeability — local runs read both, cloud runs cannot read `wiki-local/`); enforcement is a harness `deny`-read permission, not a resident rule. Landed before §13 extraction.
- **Phase 16 — Reference Extraction (`REF`):** §4/5/6/7/8/13 → `schema/reference/*.md`; §14/15 → `docs/reference/*.md`; §16 deleted; `IMPORTANT:`-flagged routing table added; stubs mirrored into `schema/AGENTS.template.md`.
- **Phase 17 — Workflow Extraction (`WF`):** §9/10/11.1–11.7/12 → `schema/workflows/*.md` (incl. the 182-line brownfield miss); resident core 1,689→287 lines; new `routing` lint category (LINT_VERSION 1.8.0) gates path-ref integrity.
- **Phase 18 — Skills Overlay (`SKILL`):** thin pointer-only `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` routers generated + drift-gated by `bin/gen-skills.sh --check` (regenerate-diff + 6 structural assertions), wired into pre-commit + a hard-fail CI `skills-check` job; zero authoritative content.

**Deferred:** Phase D — Wizard/Template fold-in (`WIZ`) — D1 conflicts with the Phase-8 minimalism decision; D2 is observation-gated. Promotable later via `/gsd-phase`.

**Design constraints held throughout:** markdown-authoritative; `AGENTS.md ≡ CLAUDE.md` byte-equality (pre-commit `sync-claude --check`); wizard pipeline preserved; always-loaded safety core stays resident (provenance requirement, MUST-NOT list verbatim, write-back-mandatory, structured-op vocabulary — privacy dissolved into the harness permission by Phase 15); CI gates unchanged in behavior (extraction relocated text, not logic).

</details>

## Current Milestone: v1.3 Source Ingestion

**Goal:** Formalize three new source ingestion paths — AI deep-research reports, PDFs, and YouTube videos — as schema conventions plus documented acquisition pipelines, designed once via a shared source-type extension contract.

**Target features:**
- **Source-type extension contract** — the 5-dimension recipe (acquisition / locator / extraction / drift / epistemics) + primary/secondary axis designed once, so each new source type is an instance of the contract rather than a one-off (per `.planning/notes/2026-05-31-milestone-grouping-proposal.md` "Source Ingestion" cluster)
- **Research-report ingest** — `source_type: research-report` for AI deep-research artifacts (Claude/ChatGPT/Perplexity), bibliography preserved as provenance; design LOCKED in `.planning/seeds/research-report-ingest.md`; ships first
- **PDF ingestion** — acquisition via olmOCR 2 (local Ollama model `richardyoung/olmocr2:7b-q8`, the wiki's own SOTA-report recommendation); reuses the `<!-- page: N -->` / `#p` locator; likely an article/paper sub-case convention, not a new type; includes VLM-hallucination epistemic guidance for degraded scans
- **YouTube video ingestion** — acquisition via the external `stt` CLI (`~/code/transcript/`: faster-whisper large-v3 + IVRIT Hebrew, pyannote diarization, yt-dlp, timestamped speaker-labeled output); reuses the `#t<start>-<end>` locator; likely a `transcript` sub-case

**Key constraints:**
- Acquisition tooling stays *outside* this repo (stt is its own project; olmocr2 runs via Ollama) — the milestone ships conventions, frontmatter metadata, docs, and at most thin glue
- Human-curates-sources role division preserved: no web-research operation; the four-op vocabulary (ingest/query/lint/reflect) stays intact
- 999.5 External Source Drift explicitly deferred — research-report URL bibliographies are its natural trigger, but it remains backlog

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

### Validated (v1.2 Schema Architecture — shipped 2026-06-08)

- ✓ Asymmetric two-directory privacy model (`wiki-cloud/` / `wiki-local/`); one-way permeability enforced as a harness `deny`-read permission; per-page §13 privacy dissolved (`PRIV-01..07`) — v1.2 (Phase 15)
- ✓ Reference extraction — §4/5/6/7/8/13 → `schema/reference/*.md`, §14/15 → `docs/reference/*.md`, §16 deleted, `IMPORTANT:`-flagged routing table added (`REF-01..10`) — v1.2 (Phase 16)
- ✓ Workflow extraction — §9/10/11.1–11.7/12 → `schema/workflows/*.md`; resident core 1,689→287 lines; `routing` lint category (LINT_VERSION 1.8.0) gates path-ref integrity (`WF-01..09`) — v1.2 (Phase 17)
- ✓ Skills overlay — four thin pointer-only `.claude/skills/*/SKILL.md` routers generated + drift-gated by `bin/gen-skills.sh --check`, wired into pre-commit + CI; zero authoritative content (`SKILL-01..02`) — v1.2 (Phase 18)

Closure: 28/28 v1.2 requirements Complete; byte-equality (`sync-claude --check`), neutrality, privacy, and `gen-skills --check` gates all green.

### Validated (v1.1 Shareability — shipped 2026-06-02)

- ✓ Template-based starter repo with four-track `/docs/` (quickstart, guided setup, manual setup, reference) — v1.1 (Phase 7)
- ✓ Kahneman cluster moved to `examples/`; starter vault neutral — v1.1 (Phase 7)
- ✓ `bin/brownfield.sh scan` — dry-run markdown report — v1.1 (Phase 10)
- ✓ `bin/brownfield.sh bootstrap` — mechanical-only auto (sentinel frontmatter, hashes, skeleton, YAML normalization) — v1.1 (Phase 10)
- ✓ Multi-agent validation — Codex agent-parity audited (blocked-on-host-runtime per AppArmor; Claude-vs-golden EXACT structural match carries the verdict) — v1.1 (Phases 13.1/13.2)
- ✓ Obsidian render/Dataview verification (deferred from v1.0 Phase 4) — v1.1 (Phase 13.2; live Dataview counts 3/2/2/2/5)

Closure gate (Phase 13.2, CLOSE-01..04): `bin/requirements-sync.sh --strict --require-complete` exits 0 milestone-wide (0 drift of 97 requirements; all 97 Complete).

### Validated (v1.1.1 Graph Integrity — completed 2026-06-03)

> **Re-planned mid-milestone.** The original self-alias premise was proven false — Obsidian resolves `[[X]]` by **filename/path only**, never by `aliases` (intentional design, confirmed for v1.12.7). Shipped the corrected approach: **uniform piped links `[[id|Title]]`** (target = page `id` = filename → always resolves; display = canonical title). See `wiki/decisions/dr-2026-06-03-uniform-piped-links` + `.planning/phases/14-graph-link-resolution/14-FINDINGS-premise-invalidated.md`.

- [x] Obsidian-accurate link-resolution convention: §8/§5 state `[[X]]` resolves by filename/path ONLY; uniform `[[id|Title]]` mandated; self-alias invariant REMOVED; superseding decision record authored (LINK-01..03) — Validated in Phase 14: graph-link-resolution
- [x] `bin/lint.sh` `linkres` re-pointed to validate link *targets* (bare/broken = error; knowledge-gap red links stay `gap`/info); `--fix` rewrites bare→piped; alias-free `orphan` resolution; shared `mask_markdown` neutralises documentation examples (LINK-04..06) — Validated in Phase 14: graph-link-resolution
- [x] All `wiki/` + `examples/` body links rewritten to uniform piped form; plural/parens variant problem dissolved; connected graph human-verified in Obsidian (LINK-07..10) — Validated in Phase 14: graph-link-resolution

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
| Progressive-disclosure self-refactor (v1.2): extract the spec monolith into `schema/reference/*.md` + `schema/workflows/*.md`, keep a minimal resident core decided by an inclusion test | The always-loaded 1,689-line AGENTS.md/CLAUDE.md violated the project's own §7 principle | ✓ Good — core shrank to ~287 lines; routing-table + `routing` lint category prevent dangling refs |
| Asymmetric two-directory privacy (`wiki-cloud/` / `wiki-local/`) enforced as a harness permission, not a resident agent rule | Per-page §13 privacy was fragile and bloated the resident core; structural enforcement is stronger than a rule the agent must remember | ✓ Good — privacy dropped from the safety core (Phase 15) |
| Thin generated `.claude/skills/` overlay (pointer-only bodies, drift-gated) over markdown SOT | Skills add discoverability without forking authority away from markdown | ✓ Good — `gen-skills --check` keeps bodies zero-authoritative; SOT stays in `schema/workflows/*.md` |

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
*Last updated: 2026-06-11 — Phase 19 (Extension Contract + Research-Report Type, `EXT-01..03`/`RPT-01..06`) complete (5/5 plans incl. gap-closure 19-05; verifier 5/5 must-haves on re-verification). Shipped: 5-dimension source-type extension contract in `schema/reference/source-types.md` with retro-fit table; `source_type: research-report` as the worked secondary instance (second-order provenance, `derived` support type, `mixed`/`tentative` epistemic defaults); `#r<n>` reference locator + 5th audit selector in `bin/audit-claims.sh`; D-08 derived-never-direct + D-09 enum lint gates (LINT_VERSION 1.9.0); 114-marker `|direct|`→`|derived|` sweep across 14 dependent pages (103 prose + 11 escaped table-cell, second pass after the table-cell blind spot); both AI deep-research report source pages retro-classified with `## References` registries; DR `dr-2026-06-10-source-type-contract`. Gap cycle: initial verification caught 11 residual `\|direct\|` table-cell markers + a vacuous D-08 gate (PROV_RE didn't strip the table-cell `\|` backslash) — both fixed in 19-05. Code review (advisory) 0 critical / 7 warning / 7 info — notable: 71% of `--select derived-report` audit claims return `insufficient-locator` (`#sec:` slug mismatches), audit-claims locator keeps a trailing backslash on table-cell markers, third report-shaped source not retro-classified — tracked in `19-REVIEW.md` for follow-up. `gsd phase.complete` again mis-advanced to superseded backlog 999.1; hand-corrected to Phase 20. Next: `/gsd-discuss-phase 20` (PDF Ingestion).*

---
*Last updated: 2026-06-10 — Milestone **v1.3 Source Ingestion** started. Scope: source-type extension contract (5-dimension recipe) + research-report ingest type (seed design LOCKED, ships first) + PDF ingestion (olmOCR 2 via Ollama, `#p` locator reuse) + YouTube video ingestion (external `stt` CLI with timestamped output, `#t` locator reuse). 999.5 drift detection explicitly deferred. Decision context captured in `.planning/todos/pending/2026-06-10-v1-3-source-ingestion-milestone-accept-pdf-olmocr2-youtube-s.md` + seeds `research-report-ingest` / `primary-source-type-extensions`. Next: requirements → roadmap.*

---
*Last updated: 2026-06-08 — **Milestone v1.2 Schema Architecture SHIPPED + ARCHIVED.** Phases 15–18 complete (15 plans); 28/28 requirements Complete. The 1,689-line AGENTS.md/CLAUDE.md monolith reduced to a ~287-line resident core via an inclusion test, the rest extracted to `schema/reference/*.md` + `schema/workflows/*.md`; asymmetric two-dir privacy (`wiki-cloud/`/`wiki-local/`) enforced as a harness permission; thin drift-gated `.claude/skills/` overlay added. Archived to `.planning/milestones/v1.2-*`; ROADMAP collapsed (Backlog preserved); `REQUIREMENTS.md` removed for a fresh next-milestone; RETROSPECTIVE updated; git tag `v1.2`. Open items at close (5) acknowledged as pre-existing deferrals — see STATE.md Deferred Items. Next: `/gsd-new-milestone`.*

---
*Last updated: 2026-06-08 — Phase 18 (Skills Overlay, `SKILL-01..02`) complete (3/3 plans, 11/11 must-haves) — **closes milestone v1.2 Schema Architecture** (Phases 15–18 all done). Shipped a thin `.claude/skills/` overlay: four pointer-only routers (`ingest`/`query`/`lint`/`reflect`), each a ≤3-line body invoking `schema/workflows/{op}.md` — zero authoritative content (markdown remains the SOT). Generated and drift-gated by `bin/gen-skills.sh --check` (regenerate-diff + 6 structural assertions: body-line, dir-purity, dead-pointer, YAML-safety, first-person, no-disable-model-invocation), wired into the pre-commit hook (sync-claude → gen-skills → lint) and a hard-fail CI `skills-check` job; `.gitignore` flipped to `.claude/*` file-glob form to track the four SKILL.md; neutrality gate extended to `.claude/skills`. TDD harness `tests/phase-18/` 10/10 green. Cross-phase regression gate: one stale prior test (`tests/phase-09/test_lint_workflow.sh` hard-coded exactly-3 CI jobs) updated for the intended new `skills-check` job; all other prior-phase harness failures confirmed pre-existing at the pre-phase baseline. Code review (advisory) found 0 blocker / 6 warning / 3 info; the warnings cluster on `gen-skills.sh` cwd-relative path resolution (latent — hook/CI always run from root) and tests not `cd`-ing to repo root, tracked in `18-REVIEW.md` for follow-up. `gsd phase.complete` again mis-advanced to SUPERSEDED backlog Phase 999.1; hand-corrected STATE to reflect v1.2 milestone-complete. Next: `/gsd-complete-milestone`.*

---
*Last updated: 2026-06-07 — Phase 17 (Workflow Extraction, `WF-01..09`) complete (4/4 plans, 9/9 must-haves). §9/10/11.1–11.7/12 extracted out of the AGENTS.md/CLAUDE.md monolith into `schema/workflows/{structured-operations,ingest,query,lint,reflect,brownfield,release,audit}.md` + `schema/reference/log-format.md`; §10 folded into `ingest.md` (diagram retained in core), no `pipeline.md`; resident core shrank 1,689→287 lines with 14 per-section inclusion justifications. Headline deliverable: a new `routing` lint category (`bin/lint.sh`, LINT_VERSION 1.8.0) — forward dangling-ref/`§N` violations → error, inverse orphan-file → warning, WF-08 inclusion-audit drift → info — exits 0 over the live tree. Byte-equality (`sync-claude --check`), neutrality, and privacy gates all green. Code review (advisory) found 0 blocker / 5 warning / 3 info; the 3 verifier-gated doc-drift items (WR-01 routing undocumented in lint.md, WR-02 DR named nonexistent files, WR-03 stale agent-parity wording) were fixed before close (commit 95504a4). `gsd phase.complete` again mis-advanced to superseded backlog Phase 999.1; hand-corrected to the real next phase, 18 (Skills Overlay). Next: `/gsd-discuss-phase 18` or `/gsd-plan-phase 18`.*

*Last updated: 2026-06-04 — Milestone **v1.2 Schema Architecture** started (promoted from backlog 999.4). Goal: apply the spec's own §7 progressive-disclosure principle to itself — reduce the always-loaded `AGENTS.md`/`CLAUDE.md` (1,689 lines) to a ~145-line resident core via an inclusion test (ambient / unscriptable-unacceptable-miss / dispatch), extracting the rest into `schema/reference/*.md` + `schema/workflows/*.md`. Committed scope: Phase 0 (`PRIV`, asymmetric two-dir privacy — gates A) + Phase A (`REF`, reference extraction) + Phase B (`WF`, workflow extraction) + Phase C (`SKILL`, optional skills overlay). Phase D (`WIZ`) deferred. Research skipped (internal refactor — relocates text, not logic). Phase numbering continues from 14. Preserved `999.4-…/CONTEXT-NOTES.md` (live design source) — declined the destructive `phases.clear`. Distilled from `.planning/milestones/v1.2-MILESTONE-BRIEF.md`. Next: requirements → roadmap.*

*Last updated: 2026-06-04 after v1.1.1 Graph Integrity milestone — SHIPPED + ARCHIVED. Single phase (14 — Graph Link Resolution, 3/3 plans) complete; 10/10 LINK requirements Complete (`bin/requirements-sync.sh --require-complete` exits 0). Archived to `.planning/milestones/v1.1.1-*`; ROADMAP collapsed (Backlog preserved); `REQUIREMENTS.md` removed for a fresh next-milestone; git tag `v1.1.1`. Corrected a stale STATE/PROJECT pointer to a non-existent "Phase 999.1" (that brownfield work shipped in v1.1 Phases 10–11; the backlog entry is SUPERSEDED). Deferred at close: 1 Phase-14 todo (`phase-14-lint-mask-fence-edge-cases`, WR-02/03) + 4 audit-flagged-but-complete quick tasks (see STATE.md Deferred Items). Next: `/gsd-new-milestone` (leading candidate: v1.2 Schema Architecture, backlog 999.4).*

*Last updated: 2026-06-03 — Phase 14 (Graph Link Resolution) complete, closing milestone v1.1.1 Graph Integrity. The milestone-start premise below was PROVEN FALSE mid-flight (Obsidian resolves `[[X]]` by filename/path ONLY — never by `aliases` — intentional design, confirmed for v1.12.7); caught at the LINK-10 human-verify gate. Re-planned to the corrected approach — **uniform piped links `[[id|Title]]`**: §8/§5 + 12 templates corrected, self-alias invariant removed, superseding DR `dr-2026-06-03-uniform-piped-links`; `bin/lint.sh` `linkres` re-pointed to validate link targets + `--fix` bare→piped + alias-free `orphan` + shared `mask_markdown` (LINT_VERSION 1.6.0); all `wiki/`+`examples/` body links rewritten to piped form; orphan count 19→0, exemplar `domain-driven-design` 18 inbound links; graph human-verified connected in Obsidian. Verifier 10/10; phase-09 tests 30/30 (incl. T14 masking guard). Post-merge integration fixes: masked the provenance + gap scans (review WR-01/WR-04). Deferred: lint mask fence edge-cases (WR-02/03, todo). LINK-01..10 Complete. Next: Phase 999.1 brownfield-vault-initialization.*

*Last updated: 2026-06-02 — Milestone v1.1.1 Graph Integrity started. Patch milestone correcting the Obsidian wikilink-resolution defect (Obsidian resolves `[[X]]` by filename + `aliases`, not `title`; 31/49 wiki pages render as graph orphans). Single phase (14 — Graph Link Resolution), ~3 plans in 2 waves: convention + DR ‖ lint enforcement (`linkres` + `--fix`); then data remediation across `wiki/` + `examples/`. Sequenced before the v1.2 schema refactor (999.4). Requirements LINK-01..10.*

*Last updated: 2026-06-02 after v1.1 Shareability milestone — SHIPPED + ARCHIVED. All 15 v1.1 phase directories (Phases 7–13.2, 52 plans) complete; 97/97 v1.1 requirements Complete with zero drift (`bin/requirements-sync.sh --strict --require-complete` exits 0). Phase 13.2 closure gate (CLOSE-01..04): Obsidian render re-run (Dataview 3/2/2/2/5), Codex agent-parity accepted blocked-on-host-runtime, write-back audited, docs consistency + scope-leak clean. Archived to `.planning/milestones/v1.1-*`; ROADMAP collapsed (Backlog preserved); `REQUIREMENTS.md` removed for a fresh next-milestone; git tag `v1.1`. Deferred: 1 post-v1.1 todo (a1 lexical-dedup lint), backlog 999.3–999.6, v1.2 items (Obsidian plugin, installer, hosted docs, brownfield `--apply`). Next: `/gsd-new-milestone`.*

*Last updated: 2026-05-03 — Phase 12.1 (NEUT-08 Personal-Term Denylist Curation) complete: 7-term defense-in-depth expansion appended to `.neutrality-denylist.txt` under unified `# Category: Personal-vault terms expanded curation (NEUT-08, 2026-05-02)` header (kept set: pre-committing, physical flinch, pre-mortem, pre-mortems, decision fatigue, decision-fatigue, meta-observation). Rubric revised from "hyphenated identifier unique to vault" to include (a) spaced multi-word phrases coined in archived journal sources (precedent: existing denylist uses spaced forms `loss aversion`, `system 1`) and (b) popular cog-bias terms used heavily in vault that would betray vault provenance via LLM-mediated example-leak. NEUT-08 flipped to Complete in REQUIREMENTS.md (line 36 + matrix line 215); 12.1-VERIFICATION.md authored with verbatim D-10 evidence; `bin/requirements-sync.sh --strict --phase 12.1` and `--require-complete --phase 12.1` both exit 0; `bin/check-neutrality.sh` source unchanged across the entire phase. First v1.1 partial-requirement closure, clearing the path for Phase 13.2 v1.1 closure verification gate.*

*Last updated: 2026-06-01 — Phase 13 (Claim Faithfulness Audit) complete: shipped `bin/audit-claims.sh` (FAITH-01 high-risk claim selectors → FAITH-02 raw-source locator→passage resolver → 9-key structured findings → FAITH-04 fail-closed privacy chokepoint → stdin-only `shlex.split` verifier dispatch with supports/weak/contradicts/insufficient verdicts) and `bin/lib/privacy_resolve.py` (§13 three-level fail-closed + strictest-wins effective-claim privacy). Review-only by default — no auto-fix, no CI gate, severity never `error`. AGENTS/CLAUDE §6 document the optional `<!-- page: N -->` page-marker convention and the Audit as a review-only workflow (four-operation framing preserved). FAITH-01..04 → Complete; verifier PASS 6/6 SC + 4/4 REQ; tests 33/33; `bin/requirements-sync.sh --strict/--require-complete --phase 13` both exit 0; code review 0 critical / 0 high (advisory MD-01: `--format json` omits the `--emit-worklist` HIGH-C metadata redaction — passage text not leaked). Remaining v1.1: Phase 13.1 (docs + Obsidian starter), Phase 13.2 (closure verification gate).*

*Previous: 2026-05-01 — Phase 12 (Complementary Systems Boundary + GTD Alignment) complete: `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` (BOUND-01) + `docs/reference/three-layer-model.md` (BOUND-02) + reviewed-match audit over README/AGENTS.md/docs/wiki/decisions (BOUND-03) — 6/6 grep hits all `negative-framing`, zero `positive-claim`. SPEC-anchored phase-base SHA `ef3afec`; zero `bin/`/`schema/` content drift; AGENTS.md §4 page-type enum unchanged (still 6); `bin/requirements-sync.sh --strict --phase 12` exits 0.*
