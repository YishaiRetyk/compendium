# Roadmap: LLM Wiki Compiler

## Milestones

- ✅ **v1.0 LLM Wiki Compiler MVP** — Phases 1–6 (shipped 2026-04-15) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Shareability** — Phases 7–13.2 (shipped 2026-06-02) — [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.1.1 Graph Integrity** — Phase 14 (shipped 2026-06-04) — [archive](milestones/v1.1.1-ROADMAP.md)
- 🚧 **v1.2 Schema Architecture** — Phases 15–18 (in progress)

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

### 🚧 v1.2 Schema Architecture (In Progress)

**Milestone Goal:** Apply the spec's own §7 progressive-disclosure principle to itself — reduce the always-loaded `AGENTS.md`/`CLAUDE.md` (1,689 lines) to a resident core of only what passes the inclusion test (ambient / unscriptable-AND-unacceptable-miss-cost / dispatch), extracting the rest into `schema/reference/*.md` + `schema/workflows/*.md`. The ~145-line core is an expected output of the test, not a target.

- [x] **Phase 15: Privacy Architecture** — Replace per-page §13 privacy model with the asymmetric two-directory model (`wiki-cloud/` / `wiki-local/`); enforcement becomes a harness permission. Gates Phase 16. (completed 2026-06-04)
- [x] **Phase 16: Reference Extraction** — Extract §4/5/6/7/8/13 → `schema/reference/*.md`; §14/15 → `docs/reference/*.md`; §16 deleted; routing table added to core. (completed 2026-06-05)
- [x] **Phase 17: Workflow Extraction** — Extract §9/10/11.1–11.7/12 → `schema/workflows/*.md`; verify core against the inclusion test; agent-parity check. (completed 2026-06-07)
- [ ] **Phase 18: Skills Overlay** — Thin `.claude/skills/` routers (ingest/query/lint/reflect); pointer-only bodies; zero authoritative content.

## Phase Details

### Phase 15: Privacy Architecture

**Goal**: Cloud-session privacy enforcement becomes structural — enforced by directory layout and harness permissions, not by a resident agent rule the cloud model must remember each turn.
**Depends on**: Nothing (first phase of v1.2; precondition for Phase 16 extracting §13 in its rewritten form)
**Requirements**: PRIV-01, PRIV-02, PRIV-03, PRIV-04, PRIV-05, PRIV-06, PRIV-07
**Success Criteria** (what must be TRUE):

  1. `wiki-cloud/` and `wiki-local/` directories are defined in §2; the existing `wiki/` tree migration path is documented and the two audit control-plane files are correctly placed on the local side.
  2. §13 is rewritten to describe the asymmetric per-vault model: local-model runs may read both dirs; cloud-model runs cannot read `wiki-local/`; the 7-row per-page precedence table is removed (not relocated).
  3. A concrete enforcement artifact exists — a `settings.json` `deny`-read entry and/or a two-session split runbook — so enforcement is structural, not a remembered rule.
  4. All tooling (`bin/check-privacy.sh`, `bin/lint.sh` privacy checks, `bin/audit-claims.sh` FAITH-04 resolution, CI privacy-leak job) operates on the structural model without behavioral regression.
  5. Decision record `wiki/decisions/dr-YYYY-MM-DD-privacy-asymmetric-two-dir.md` (`trigger_type: schema-update`) is authored, recording the three options and why asymmetric won; §13's resident obligation is confirmed reduced to a one-line structural pointer.

**Plans**: 3 plans

Plans:

**Wave 1**

- [x] 15-00-PLAN.md — Wave 0 RED test scaffold (lib.sh + 9 test_*.sh covering PRIV-01..07)
- [x] 15-01-PLAN.md — Lockstep migration: route+strip wiki/→wiki-cloud/+wiki-local/, rewrite §2/§3/§5/§8/§13, re-key paths, author DR (ONE commit, D-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 15-02-PLAN.md — Enforcement + tooling re-key: D-09 cloud→local link check, check-privacy/privacy_resolve/audit re-key, settings.cloud.json deny-profile + honest fail-direction docs

### Phase 16: Reference Extraction

**Goal**: Every static reference section (page-type definitions, frontmatter schema, provenance syntax, wikilink conventions, privacy model, scaling, tooling) lives in its own standalone markdown file under `schema/reference/` or `docs/reference/`, with the core replaced by routing stubs; §16 is deleted.
**Depends on**: Phase 15 (§13 must be rewritten to asymmetric form before it can be extracted; PRIV-07 feed REF-06)
**Requirements**: REF-01, REF-02, REF-03, REF-04, REF-05, REF-06, REF-07, REF-08, REF-09, REF-10
**Success Criteria** (what must be TRUE):

  1. Every section named in the Extraction Map (§4, §5, §6, §7, §8, §13, §14, §15, §16) is either present as a standalone file at its target path or explicitly dissolved/deleted per the map; no section is silently dropped.
  2. The `IMPORTANT:`-flagged routing table is present at the top of core, correctly mapping every extracted operation/topic to its target file — an agent given only `AGENTS.md` can find any reference material in one hop.
  3. The v1.1.1 uniform-piped-link truth (`[[X]]` resolves by filename/path ONLY; uniform `[[id|Title]]` mandated) is carried verbatim into `schema/reference/wikilinks.md`; the §4/§7 section-ordering dedupe is in place (one merged type-roster, §7 dissolved).
  4. `AGENTS.md` is byte-identical to `CLAUDE.md`; `schema/AGENTS.template.md` mirrors all routing stubs; `bin/sync-claude.sh --check` and `bin/init-wizard.sh --dry-run` both pass.
  5. All CI gates are green (`lint` 3-job, `neutrality`, `setup-parity`; `check-privacy.sh`; `check-neutrality.sh`) over the new `schema/reference/*.md` tree.

**Plans**: 5 plans

Plans:

**Wave 0** *(neutrality gate prerequisite)*

- [x] 16-00-PLAN.md — Add `schema` to check-neutrality.sh PUBLIC_PATHS (critical gap; must precede all extraction commits)

**Wave 1** *(sequential — AGENTS.md is a shared-edit file)*

- [x] 16-01-PLAN.md — Extract §4 page-types + §5 frontmatter to schema/reference/; dissolve §7
- [x] 16-02-PLAN.md — Extract §6 with consumer-split → provenance.md + lint.md seed (decay only)
- [x] 16-03-PLAN.md — Extract §8 wikilinks + §13 privacy to schema/reference/; §14/§15 to docs/reference/; delete §16

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 16-04-PLAN.md — Add routing table; mirror stubs into AGENTS.template.md; write REF-10 DR; run full CI gate suite

### Phase 17: Workflow Extraction

**Goal**: Every procedural workflow (structured operations, ingest, query, lint, reflect, brownfield, release, audit) lives in its own standalone file under `schema/workflows/`, the resident core is verified section-by-section against the inclusion test, and a non-Claude agent can ingest using only the routing table and the extracted workflow file.
**Depends on**: Phase 16 (routing table + `schema/reference/*.md` files must exist before workflow files can reference them; §6 consumer-split decay/staleness portion lands in `workflows/lint.md`)
**Requirements**: WF-01, WF-02, WF-03, WF-04, WF-05, WF-06, WF-07, WF-08, WF-09
**Success Criteria** (what must be TRUE):

  1. Every workflow section named in the Extraction Map (§9, §10 substantive blocks, §11.1–11.7, §12) exists as a standalone file at its target path or is correctly folded/deleted per the map; the §10 pipeline diagram (1 line) and §11.2 write-back-mandatory line remain in core.
  2. The solo structured-op commit-prefix gap (Open Q9) is closed: a defined commit prefix exists for standalone UPDATE/MERGE/SUPERSEDE/ARCHIVE operations.
  3. The 182-line brownfield workflow (§11.5) is present in `schema/workflows/brownfield.md`; the §5 lint "source of truth for CI contracts" framing is preserved in `schema/workflows/lint.md`.
  4. Every resident section in core carries a one-line justification citing its inclusion-test clause (ambient / unscriptable-unacceptable-miss / dispatch); the resulting core is visibly smaller than 1,689 lines with ~145 as an observable output (a tripwire re-audit fires on upward drift, not a gate).
  5. `docs/reference/agent-parity.md` is updated with evidence that a Codex/Cursor agent given only `AGENTS.md` can ingest by following the routing table to `workflows/ingest.md`.

**Plans**: 4 plans (4 waves — sequential core-file editing + routing guard built last)

Plans:

**Wave 1**

- [x] 17-01-PLAN.md — Extract §9 structured-ops → structured-operations.md; fold §10 substantive blocks → ingest.md seed; reduce core §9 (vocab + validate-op + solo-op log + D-01 commit prefix) and §10 (diagram only) (WF-01, WF-02)

**Wave 2** *(blocked on Wave 1 — shares core file)*

- [x] 17-02-PLAN.md — Complete ingest.md (§11.1 procedure); extract §11.2 → query.md; reduce core §11.1/§11.2 to routing dispatch + the one write-back-mandatory line (WF-03, WF-04)

**Wave 3** *(blocked on Wave 2 — shares core file; final extraction)*

- [x] 17-03-PLAN.md — Merge §11.3 lint body INTO lint.md (CI-contract framing preserved); extract §11.4/11.5/11.6/11.7 reflect/brownfield/release/audit; extract §12 → log-format.md; repoint external §N referrers; delete routing scaffold (WF-05, WF-06, WF-07)

**Wave 4** *(blocked on Wave 3 — routing guard goes green only after all §N abolished; gates close)*

- [x] 17-04-PLAN.md — Build the `routing` lint category (bidirectional resolvability guard); WF-08 inclusion-audit baseline + drift info check + section justification; WF-09 agent-parity desk-check + empirical record; schema-update DR; full CI gate suite (WF-08, WF-09)

### Phase 18: Skills Overlay

**Goal**: Thin `.claude/skills/` routers exist for ingest, query, lint, and reflect — each a pointer-only body that invokes the corresponding extracted workflow file — adding zero authoritative content.
**Depends on**: Phase 17 (skill bodies point to `schema/workflows/*.md` files that must exist first)
**Requirements**: SKILL-01, SKILL-02
**Success Criteria** (what must be TRUE):

  1. Four skill files exist under `.claude/skills/` (ingest, query, lint, reflect); each body is at most 3 lines and contains only a pointer to its corresponding `schema/workflows/{op}.md` file.
  2. No behavior is encoded in a skill file that is not already present in the corresponding workflow markdown file; markdown remains the sole authoritative source.

**Plans**: TBD

Plans:

- [ ] 18-01: TBD

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

### Phase 999.4: v1.2 Schema Architecture — Progressive Disclosure Refactor (BACKLOG)

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
| 18. Skills Overlay | v1.2 | 0/TBD | Not started | - |
