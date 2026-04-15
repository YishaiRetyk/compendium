# Milestones

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
