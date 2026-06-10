# Roadmap: LLM Wiki Compiler

## Milestones

- ✅ **v1.0 LLM Wiki Compiler MVP** — Phases 1–6 (shipped 2026-04-15) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Shareability** — Phases 7–13.2 (shipped 2026-06-02) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.1.1 Graph Integrity** — Phase 14 (shipped 2026-06-04) — [archive](milestones/v1.1.1-ROADMAP.md)
- ✅ **v1.2 Schema Architecture** — Phases 15–18 (shipped 2026-06-08) — [archive](milestones/v1.2-ROADMAP.md)
- 🚧 **v1.3 Source Ingestion** — Phases 19–21 (started 2026-06-10)

## Phases

<details>
<summary>✅ v1.0 LLM Wiki Compiler MVP (Phases 1–6) — SHIPPED 2026-04-15</summary>

- [x] Phase 1: Schema, Structure & Conventions (3/3 plans) — completed 2026-04-09
- [x] Phase 2: Page Types, Examples & Navigation (3/3 plans) — completed 2026-04-10
- [x] Phase 3: Ingestion & Provenance Pipeline (5/5 plans) — completed 2026-04-11
- [x] Phase 4: Query & Structured Operations (6/6 plans) — completed 2026-04-13
- [x] Phase 5: Lint & Quality (4/4 plans) — completed 2026-04-14
- [x] Phase 6: Reflection & Drift Detection (3/3 plans) — completed 2026-04-15

</details>

<details>
<summary>✅ v1.1 Shareability (Phases 7–13.2) — SHIPPED 2026-06-02</summary>

- [x] Phase 7: Neutral Template Foundation (5/5 plans) — completed 2026-04-15
- [x] Phase 8: Two-Track Setup (Wizard + Manual) (5/5 plans) — completed 2026-04-16
- [x] Phase 9: Collaborative PR Workflow + CI Lint Gate (6/6 plans) — completed 2026-04-16
- [x] Phase 10: Brownfield Scan + Bootstrap (6/6 plans) — completed 2026-04-18
- [x] Phase 11: Brownfield Suggest + Verify (5/5 plans) — completed 2026-04-20
- [x] Phase 12: Complementary Systems Boundary + GTD Alignment (4/4 plans) — completed 2026-05-01
- [x] Phase 12.1: NEUT-08 Personal-Term Denylist Curation (4/4 plans) — completed 2026-05-03
- [x] Phase 12.2: Local Wiki Write Gate (5/5 plans) — completed 2026-05-04
- [x] Phase 13: Claim Faithfulness Audit (5/5 plans) — completed 2026-06-01
- [x] Phase 13.1: Docs Finalization + Obsidian Starter (5/5 plans) — completed 2026-06-01
- [x] Phase 13.2: v1.1 Closure Verification Gate (3/3 plans) — completed 2026-06-02

Full phase details: [milestones/v1.1-ROADMAP.md](milestones/v1.1-ROADMAP.md)

</details>

<details>
<summary>✅ v1.1.1 Graph Integrity (Phase 14) — SHIPPED 2026-06-04</summary>

- [x] Phase 14: Graph Link Resolution (3/3 plans) — completed 2026-06-03 — uniform piped links `[[id|Title]]` convention + `linkres` target validation + `wiki/`/`examples/` remediation; orphan count 19→0, connected graph human-verified. (LINK-01..10)

Full phase details: [milestones/v1.1.1-ROADMAP.md](milestones/v1.1.1-ROADMAP.md)

</details>

<details>
<summary>✅ v1.2 Schema Architecture (Phases 15–18) — SHIPPED 2026-06-08</summary>

Applied the spec's own §7 progressive-disclosure principle to itself — the always-loaded `AGENTS.md`/`CLAUDE.md` monolith (1,689 lines) reduced to a ~287-line resident core decided by an inclusion test, the rest extracted into `schema/reference/*.md` + `schema/workflows/*.md`. 28/28 requirements Complete.

- [x] Phase 15: Privacy Architecture (3/3 plans) — completed 2026-06-04 — asymmetric two-directory model (`wiki-cloud/` / `wiki-local/`), one-way permeability enforced as a harness `deny`-read permission; per-page §13 privacy dissolved. (PRIV-01..07)
- [x] Phase 16: Reference Extraction (5/5 plans) — completed 2026-06-05 — §4/5/6/7/8/13 → `schema/reference/*.md`, §14/15 → `docs/reference/*.md`, §16 deleted, `IMPORTANT:` routing table added. (REF-01..10)
- [x] Phase 17: Workflow Extraction (4/4 plans) — completed 2026-06-07 — §9/10/11.1–11.7/12 → `schema/workflows/*.md`; core 1,689→287 lines; new `routing` lint category (LINT_VERSION 1.8.0). (WF-01..09)
- [x] Phase 18: Skills Overlay (3/3 plans) — completed 2026-06-08 — four thin pointer-only `.claude/skills/*/SKILL.md` routers, generated + drift-gated by `bin/gen-skills.sh --check`, wired into pre-commit + CI; zero authoritative content. (SKILL-01..02)

Full phase details: [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)

</details>

## v1.3 Source Ingestion (Phases 19–21)

**Goal:** Formalize three new source ingestion paths — AI deep-research reports, PDFs, and YouTube videos — as schema conventions plus documented acquisition pipelines, designed once via a shared source-type extension contract.

- [ ] **Phase 19: Extension Contract + Research-Report Type** - Define the 5-dimension source-type extension contract extracted from real cases, with `research-report` as the worked secondary instance; implement the full `source_type: research-report` convention including second-order provenance, epistemic defaults, and retro-classification of the two existing AI reports
- [ ] **Phase 20: PDF Ingestion** - Document the PDF acquisition pipeline (olmOCR 2 via Ollama), define the PDF sub-case convention with page-anchored provenance and VLM-hallucination guidance, and validate end-to-end with a real PDF artifact
- [ ] **Phase 21: Video/YouTube Ingestion** - Document the video acquisition pipeline (yt-dlp + timestamped STT), define the video-as-transcript sub-case convention with timestamp-anchored provenance and drift stance, and validate end-to-end with a real YouTube video

## Phase Details

### Phase 19: Extension Contract + Research-Report Type

**Goal**: The schema has a formal, reusable extension contract for adding source types, and the `research-report` type is fully implemented as the contract's worked secondary instance
**Depends on**: Nothing (first v1.3 phase; v1.3 editing targets are modular `schema/reference/*.md` + `schema/workflows/*.md` files, not the pre-extraction monolith)
**Requirements**: EXT-01, EXT-02, EXT-03, RPT-01, RPT-02, RPT-03, RPT-04, RPT-05, RPT-06
**Success Criteria** (what must be TRUE):

  1. An agent reading `schema/reference/` can find a single source-type extension contract that lists the 5 dimensions and the primary-vs-secondary axis, and can use it to evaluate whether any new candidate justifies a new type or is a sub-case
  2. The contract includes a retro-fit table mapping all current source types across the 5 dimensions, so a reader can see how existing types are instances of the same contract
  3. An agent ingesting an AI deep-research report finds `source_type: research-report` in the frontmatter enum and Pass-0 classification, knows to preserve the bibliography in the raw source, and captures it as an addressable citation registry in the source summary
  4. Claims extracted from a research report carry `support_type: derived` (never `direct`) and a lower epistemic default (`mixed`/`tentative`), making the second-order-ness visible in every provenance marker
  5. The two existing AI deep-research reports already in `sources/` have been retro-classified with `source_type: research-report` and their citation registries backfilled in their source summary pages

**Plans**: 4 plans (3 waves)
Plans:
**Wave 1**

- [x] 19-01-PLAN.md — Extension contract (source-types.md) + routing table row + frontmatter enum + ingest Pass 0
- [x] 19-02-PLAN.md — Provenance #r<n> locator + audit-claims.sh derived-report selector + audit.md documentation

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 19-03-PLAN.md — bin/lint.sh D-08/D-09/version + report-citing direct→derived sweep (103 markers, 14 dependent pages)

**Wave 3** *(blocked on Wave 2 — 19-04 needs 19-03's D-09 enum live before setting `source_type: research-report`; its final gate proves D-08 non-vacuously)*

- [ ] 19-04-PLAN.md — Source summary retro-classification + citation registries + log + DR + phase-final combined lint gate

### Phase 20: PDF Ingestion

**Goal**: PDF documents can be acquired via a documented pipeline and ingested as a sub-case of an existing source type, with page-anchored provenance and honest epistemic handling for degraded scans
**Depends on**: Phase 19 (extension contract defines the evaluation rule applied to confirm PDF is a sub-case, not a new type)
**Requirements**: PDF-01, PDF-02, PDF-03, PDF-04
**Success Criteria** (what must be TRUE):

  1. An agent can find a documented PDF acquisition pipeline in `schema/` — running olmOCR 2 via the local Ollama instance produces a Markdown file with `<!-- page: N -->` markers ready for standard ingest
  2. A source summary page for a PDF document records the extraction tool and model version in frontmatter, and every claim uses `#p<N>` locators pointing to the correct page
  3. When a PDF is a degraded or scanned document, the convention specifies spot-verification steps and/or mandates a lower epistemic default — an agent does not silently treat VLM-extracted text as high-confidence
  4. One real PDF artifact has been acquired via the pipeline, ingested, and its wiki pages are in `sources/` with page-anchored provenance; the original PDF co-exists as a bundle asset alongside `source.md`

**Plans**: TBD
**UI hint**: no

### Phase 21: Video/YouTube Ingestion

**Goal**: YouTube videos can be acquired via a documented pipeline and ingested as a sub-case of the transcript source type, with timestamp-anchored provenance and a clear drift stance
**Depends on**: Phase 19 (extension contract defines the evaluation rule confirming video is a transcript sub-case)
**Requirements**: VID-01, VID-02, VID-03, VID-04
**Success Criteria** (what must be TRUE):

  1. An agent can find a documented video acquisition pipeline in `schema/` describing yt-dlp + timestamped STT to produce a speaker-labeled transcript ready for standard ingest (tool-generic in template-public docs; the local STT tool is the worked instance in `.planning/` notes)
  2. A source summary page for a YouTube video records `url`, `channel`, `title`, `publish_date`, and `duration` in frontmatter, and every claim uses `#t<start>-<end>` locators that resolve to the transcript
  3. The convention explicitly states the drift stance for videos: immutable once published; concern is deletion/link-rot, not content change; no drift machinery is needed or implemented
  4. One real YouTube video has been acquired via the pipeline, ingested, and its wiki pages are in `sources/` with timestamp-anchored provenance

**Plans**: TBD
**UI hint**: no

## Backlog

> **Live / promotable:** Phases 999.3–999.6 below are the active backlog. Historical entries (superseded / promoted / delivered: 999.1, 999.2, 999.7) are collected under "Archived / Delivered" at the end of this section, retained for traceability only — do not plan against them.

### Phase 999.3: Template Placeholder System for Published Surfaces (BACKLOG)

**Goal:** [Captured for future planning] Extend the `{{...}}` placeholder pattern — currently only on `AGENTS.template.md` (4 placeholders: `{{AGENT_FILENAME}}`, `{{DECAY_PROFILE}}`, `{{DEFAULT_PRIVACY}}`, `{{PRIMARY_DOMAIN}}`) — to other template-shaped surfaces (`README.md` title, and potentially `PRIVACY.md`, `docs/quickstart.md`, `docs/guided-setup.md`). Have `bin/init-wizard.sh` substitute them at adoption time. Enforce the placeholder set with a test analogous to `tests/phase-07/test_agents_template_placeholders.sh`.
**Origin:** Surfaced 2026-04-16 while resolving a `test_readme.sh` regression from the voice-pass commit `ed6f7e0`. Option C in the README placeholder tradeoff analysis — deferred today because the existing `<org>/<repo>` prose convention works and expanding the placeholder set touches init-wizard + schema + tests in concert (not a one-line fix). Short-term fix: Option A (revert README title to `<org>/<repo>`).
**Relevant prior art:** Phase 8 WZRD-07 reduced the `AGENTS.template.md` placeholder set from 6 to 4 per D-02 (minimalism). This backlog item moves in the OPPOSITE direction for a different surface — whoever plans this should re-visit that minimalism decision first and justify any expansion against it.
**Scope to scope at planning time:** which published surfaces benefit enough to justify placeholders vs. leaving prose conventions in place.
**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with /gsd-review-backlog when ready)

### Phase 999.4: v1.2 Schema Architecture — Progressive Disclosure Refactor (DELIVERED — promoted to v1.2 milestone, shipped 2026-06-08)

> **Delivered as milestone v1.2 Schema Architecture** (Phases 15–18, shipped 2026-06-08). Retained for traceability only — do not plan against it. See [milestones/v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md).

**Goal:** [Captured for future planning] Reduce `AGENTS.md` / `CLAUDE.md` from ~1,412 lines (post-09.1) to a 500–700 line core by extracting procedural workflows, schema reference tables, and validation checklists into plain markdown under `schema/reference/*.md` and `schema/workflows/*.md`. Preserve markdown-authoritative architecture (Claude-optimized, harness-portable). Add optional `.claude/skills/` thin-wrapper overlay as a last step. Proposed as a standalone v1.2 milestone titled "Schema Architecture," not a v1.1 phase.

**Origin:** Surfaced 2026-04-16 during a design thread reviewing the project against Anthropic Agent Skills best-practices. Diagnosis: Phase 09.1 extracted the easy ~21% (worked examples + appendices); remaining ~79% is workflow procedures and schema reference material. Spec loaded every turn, violating the project's own §7 progressive disclosure principle (applied to wiki pages but not to the spec itself).

**Advisor-corrected direction:** Markdown-first, not Claude-skills-first. Two independent advisors rejected a `.claude/skills/`-centric extraction as vendor coupling. Adopted framing: *Claude-optimized, markdown-authoritative, future-harness-friendly.* Core target raised from an initially-proposed 180 lines to 500–700 lines to preserve always-loaded safety invariants (privacy defaults, provenance requirement, MUST NOT list, write-back mandatory, structured-op vocabulary).

**Proposed phase sequence within v1.2:**

- **Phase A — Reference extraction** (low-risk): §4, §5, §6, §7, §8, §13 → `schema/reference/*.md`; §14, §15 → `docs/reference/*.md`; §16 deleted.
- **Phase B — Workflow extraction** (medium-risk): §9, §10, §11.1–11.4 → `schema/workflows/*.md`; §12 structured-op details → `schema/reference/log-format.md`.
- **Phase C — Claude skills overlay** (optional): thin `.claude/skills/` wrappers pointing to `schema/workflows/*.md`; skill body is one paragraph (router pattern). Consider `disable-model-invocation: true` for explicit triggering.

**Acceptable alternative:** Narrow Phase 09.2 doing only Phase A under v1.1 (captures ~50–60% of the reduction at low risk), deferring B + C to v1.2.

**Constraints to preserve:** `AGENTS.md` ↔ `CLAUDE.md` byte-equality via `.githooks/pre-commit`; `bin/init-wizard.sh` rendering pipeline; CI gates (lint / privacy-leak / strict / neutrality / setup-parity); `local_only` fail-closed semantics; `bin/lint.sh` / `bin/validate-op.sh` / `bin/check-privacy.sh` enforcement unchanged (they operate on content, not file boundaries).

**Open questions for `/gsd-discuss-phase`:** milestone vs. single phase; exact core line target within 500–700 range; include Phase C in v1.2 or defer to v1.3; split §6 provenance/decay at extraction time or follow-up; differentiation between `docs/reference/` (end-user) and `schema/reference/` (agent-authoritative); extension of `bin/sync-claude.sh` to the full `schema/` tree; wizard behavior for the extracted tree; evolution of AGENTS.md's "sole authoritative specification" framing.

**Detailed design notes:** see `.planning/phases/999.4-v1-2-schema-architecture-progressive-disclosure-refactor/CONTEXT-NOTES.md` — comprehensive thread capture including extraction table (section → target file), best-practice recommendations beyond extraction, constraints checklist, research lineage, and draft exit criteria.

**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with /gsd-review-backlog when ready)

### Phase 999.5: External Source Drift Detection (BACKLOG)

**Goal:** [Captured for future planning] Extend drift detection from local source-file hash changes to URL-backed sources, marking affected source summaries `stale` when upstream content changes.
**Origin:** Surfaced 2026-04-24 during roadmap review. Valuable once the wiki contains more live web-backed sources, but lower leverage than local write gating (Phase 12.2), boundary clarification (Phase 12), and claim faithfulness audit (Phase 13).
**See also:** `.planning/seeds/research-report-ingest.md` — ingesting AI deep-research reports produces URL-backed citation registries that are the natural trigger to promote this; best designed together or back-to-back.
**Non-goals:**

- No broad web-ingestion system
- No automatic re-compilation by default
- No mandatory network dependency for core workflows

**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with /gsd-review-backlog when ready)

### Phase 999.6: Observed GTD Review Patterns (BACKLOG)

**Goal:** [Captured for future planning] Document GTD-review and agent-backend integration patterns only after they have been used repeatedly in real practice.
**Origin:** Surfaced 2026-04-24 during roadmap review. The system should document what has worked, not what ought to work in theory — this prevents speculative template-kit documentation.

**Trigger to promote:**

- Compendium has been used in a GTD review loop for at least 2 months
- At least 3 Dataview queries or review views are actually re-run in practice
- At least 2–3 review behaviors have proven durable enough to describe as patterns rather than experiments

**Scope when promoted:**

- Capture observed review patterns
- Distinguish durable patterns from one-off experiments
- Document how compendium complements task/working-memory systems in practice

**Non-goals:**

- No task-manager features
- No premature dashboards marketed as canonical
- No GTD-specific filesystem/schema expansion without separate justification

**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with /gsd-review-backlog when ready)

### Archived / Delivered (historical — do not plan against)

These entries are retained for traceability only. Each was superseded by, promoted into, or delivered as active work; no further planning should target them.

### Phase 999.1: Brownfield Vault Initialization (SUPERSEDED — absorbed into v1.1 Phases 10–11)

**Status:** Superseded 2026-04-15. The backlog goal — scan/bootstrap/suggest/verify workflow for existing Obsidian vaults — is fully captured by v1.1 Phases 10 (Scan + Bootstrap) and 11 (Suggest + Verify) under REQ-IDs BRWN-01..21. This entry is retained for historical traceability only; do not plan new work against it.

**Supersedes:** promoted backlog → v1.1 Phases 10–11
**Original goal:** Workflow to scan an existing Obsidian vault with non-conforming pages and bring them into compliance: schema inference, bulk frontmatter injection, provenance bootstrapping, index auto-generation, template application, and conformance linting with auto-fix.

### Phase 999.2: NEUT-08 Personal-Term Denylist Curation (PROMOTED — see Phase 12.1)

**Status:** Promoted 2026-05-01 to active v1.1 as **Phase 12.1** so the only outstanding partial v1.1 requirement (NEUT-08) clears before the Phase 13.2 closure gate. This entry is retained for historical traceability only; do not plan new work against it.

**Promoted to:** Phase 12.1 (NEUT-08 Personal-Term Denylist Curation)
**Original goal:** Hand-review `.planning/backlog-neutrality-denylist-candidate.txt` (861 lines of deterministic `bin/check-neutrality.sh --suggest-denylist` output) and merge a curated personal-domain term set into `.neutrality-denylist.txt`. Ships today with Kahneman category only (10 lines); infrastructure (gate + suggest + candidate) is complete. Remaining work is human curation, not engineering.
**Origin:** Phase 7 scope-deferred per user (reaffirmed 2026-04-16 during human-UAT walkthrough). Tracked in REQUIREMENTS.md as NEUT-08 "Deferred (partial)"; evidence in `.planning/phases/07-neutral-template-foundation/07-VERIFICATION.md` `human_verification_deferred` block.

### Phase 999.7: requirements-sync Strict-Mode Completion Check (DELIVERED via quick task 260501-g5n on 2026-05-01)

**Status:** Delivered 2026-05-01 via `/gsd-quick` (quick task `260501-g5n` at `.planning/quick/260501-g5n-requirements-sync-strict-mode-completion/`). Promoted directly from backlog without a standalone phase since the work was scope-trivial (one CLI flag + 4 tests). `bin/requirements-sync.sh` now accepts `--require-complete`, which exits 2 when any in-scope REQ-ID has status != Complete in REQUIREMENTS.md. Composes with `--phase N` for phase-scope closure. Phase 13.2 closure can now consume `--require-complete` instead of relying on `--strict` alone (which only detects drift, not incompleteness).

**Goal:** [Captured for future planning — historical] Extend `bin/requirements-sync.sh --strict` so it fails when active requirements are still `Pending` at phase/milestone closure, not just when REQUIREMENTS.md and VERIFICATION.md drift.
**Origin:** Surfaced 2026-05-01 while reconciling Phase 12.1 (NEUT-08 promotion). Current strict mode passes trivially for any active-but-unstarted phase: `requirements-sync --phase 12.1 --strict` reports "0 drift / NEUT-08 Pending / not found / ok" and exits 0. This means closure gates that lean only on `requirements-sync --strict` cannot detect incomplete work — they can only detect *inconsistent* work. Phase 12.1's success criterion now requires a verification artifact in addition to the drift check; longer term the script itself should encode a closure-mode check.
**Trigger to promote:**

- Multiple phases approaching closure want a single mechanical "all required REQ-IDs Complete" gate, OR
- The Phase 13.2 closure-verification gate authoring exposes the same gap and benefits from a shared primitive.

**Scope when promoted:**

- New flag (e.g., `--require-complete` or `--mode closure`) that fails when any in-scope REQ-ID has `Pending` status in REQUIREMENTS.md
- Composes with `--phase N` for phase-scope closure and `--milestone X` (if added) for milestone-scope closure
- Preserves backward compatibility: default `--strict` semantics (drift-only) unchanged

**Non-goals:**

- No automatic status flipping
- No replacement of human-authored verification artifacts
- No coupling to a specific milestone's closure script

**Requirements:** TBD
**Plans:** 0 plans

Plans:

- [ ] TBD (promote with /gsd-review-backlog when ready)

### Explicitly Deferred

The following are intentionally deferred until real usage demands them, captured here so the roadmap does not drift into "compendium as everything":

- **Tier 2–4 scaling work** (`split index`, `incremental lint`, SQLite metadata) — see AGENTS.md §14 scaling tiers; only promote when observed signals warrant it.
- **Multi-agent merge UX beyond current git/PR discipline** — `CONTRIBUTING.md` + `docs/reference/ci.md` cover the current Phase 9 contract.
- **Canonical GTD review dashboards or workflow-specific Dataview surfaces** — review surfaces emerge from observed practice (see Phase 999.6), not speculative design.
- **Hotkey bundles / editor-personalization packs** — out of scope for the shipped starter; users personalize their own Obsidian config.
- **Task, reminder, calendar, inbox, or waiting-for engine features inside compendium** — excluded by the Phase 12 system boundary.
- **High-frequency event / Slack / ticket / operational data ingestion** — excluded by the Phase 12 system boundary.

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 1. Schema, Structure & Conventions | v1.0 | 3/3 | Complete | 2026-04-09 |
| 2. Page Types, Examples & Navigation | v1.0 | 3/3 | Complete | 2026-04-10 |
| 3. Ingestion & Provenance Pipeline | v1.0 | 5/5 | Complete | 2026-04-11 |
| 4. Query & Structured Operations | v1.0 | 6/6 | Complete | 2026-04-13 |
| 5. Lint & Quality | v1.0 | 4/4 | Complete | 2026-04-14 |
| 6. Reflection & Drift Detection | v1.0 | 3/3 | Complete | 2026-04-15 |
| 7. Neutral Template Foundation | v1.1 | 5/5 | Complete | 2026-04-15 |
| 8. Two-Track Setup (Wizard + Manual) | v1.1 | 5/5 | Complete | 2026-04-16 |
| 9. Collaborative PR Workflow + CI Lint Gate | v1.1 | 6/6 | Complete | 2026-04-16 |
| 10. Brownfield Scan + Bootstrap | v1.1 | 6/6 | Complete    | 2026-04-18 |
| 11. Brownfield Suggest + Verify | v1.1 | 5/5 | Complete    | 2026-04-20 |
| 12. Complementary Systems Boundary + GTD Alignment | v1.1 | 4/4 | Complete    | 2026-05-01 |
| 12.1. NEUT-08 Personal-Term Denylist Curation | v1.1 | 4/4 | Complete    | 2026-05-03 |
| 12.2. Local Wiki Write Gate | v1.1 | 5/5 | Complete    | 2026-05-04 |
| 13. Claim Faithfulness Audit | v1.1 | 5/5 | Complete | 2026-06-01 |
| 13.1. Docs Finalization + Obsidian Starter | v1.1 | 5/5 | Complete | 2026-06-01 |
| 13.2. v1.1 Closure Verification Gate | v1.1 | 3/3 | Complete | 2026-06-02 |
| 14. Graph Link Resolution | v1.1.1 | 3/3 | Complete    | 2026-06-03 |
| 15. Privacy Architecture | v1.2 | 3/3 | Complete    | 2026-06-04 |
| 16. Reference Extraction | v1.2 | 5/5 | Complete    | 2026-06-05 |
| 17. Workflow Extraction | v1.2 | 4/4 | Complete    | 2026-06-07 |
| 18. Skills Overlay | v1.2 | 3/3 | Complete    | 2026-06-08 |
| 19. Extension Contract + Research-Report Type | v1.3 | 2/4 | In Progress|  |
| 20. PDF Ingestion | v1.3 | 0/TBD | Not started | - |
| 21. Video/YouTube Ingestion | v1.3 | 0/TBD | Not started | - |
