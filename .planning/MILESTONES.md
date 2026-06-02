# Milestones

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
