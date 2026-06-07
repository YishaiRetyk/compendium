---
id: dr-2026-06-05-workflow-extraction
title: "Workflow Extraction: AGENTS.md §9–§12 to schema/workflows/ + routing guard + inclusion tripwire"
type: decision
status: active
summary: "Extracts §9 (operations vocabulary), §10 (compiler pipeline), §11.1–11.7 (workflows), and §12 (index/log formats) from the AGENTS.md monolith into standalone files under schema/workflows/; abolishes all cross-file §N references in favor of path-refs enforced by a new routing lint category; adds a machine-readable inclusion-audit tripwire."
created_at: 2026-06-07
updated_at: 2026-06-07
sources: []
epistemic_status: sourced
tags:
  - meta
  - schema
domains:
  - wiki-infrastructure
supersedes: null
superseded_by: null
aliases:
  - dr-2026-06-05-workflow-extraction
has_contradictions: false
knowledge_domain: software
trigger_type: schema-update
affected_pages: []
---

# Workflow Extraction: AGENTS.md §9–§12 to schema/workflows/ + routing guard + inclusion tripwire

## TL;DR

Phase 17 continues the reference-extraction trajectory begun in Phase 16 (see [[dr-2026-06-04-reference-extraction|Reference Extraction: AGENTS.md Monolith to schema/reference/ + schema/workflows/]]). It extracts the four remaining workflow-heavy sections — §9 (operations vocabulary and executor model), §10 (compiler pipeline), §11.1–11.7 (all six workflow procedures), and §12 (index/log format specifications) — into standalone files under `schema/workflows/` and `schema/reference/log-format.md`. Three supporting deliverables close the phase: (1) a `routing` lint category that enforces bidirectional path-ref integrity over the schema tree; (2) a machine-readable `<!-- inclusion-audit: N lines @ date -->` baseline header enabling a drift tripwire; and (3) per-section inclusion justification comments in core confirming every resident section earns its ambient load cost.

## Decision

Extract the following sections from the AGENTS.md/CLAUDE.md monolith to standalone authoritative files:

- §9 (Operations Vocabulary + Executor Model) → `schema/workflows/structured-operations.md`
- §10 (Compiler Pipeline) → folded into `schema/workflows/ingest.md` (Claim Granularity Rules + Append-Then-Synthesize policy); the pipeline state-machine diagram is retained inline in core
- §11.1 (Ingest Workflow) → `schema/workflows/ingest.md`
- §11.2 (Query Workflow) → `schema/workflows/query.md`
- §11.3 (Lint Workflow) → `schema/workflows/lint.md` (already seeded in Phase 16; extended)
- §11.4 (Reflect Workflow) → `schema/workflows/reflect.md`
- §11.5 (Brownfield Workflow) → `schema/workflows/brownfield.md`
- §11.6 (Release Workflow) → `schema/workflows/release.md`
- §11.7 (Audit Workflow) → `schema/workflows/audit.md`
- §12 (Index and Log format) → `schema/reference/log-format.md`

Core retains only the two-axis IMPORTANT routing table (one row per extracted file), the solo-op commit-prefix convention summary (ambient, governs all four operations), and navigation stubs. Every cross-file §N reference is abolished and replaced with a path-ref. The routing guard (`bin/lint.sh --category routing`) enforces this mechanically: forward dangling refs → error; inverse orphan workflow files → warning; inclusion-audit drift → info.

Solo-op commit-prefix convention (D-01): the four canonical prefixes (`ingest`, `query`, `lint`, `reflect`) are promoted from inline §3 text to the routing table row for the operations file, removing the need to duplicate the table in core.

## Why

The inclusion test (ambient / unscriptable-AND-unacceptable-miss / dispatch) applied section-by-section finds that §9–§12 all fail the ambient clause: workflow procedures are large, procedural, and JIT-loaded at the start of a specific operation. Loading a 400-line ingest procedure on every turn is not ambient cost — it is waste.

The adopted framing: "AGENTS.md is the router. Each leaf file owns its domain." Cross-file §N references (e.g., "see §11.1") replaced the D-09 convention by accident; they pointed into the monolith's inline position rather than to the authoritative file, undermining the router model. The replacement framing: all cross-file navigation uses explicit path-refs (`schema/workflows/ingest.md`), enforced by the routing lint category so the pattern cannot regress.

The inclusion-audit header (D-12) records the honest post-extraction baseline N rather than a guessed value. The drift tripwire (`+20% or +25 lines`) provides a mechanical signal when core grows without a fresh inclusion-test pass — a self-enforcing hygiene gate.

## Alternatives Considered

**Option A — Standalone `bin/check-routing.sh` script:** Extract the forward/inverse path-ref check into a separate script rather than the routing lint category. Rejected (D-06): a standalone script runs outside the `bin/lint.sh --ci` pipeline and cannot be made a required CI check without additional workflow plumbing. Integrating into lint makes the routing check a first-class CI gate automatically.

**Option B — Extend `bin/sync-claude.sh --check-tree`:** Add path-ref resolution to the sync-claude check since it already validates AGENTS.md ↔ CLAUDE.md byte-equality. Rejected (D-06): sync-claude's scope is narrow (byte-equality gate); widening it conflates two distinct concerns. The lint pipeline is the right home for structural validity checks.

**Option C — Keep §N references with a conversion table in AGENTS.md:** Maintain cross-file §N references alongside a mapping table translating them to file paths. Rejected: two representations of the same navigation target always drift. The routing lint category enforces that only one form exists.

**Option D — LINT_VERSION micro-bump (1.7.0 → 1.7.1):** Treat the routing category as a non-breaking patch. Rejected: adding a new lint category that can cause new CI failures is a MINOR change per semver convention. 1.8.0 is correct.

## Consequences

- AGENTS.md/CLAUDE.md core shrinks to ~287 lines (the post-extraction resident core), down from 1,051 lines at phase start.
- Every cross-file §N reference is eliminated; `bin/lint.sh --category routing` exits 0 over the fully-extracted tree and gates CI via the error severity remap.
- `LINT_VERSION` advances to 1.8.0 (MINOR: new routing category).
- The inclusion-audit header in core (`<!-- inclusion-audit: N lines @ date -->`) is parsed by `bin/lint.sh` to fire a drift info check when core grows more than +20%/+25 lines without a fresh audit pass.
- Agents loading AGENTS.md on a fresh turn read ~287 lines instead of 1,000+; they follow one routing-table hop to the relevant workflow file rather than reading the full monolith.
- `bin/sync-claude.sh --check` (AGENTS.md ≡ CLAUDE.md) remains the byte-equality gate; the inclusion-audit header is mirrored in all three files (AGENTS.md, CLAUDE.md, schema/AGENTS.template.md).
- `schema/workflows/lint.md` was seeded in Phase 16 with the decay table and staleness auto-fix rules; Phase 17 extends it with the full lint procedure (§11.3).

## Affected Pages

No id-bearing wiki pages are affected (`affected_pages: []`). This is an infrastructure/schema-update record. The change reshapes the AGENTS.md/CLAUDE.md spec and creates workflow files under `schema/workflows/` — none of which are id-bearing wiki pages (consistent with the Phase 16 precedent in [[dr-2026-06-04-reference-extraction|Reference Extraction: AGENTS.md Monolith to schema/reference/ + schema/workflows/]]). For navigability, `wiki-cloud/index.md` gains a Decisions entry and `wiki-cloud/log.md` gains a reflect operation entry.

## Sources

Design decisions D-01 through D-15 in `.planning/phases/17-workflow-extraction/17-CONTEXT.md`. Phase 16 extraction DR at `wiki-cloud/decisions/dr-2026-06-04-reference-extraction.md`. Milestone brief at `.planning/milestones/v1.2-MILESTONE-BRIEF.md`.
