# Roadmap: LLM Wiki Compiler

## Milestones

- ✅ **v1.0 LLM Wiki Compiler MVP** — Phases 1–6 (shipped 2026-04-15) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Shareability** — Phases 7–13.2 (shipped 2026-06-02) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.1.1 Graph Integrity** — Phase 14 (shipped 2026-06-04) — [archive](milestones/v1.1.1-ROADMAP.md)
- ✅ **v1.2 Schema Architecture** — Phases 15–18 (shipped 2026-06-08) — [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 Source Ingestion** — Phases 19–21 (shipped 2026-06-14) — [archive](milestones/v1.3-ROADMAP.md)
- ✅ **v1.4 Source Lifecycle** — Phases 22–23 (shipped 2026-07-03) — [archive](milestones/v1.4-ROADMAP.md)
- 🚧 **v1.5 Python Migration** — Phases 24–26 (IN PROGRESS — started 2026-07-03; imported from the laptop, renumbered from its v1.4/22–24; Phase-24 plans hardened through 6 cross-AI review cycles; MANDATORY re-baseline executed at start per the brief) — [brief](milestones/v1.5-MILESTONE-BRIEF.md) · [requirements](REQUIREMENTS.md) · plans in `phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/`

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

<details>
<summary>✅ v1.4 Source Lifecycle (Phases 22–23) — SHIPPED 2026-07-03</summary>

Closed the source lifecycle loop: the `repository` source type as the extension contract's first PRIMARY new-type instance, plus external source drift detection (promoted backlog 999.5) as opt-in, review-only `lint --network` checks. 11/11 requirements Complete.

- [x] Phase 22: Repository Source Type (3/3 plans) — completed 2026-07-03 — `schema/reference/repository-ingestion.md` (snapshot bundle + `## Excerpts` registry), `#path:`/`#commit:` locators with fence-aware audit resolvers, lint enforcement (LINT_VERSION 1.11.0), `bin/repo-snapshot.sh`, real ingest of `open-gsd/gsd-core` (which caught live upstream drift: the documented repo home was an archived redirect); 15-finding xhigh review fully applied. (REPO-01..06)
- [x] Phase 23: External Source Drift Detection (2/2 plans) — completed 2026-07-03 — opt-in `--network` checks in the pre-plumbed `drift-external` subcategory (repo HEAD-vs-SHA, URL reachability with videos excluded, registry link-rot ratios; LINT_VERSION 1.12.0); surface-don't-mark DR; live validation run. (DRIFT-01..05)

Full phase details: [milestones/v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)

</details>

### 🚧 v1.5 Python Migration (Phases 24–26) — IN PROGRESS (started 2026-07-03)

Re-platform the `bin/` toolchain from Bash to Python behind `.sh` exec-shims (shim-and-swap): installable package + frozen shared `common/` core + `WIKI_IMPL=bash|py` parity oracle built first (the one hard serialization point), then parallel cluster ports fan out behind the frozen surface and fan back in through a single cutover; the wholesale CLI→pytest conversion is terminal and deferrable. Pure internal refactor — behavior parity is the acceptance bar throughout. Definition: [milestones/v1.5-MILESTONE-BRIEF.md](milestones/v1.5-MILESTONE-BRIEF.md); requirements promoted to [REQUIREMENTS.md](REQUIREMENTS.md) at start; MANDATORY re-baseline (per the brief) executed at milestone start — see `phases/24-.../24-REBASELINE.md`.

- [x] **Phase 24: Foundation — Package Skeleton + Frozen Shared Core + Parity Oracle** (6/6 plans) — completed 2026-07-03 — PKG-01..04, TEST-01..05; mandatory re-baseline executed (24-REBASELINE.md); 22-finding adversarial review applied (24-REVIEW.md — headline: the routing gate was red at HEAD, local hooks had been disabled since April, and a subshell capture-key collision gutted per-call parity coverage; all fixed + re-verified; baseline re-pinned at 9905bf0 via the D-09 flow)
  - [x] 24-01: Package skeleton + shim-contract doc (wave 1) — 16 stubs (RB-1)
  - [x] 24-02: common/ over-extraction (wave 2)
  - [x] 24-03: Parity seam (WIKI_IMPL) + pytest conftest (wave 2)
  - [x] 24-04: Characterization-golden backfill + anti-signal rewrite (wave 3)
  - [x] 24-05: CI wiring + parity matrix (wave 4) — 228 sites seam-routed
  - [x] 24-06: Freeze guard + baseline pin + phase-24-freeze tag (wave 5)
- [ ] **Phase 25: Parallel Migration + Cutover** (plans TBD at plan-phase) — MIG-01..06, CUT-01, TEST-06
- [ ] **Phase 26: Wholesale CLI→Pytest Conversion** (terminal, deferrable) — CUT-02

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
| 22. Repository Source Type | v1.4 | 3/3 | Complete    | 2026-07-03 |
| 23. External Source Drift Detection | v1.4 | 2/2 | Complete    | 2026-07-03 |
| 24. Foundation: Skeleton + Frozen Core + Parity Oracle | v1.5 | 6/6 | Complete | 2026-07-03 |
| 25. Parallel Migration + Cutover | v1.5 | TBD | Pending | — |
| 26. Wholesale CLI→Pytest Conversion (deferrable) | v1.5 | TBD | Pending | — |
