---
phase: 19-extension-contract-research-report-type
plan: "01"
subsystem: schema-reference
tags:
  - schema
  - source-types
  - extension-contract
  - research-report
dependency_graph:
  requires: []
  provides:
    - schema/reference/source-types.md (5-dimension extension contract, retro-fit table, evaluated candidates registry)
    - research-report source_type enum value in frontmatter.md
    - Pass 0 research-report classification in ingest.md
    - AGENTS.md/CLAUDE.md routing row for source-types.md
  affects:
    - schema/reference/frontmatter.md (source_type enum extended)
    - schema/workflows/ingest.md (Pass 0 step + granularity table)
    - AGENTS.md + CLAUDE.md (routing table)
tech_stack:
  added: []
  patterns:
    - provenance.md header pattern (agent-authoritative blockquote)
    - See Also footer pattern
    - routing table row format (ROUTING_ROW_RE-compatible)
    - graceful-degradation note pattern
key_files:
  created:
    - schema/reference/source-types.md
  modified:
    - AGENTS.md
    - CLAUDE.md
    - schema/reference/frontmatter.md
    - schema/workflows/ingest.md
decisions:
  - 5-dimension contract (acquisition/locator/extraction/drift/epistemic) is the formal evaluation recipe for all new source type candidates
  - Decision rule: new source_type justified only if it changes at least one dimension; otherwise document as sub-case
  - research-report is the worked secondary instance demonstrating the contract
  - All research-report claims use support_type derived (never direct); lint enforces this as error (Phase 19-02)
  - Model C hybrid promotion path: report is primary registry, citations promotable on demand
metrics:
  duration: "3 minutes"
  completed_date: "2026-06-10"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 4
---

# Phase 19 Plan 01: Source-type Extension Contract — Summary

5-dimension source-type extension contract established in new `schema/reference/source-types.md`, wired into AGENTS.md/CLAUDE.md routing table, frontmatter.md enum, and ingest.md Pass 0 + granularity table.

## What Was Built

**Task 1 — schema/reference/source-types.md (new, 110 lines)**

Created the authoritative source-type extension contract. The file contains:
- **Section 1: 5 Dimensions** — acquisition, locator, extraction granularity, drift, epistemic default; table defining each dimension and why it matters.
- **Section 2: Primary vs Secondary Axis** — decision rule: a new `source_type` is justified only if it changes at least one dimension relative to all existing types; otherwise it is a sub-case.
- **Section 3: Retro-fit Table** — all 7 source types (6 existing + research-report) mapped across the 5 dimensions.
- **Section 4: Evaluated Candidates Registry** — pre-populated with pdf (provisional sub-case of article/paper), video (provisional sub-case of transcript), and repository (pending). Phases 20 and 21 finalize their rows.
- **Section 5: research-report Worked Secondary Instance** — full convention: classification rule, provenance (derived-only, #r<n> locator), citation registry format (r<n>:: Dataview keys), epistemic default (mixed/tentative), Model C promotion path, audit priority, anti-laundering rationale.
- **Section 6: Ingest Checklist for research-report** — 5-step ordered checklist.
- **See Also footer** — links to AGENTS.md, frontmatter.md, provenance.md, ingest.md, audit.md.

**Task 2 — Four targeted edits wiring the contract**

- **AGENTS.md**: New routing table row `> | Adding/evaluating a new source type | \`schema/reference/source-types.md\` |` inserted after the provenance.md row.
- **CLAUDE.md**: Byte-equal sync via `bin/sync-claude.sh` — confirmed with `--check`.
- **schema/reference/frontmatter.md**: `source_type` enum updated to `article|paper|transcript|journal|data|image|research-report`; pointer sentence added after the YAML block: "Semantics for each `source_type` value and the extension decision rule → `schema/reference/source-types.md`."
- **schema/workflows/ingest.md**: Pass 0 step extended to include `research-report` with secondary-source note and pointer to source-types.md; granularity table has new `research-report` row; informal type labels (`report, technical doc` and `book-chapter, essay`) reconciled to parent enum types via parenthetical `— sub-cases of \`article\` or \`paper\`` mappings (D-03).

## Verification Results

All CI gates passed:
- `bin/lint.sh --category routing` → 0 errors, 0 warnings, 0 info (source-types.md routing row resolves correctly)
- `bin/sync-claude.sh --check` → OK: AGENTS.md == CLAUDE.md
- `bin/check-neutrality.sh` → exit 0 (no real vault slugs in template-public files)

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | b6c0796 | feat(19-01): create schema/reference/source-types.md — 5-dimension extension contract |
| 2 | 0825e08 | feat(19-01): wire source-types.md into routing table, frontmatter enum, and ingest.md Pass 0 |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. The evaluated candidates registry rows for pdf and video are intentionally marked provisional — they are pre-evaluations, not stubs blocking this plan's goal. The `(Phase 20)` and `(Phase 21)` convention-doc references are accurate forward pointers, documented as such.

## Threat Flags

None. The new `schema/reference/source-types.md` is a template-public schema reference file with no network endpoints, auth paths, or trust-boundary-crossing content. All examples use abstract placeholders verified by `bin/check-neutrality.sh`.

## Self-Check: PASSED

- `schema/reference/source-types.md` exists: FOUND
- Commit b6c0796 exists: FOUND
- Commit 0825e08 exists: FOUND
- `research-report` in schema/reference/source-types.md: 10+ matches
- `research-report` in schema/reference/frontmatter.md: 1 match (enum line)
- `research-report` in schema/workflows/ingest.md: 3 matches (Pass 0 + sub-bullet + granularity table)
- `source-types.md` in AGENTS.md: 1 match (routing table row)
- `source-types.md` in CLAUDE.md: 1 match (byte-equal sync)
- `wc -l schema/reference/source-types.md`: 110 lines (>80 requirement met)
