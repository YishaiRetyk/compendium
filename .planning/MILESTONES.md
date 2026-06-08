# Milestones

## v1.2 Schema Architecture (Shipped: 2026-06-08)

**Phases completed:** 4 phases (15–18), 15 plans
**Requirements:** 28/28 complete (PRIV-01..07, REF-01..10, WF-01..09, SKILL-01..02)
**Timeline:** 2026-06-04 → 2026-06-08 (~4 days)

**Delivered:** The project's own §7 progressive-disclosure principle applied to its own spec — the always-loaded `AGENTS.md`/`CLAUDE.md` monolith (1,689 lines) reduced to a ~287-line resident core, the rest extracted into a markdown-authoritative `schema/reference/*.md` + `schema/workflows/*.md` tree, with privacy re-architected as a structural harness permission and a thin drift-gated skills overlay added.

**Key accomplishments:**

- **Privacy Architecture (Phase 15, `PRIV-01..07`):** Replaced per-page §13 `privacy` frontmatter with the asymmetric two-directory model — `wiki-cloud/` (cloud-safe) and `wiki-local/` (local-only), one-way permeability enforced as a harness `deny`-read permission rather than a resident agent rule. One security-atomic migration commit re-keyed every privacy predicate so no intermediate had a dead guard; a TDD harness armed the Nyquist gate before any structural change. Privacy thereby dropped out of the always-loaded safety core.
- **Reference Extraction (Phase 16, `REF-01..10`):** §4/5/6/7/8/13 → `schema/reference/*.md`; §14/15 → `docs/reference/*.md`; §16 deleted; the `IMPORTANT:`-flagged routing table added to the core; stubs mirrored into `schema/AGENTS.template.md`; byte-equality and neutrality gates held.
- **Workflow Extraction (Phase 17, `WF-01..09`):** §9/10/11.1–11.7/12 → `schema/workflows/*.md` (including the previously-missed 182-line brownfield workflow); resident core shrank 1,689→287 lines with per-section inclusion justifications; a new `routing` lint category (LINT_VERSION 1.8.0) gates forward dangling-ref and inverse orphan-file integrity over the live tree.
- **Skills Overlay (Phase 18, `SKILL-01..02`):** Four thin pointer-only `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` routers generated and drift-gated by `bin/gen-skills.sh --check` (regenerate-diff + 6 structural assertions), wired into the pre-commit hook and a hard-fail CI `skills-check` job; zero authoritative content (markdown stays the SOT). TDD harness `tests/phase-18/` 10/10 green; advisory code-review warnings on generator cwd-resolution fixed in `18-REVIEW-FIX.md`.

**Known deferred items at close:** 5 (see STATE.md Deferred Items) — all pre-existing acknowledged deferrals carried from prior closes: the `phase-14-lint-mask-fence-edge-cases` todo, and 4 audit-flagged quick tasks (`260415-fvc`, `260415-gzu`, `260501-g5n`, `260602-d6a`) that are actually complete (false-positive from an unparseable status field). Plus Phase D Wizard fold-in (`WIZ`) deferred from v1.2 scope.

---

## v1.1.1 Graph Integrity (Shipped: 2026-06-04)

**Phases completed:** 1 phase (Phase 14: Graph Link Resolution), 3 plans
**Requirements:** 10/10 LINK requirements complete (`bin/requirements-sync.sh --require-complete` exits 0)
**Timeline:** 2026-06-02 → 2026-06-03 (~2 days, 75 commits since v1.1)

**Delivered:** A connected Obsidian graph — the schema now tells the truth about link resolution and the data is remediated to match.

**Key accomplishments:**

- **Premise correction (the headline):** The original Phase 14 self-alias approach was executed, then proven false at the LINK-10 human-verify gate — Obsidian resolves `[[X]]` by **filename/path ONLY**, never via `title` or `aliases` (confirmed for v1.12.7). Phase 14 was re-planned around the correct approach. Wrong-premise artifacts quarantined under `14-graph-link-resolution/_superseded-premise/`.
- **Convention + schema (LINK-01..03):** `CLAUDE.md`/`AGENTS.md` §3/§5/§8/§15/§16 corrected to mandate **uniform piped links** `[[id|Title]]` (target = page `id` = filename, always resolves; display = canonical title); the false self-alias invariant removed (`aliases` reverts to optional); superseding decision record `dr-2026-06-03-uniform-piped-links` supersedes the wrong-premise DR; `schema/AGENTS.template.md` + 12 templates mirrored; AGENTS.md kept byte-identical to CLAUDE.md.
- **Lint enforcement (LINK-04..06):** `bin/lint.sh` `linkres` re-pointed to validate intra-wiki link *targets* (bare `[[X]]` and unknown-`id` targets are errors; knowledge-gap red links stay `gap`/info); `--fix` rewrites bare → piped for unique matches; `orphan` reconciled to resolve by `id`/filename only; shared `mask_markdown()` helper (LINT_VERSION 1.6.0); regression tests added.
- **Data remediation (LINK-07..10):** All `wiki/` + `examples/` body links rewritten to piped form; variant reconciliation dissolved (plural/parens/casing live in cosmetic display text); orphan count 19→0; `domain-driven-design` now has 18 inbound links; connected graph human-verified in Obsidian.

**Known deferred items (acknowledged at close):**

- 1 pending todo `phase-14-lint-mask-fence-edge-cases` — WR-02/03 fence-edge-case hardening for lint markdown masking; in `.planning/todos/pending/`, promote via `/gsd-quick`. Recorded in STATE.md Deferred Items.
- 4 audit-flagged quick tasks (`260415-fvc`, `260415-gzu`, `260501-g5n`, `260602-d6a`) are all complete (each has a SUMMARY.md; flagged only by an unparseable status field) — no action.
- Backlog Phases 999.3–999.6 and v1.2-deferred items carry forward from the v1.1 close (see below).

**Archives:**

- `milestones/v1.1.1-ROADMAP.md`
- `milestones/v1.1.1-REQUIREMENTS.md`

---

## v1.1 Shareability (Shipped: 2026-06-02)

**Phases completed:** 15 phase directories (Phases 7–13.2), 52 plans
**Requirements:** 97/97 v1.1 requirements complete (0 drift, 0 incomplete — `bin/requirements-sync.sh --strict --require-complete` exits 0)
**Timeline:** 2026-04-15 → 2026-06-02 (~48 days, 382 commits)

**Key accomplishments:**

- **Neutral template foundation (Phase 7):** Public orphan-branch starter template (`YishaiRetyk/compendium`) with the Kahneman cluster relocated to `examples/`, a `bin/check-neutrality.sh` denylist CI gate over template-public paths, and the `bin/requirements-sync.sh` mechanical ledger check. Four-track `/docs/` (quickstart, guided, manual, reference).
- **Two-track setup + collaborative curation (Phases 8–9):** `bin/init-wizard.sh` guided wizard plus a byte-equivalent manual track (canonical-fixture parity enforced in CI); git-based PR curation workflow with a `log.md` contributor field, and a three-job CI gate (`bin/lint.sh --ci --format json` severity remap, privacy-leak guard, `--strict` ratchet).
- **Brownfield onboarding (Phases 10–11):** `bin/brownfield.sh scan|bootstrap|suggest|review-typing|verify` with the `bootstrap_stage` lifecycle sentinel, ruamel.yaml round-trip, four canonical migration script classes (apply vs advisory), and a 5-gate `verify --promote`. Strict mechanical-vs-judgment boundary; `--apply` deferred to v1.2.
- **Complementary-systems boundary (Phases 12, 12.1):** Decision record + `docs/reference/three-layer-model.md` defining compendium as durable wiki-memory inside a multi-system stack (task/working-memory/wiki layers, capture/clarify/organize/review routing, explicit anti-features); NEUT-08 personal-term denylist curation closed.
- **Trust + closure semantics (Phases 12.2, 13):** Local pre-commit write gate blocking zero-provenance new synthesized pages (`bin/lint.sh --strict --staged`); `bin/audit-claims.sh` claim-faithfulness sampler (supports/weak/contradicts/insufficient verdicts, review-only, fail-closed privacy chokepoint).
- **Docs finalization + closure gate (Phases 13.1, 13.2):** `/docs/reference/` fill-out + minimal Obsidian starter; the v1.1 closure gate re-ran the Obsidian render (Dataview counts 3/2/2/2/5), accepted the Codex agent-parity column as blocked-on-host-runtime, audited write-back, confirmed docs consistency + zero scope-leak, and drove `requirements-sync --strict --require-complete` to exit 0 milestone-wide.

**Known deferred items (acknowledged at close):**

- 1 pending todo `a1-lexical-dedup-lint-category` — near-duplicate page detection (`duplicate` lint category); explicitly `blocked_on: Phase 13.2`, promote via `/gsd-quick` post-v1.1. Recorded in STATE.md Deferred Items.
- Backlog Phases 999.3–999.6 (template placeholder system, v1.2 schema progressive-disclosure refactor, external source drift detection, observed GTD review patterns) remain in `.planning/ROADMAP.md` Backlog.
- v1.2-deferred from PROJECT.md: Obsidian plugin distribution, one-command installer, hosted docs site, brownfield `--apply` mode.
- Pre-existing tech debt (per the superseded 2026-04-30 milestone audit): 3 unsummarized pre-Phase-7 Kahneman raw sources (DRFT-01 warning), brownfield WR-*/IN-* nits, Phase 11 human-UAT visual items, lint `[[Page Title]]` red-link false-positives. All non-blocking.

**Archives:**

- `milestones/v1.1-ROADMAP.md`
- `milestones/v1.1-REQUIREMENTS.md`
- `milestones/v1.1-MILESTONE-AUDIT.md` (superseded 2026-04-30 snapshot; authoritative closure is the Phase 13.2 gate)

---

## v1.0 LLM Wiki Compiler MVP (Shipped: 2026-04-15)

**Phases completed:** 6 phases, 24 plans, 44 tasks
**Requirements:** 95/95 v1 requirements complete
**Timeline:** 2026-04-06 → 2026-04-15 (9 days)

**Key accomplishments:**

- **Phase 1 — Schema & Structure:** Complete 1,178-line AGENTS.md (16 sections) with structured operations vocabulary, four prescriptive workflows, fail-closed privacy routing, progressive disclosure conventions, and provisional scaling boundaries. All 19 Phase 1 requirements pass automated validation.
- **Phase 2 — Page Types & Navigation:** Five copy-paste templates (entity, concept, source, comparison, overview) with FORBIDDEN PATTERNS guardrails; five connected example pages forming a Kahneman/cognitive-biases cluster; populated index.md and parseable log.md; section 6 epistemic inline syntax.
- **Phase 3 — Ingestion & Provenance:** `bin/ingest.sh` with UTC-dated source directories, SHA-256 hashing, and collision handling. Two end-to-end validation ingests (article + journal entry) producing 20+ atomic provenance markers, clean privacy separation via dedicated local_only pages, and diff-driven page-creation judgment.
- **Phase 4 — Query & Structured Operations:** `bin/search.sh` dual-mode (index lookup + full-text + query prompt scaffolding); `bin/validate-op.sh` deterministic validator enforcing 5 mechanical checks + per-operation preconditions; compilation_status state machine; section 11.2 rewritten with write-back rules and delta compilation; three query scenarios executed end-to-end.
- **Phase 5 — Lint & Quality:** `bin/lint.sh` with YAML validation, provenance checks, orphan/cross-ref detection, domain-based staleness decay, contradiction candidate detection (section-level multi-source flagging), red-link and sparse-coverage gap detection. Zero-error wiki validates phases 1–4 schema quality.
- **Phase 6 — Reflection & Drift Detection:** Decision record page type (template, directory, sections 4.6/5/12, inaugural bootstrapping record); drift detection integrated into lint (5 checks); three-tier reflect workflow with checkpoint state and skip criteria to prevent record inflation.

**Known Tech Debt (from audit):**

- REQUIREMENTS.md bookkeeping: 9 Pending flags on QURY-01/04/05 and SOPS-01..06 flipped during completion (quick-260415-gzu); 15 requirements verified but not echoed in SUMMARY frontmatter.
- CMPL-06/07 and SOPS-06 absent from SUMMARY frontmatter (covered by Plan 03-01 and Plan 04-03).
- Article validation ingest produced 20 provenance markers vs 8–15 target (accepted during human semantic review).
- Phase 4: deferred human verification of genuine write-back scenario and Obsidian vault link/Dataview rendering.
- Phases 01/04/05/06 have partial Nyquist coverage (02/03 compliant); no substantive gaps.

**Archives:**

- `milestones/v1.0-ROADMAP.md`
- `milestones/v1.0-REQUIREMENTS.md`
- `milestones/v1.0-MILESTONE-AUDIT.md`

---
