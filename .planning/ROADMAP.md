# Roadmap: LLM Wiki Compiler

## Milestones

- ✅ **v1.0 LLM Wiki Compiler MVP** — Phases 1–6 (shipped 2026-04-15) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Shareability** — Phases 7–13.2 (shipped 2026-06-02) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.1.1 Graph Integrity** — Phase 14 (shipped 2026-06-04) — [archive](milestones/v1.1.1-ROADMAP.md)
- ✅ **v1.2 Schema Architecture** — Phases 15–18 (shipped 2026-06-08) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Source Ingestion** — Phases 19–21 (shipped 2026-06-14) — [archive](milestones/v1.3-ROADMAP.md)
- 🚧 **v1.4 Source Lifecycle** — Phases 22–23 (started 2026-07-03)
- 📦 **v1.5 Python Migration** — Phases 24–26 (STAGED — imported from the laptop 2026-07-03, renumbered from its v1.4/22–24; Phase-24 plan hardened through 6 cross-AI review cycles, ready to execute after v1.4 closes with a MANDATORY re-baseline) — [brief](milestones/v1.5-MILESTONE-BRIEF.md) · [requirements](milestones/v1.5-REQUIREMENTS-STAGED.md) · plans in `phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/`

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

<details>
<summary>✅ v1.3 Source Ingestion (Phases 19–21) — SHIPPED 2026-06-14</summary>

Formalized three new source ingestion paths — AI deep-research reports, PDFs, and YouTube videos — as schema conventions plus documented acquisition pipelines, designed once via a shared source-type extension contract. 17/17 requirements Complete.

- [x] Phase 19: Extension Contract + Research-Report Type (5/5 plans incl. gap-closure wave) — completed 2026-06-10 — 5-dimension extension contract + `source_type: research-report` (second-order provenance, `derived`-only markers, `#r<n>` locators, D-08/D-09 lint gates); three report sources retro-classified. (EXT-01..03, RPT-01..06)
- [x] Phase 20: PDF Ingestion (4/4 plans) — completed 2026-06-12 — `bin/pdf-extract.sh` acquisition glue + authoritative `schema/reference/pdf-ingestion.md`; PDF as article/paper sub-case with `#p<N>` locators + VLM-hallucination epistemic guidance; real-PDF validation ingest. (PDF-01..04)
- [x] Phase 21: Video/YouTube Ingestion (2/2 plans) — completed 2026-06-14 — authoritative `schema/reference/video-ingestion.md`; video as transcript sub-case with `#t<start>-<end>` locators, five frontmatter fields, link-rot drift stance; real 3-speaker YouTube validation ingest. (VID-01..04)

Full phase details: [milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)

</details>

## v1.4 Source Lifecycle (Phases 22–23)

**Goal:** Close the source lifecycle loop — formalize the `repository` source type as the extension contract's first *primary* new-type instance (locators, snapshot convention, epistemic split, lint enforcement), then ship external-source drift detection (backlog 999.5) as an opt-in, review-only extension of lint's pre-plumbed `drift-external` subcategory, with repository SHA drift as the pilot case.

- [x] **Phase 22: Repository Source Type** - Justify `source_type: repository` via the extension contract, define `#path:`/`#commit:` locators + the curated-snapshot bundle convention + the within-source epistemic split, enforce via lint/audit, and validate end-to-end with a real repository (completed 2026-07-03)
- [x] **Phase 23: External Source Drift Detection** - Extend lint's `drift`/`EXTERNAL:` subcategory with opt-in `--network` checks (repository HEAD-vs-SHA, URL reachability, citation-registry link-rot), review-only with documented follow-up guidance, validated by a real run over the live wiki (completed 2026-07-03)

## Phase Details

### Phase 22: Repository Source Type

**Goal**: Code repositories can be acquired via a documented snapshot pipeline and ingested as a first-class primary source type, with file/line-anchored provenance that the audit can actually resolve
**Depends on**: Nothing within v1.4 (consumes the Phase 19 extension contract; first primary new-type instance)
**Requirements**: REPO-01, REPO-02, REPO-03, REPO-04, REPO-05, REPO-06
**Success Criteria** (what must be TRUE):

  1. An agent reading `schema/reference/source-types.md` finds `repository` in the retro-fit table with the contract evaluation recorded (locator + drift + acquisition + epistemics all change → new primary type, not a sub-case), and `source_type: repository` in the frontmatter enum + ingest Pass-0
  2. An agent ingesting a repository finds a documented acquisition runbook producing a curated snapshot bundle — README + key docs + an addressable `## Excerpts` registry + metadata frontmatter (`repo_url`, `commit_sha`, `default_branch`, `license`, `primary_language`) — explicitly NOT a full clone; thin glue in `bin/` scaffolds it
  3. Claims anchor to `#path:<file>[:L<n>[-L<m>]]` / `#commit:<sha>` locators documented in the provenance locator table, and `bin/audit-claims.sh` resolves `#path:` locators against the snapshot's excerpt registry (missing excerpt degrades honestly to `insufficient-locator`)
  4. The within-source epistemic split is documented and exercised: code/benchmark claims `sourced`, self-descriptive capability claims hedged claim-level `tentative`; `knowledge_domain: software` decay applies
  5. Lint enforces the type — D-09 enum extended, conditional required-fields check (`repo_url` + `commit_sha`), LINT_VERSION bumped — and a lint run over the live tree stays clean
  6. One real repository has been acquired via the runbook, ingested, its wiki pages carry `#path`-anchored provenance, and a source-scoped audit run resolves its locators (non-vacuous)

**Plans**: 3 plans (3 waves)
Plans:

**Wave 1**

- [x] 22-01-PLAN.md — repository-ingestion.md convention + source-types/frontmatter/provenance/ingest edits + routing row (byte-synced)

**Wave 2** *(blocked on Wave 1)*

- [x] 22-02-PLAN.md — lint enum + conditional fields (LINT_VERSION 1.11.0) + audit #path/#commit resolvers (dispatch-order D-11) + bin/repo-snapshot.sh + tests/phase-22 TDD harness

**Wave 3** *(blocked on Wave 2 — network acquisition)*

- [x] 22-03-PLAN.md — end-to-end validation ingest (gsd-build/get-shit-done) + source-scoped audit + DR + phase-final gates

**UI hint**: no

### Phase 23: External Source Drift Detection

**Goal**: The wiki can tell when its URL-backed and repository sources have moved or died upstream — opt-in, review-only, with no new mandatory network dependency anywhere in the core workflows
**Depends on**: Phase 22 (repository SHA drift is the pilot case; the checker consumes the `commit_sha`/`repo_url` fields Phase 22 defines)
**Requirements**: DRIFT-01, DRIFT-02, DRIFT-03, DRIFT-04, DRIFT-05
**Success Criteria** (what must be TRUE):

  1. `bin/lint.sh --network` runs the new external checks; without the flag, lint output over the live tree is byte-identical to pre-phase behavior; `--ci` continues to default-skip `drift-external`
  2. Repository sources: upstream default-branch HEAD vs recorded `commit_sha` via `git ls-remote` (no clone) → `EXTERNAL:` drift warning on divergence or unreachability, silence when current
  3. URL-backed sources: dead/gone URLs → warning, redirects → info; research-report citation registries get a sampled link-rot ratio finding with documented thresholds
  4. The stance is review-only and documented in `schema/workflows/lint.md`: findings report, nothing mutates, follow-up is a human decision (re-snapshot vs annotate via UPDATE op); video sources excluded per D-06; a decision record captures the narrowed "surface, don't auto-mark" choice vs the original 999.5 sketch
  5. A real `--network` run over the live wiki has executed, covering the Phase-22 repository source and the existing URL-backed sources; findings triaged with follow-ups logged

**Plans**: 2 plans (2 waves)
Plans:

**Wave 1**

- [x] 23-01-PLAN.md — --network flag + three check families (repo HEAD drift, URL reachability, registry link-rot) + network-free tests (LINT_VERSION 1.12.0)

**Wave 2** *(blocked on Wave 1)*

- [x] 23-02-PLAN.md — lint.md External Source Drift section + DR (surface-don't-mark) + live --network validation run with triage

**UI hint**: no

## Backlog

> **Live / promotable:** Phases 999.3 and 999.6 below are the active backlog. Historical entries (superseded / promoted / delivered: 999.1, 999.2, 999.4, 999.5, 999.7) are retained for traceability only — do not plan against them.

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

### Phase 999.5: External Source Drift Detection (PROMOTED — see v1.4 Phase 23)

> **Promoted 2026-07-03** into milestone v1.4 Source Lifecycle as **Phase 23** (paired with the `repository` source type per this entry's own "best designed together or back-to-back" note — the trigger fired when v1.3 shipped research-report citation registries). Retained for traceability only — do not plan against it. Note: the "marking affected source summaries `stale`" sketch below was consciously narrowed to review-only surfacing at promotion (see the Phase 23 DR).

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
| 19. Extension Contract + Research-Report Type | v1.3 | 5/5 | Complete    | 2026-06-10 |
| 20. PDF Ingestion | v1.3 | 4/4 | Complete    | 2026-06-12 |
| 21. Video/YouTube Ingestion | v1.3 | 2/2 | Complete    | 2026-06-14 |
