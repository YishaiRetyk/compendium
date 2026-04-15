---
phase: 05-lint-quality
plan: 03
subsystem: lint
tags: [contradiction-detection, gap-analysis, red-links, sparse-coverage, provenance]

# Dependency graph
requires:
  - phase: 05-02
    provides: "bin/lint.sh with YAML, provenance, orphan, crossref, stale checks and finding accumulator"
provides:
  - "Contradiction candidate detection (multi-source section flagging with page-type filtering)"
  - "has_contradictions frontmatter sync (mechanical auto-fix)"
  - "Red link detection (2+ pages or TL;DR/Key Facts threshold)"
  - "Sparse source coverage detection (comparative heuristic with maturity guardrail)"
  - "Investigative question suggestions for each knowledge gap"
affects: [05-04, 05-05, lint-workflow]

# Tech tracking
tech-stack:
  added: []
  patterns: [section-parsing-for-provenance-grouping, lexicographic-pair-normalization, maturity-guardrail-pattern]

key-files:
  created: []
  modified:
    - bin/lint.sh

key-decisions:
  - "Contradiction candidates use section-level provenance grouping with lexicographic pair normalization"
  - "has_contradictions sync runs under both --category contradiction and --category yaml"
  - "Red link resolution reuses orphan detection resolution map (case-insensitive, alias-aware)"
  - "Maturity guardrail threshold: 5+ domains with 3+ having 2+ sources"

patterns-established:
  - "Section parsing: split body at ## and ### headings for per-section analysis"
  - "Pair normalization: sorted tuples prevent A-vs-B / B-vs-A duplicate findings"
  - "Maturity guardrail: comparative heuristics gate on sufficient data before flagging"

requirements-completed: [CNTR-01, CNTR-02, LINT-05, GAP-01, GAP-02, LINT-06]

# Metrics
duration: 2min
completed: 2026-04-13
---

# Phase 05 Plan 03: Contradiction & Gap Detection Summary

**Contradiction candidate detection via multi-source section flagging with page-type filtering, plus red link and sparse coverage gap detection with maturity guardrail**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-13T19:43:19Z
- **Completed:** 2026-04-13T19:45:40Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Contradiction candidate detection flags non-overview/non-comparison page sections with 2+ source_ids, with existing [contradiction:] markers excluded from re-flagging
- has_contradictions frontmatter mechanically synced with body markers, auto-fixable with --fix
- Red link detection flags unresolved wikilinks appearing on 2+ pages or in TL;DR/Key Facts sections
- Sparse source coverage uses knowledge_domain consistently with maturity guardrail preventing false alarms on young wikis
- Each gap finding includes a suggested investigative question

## Task Commits

Each task was committed atomically:

1. **Task 1: Add contradiction candidate detection and has_contradictions sync** - `f2af84e` (feat)
2. **Task 2: Add knowledge gap detection and question suggestions** - `f18bc9b` (feat)

## Files Created/Modified
- `bin/lint.sh` - Added contradiction candidate detection (Check 6), has_contradictions sync (Check 7), red link detection (Check 8), and sparse source coverage (Check 9) functions to the python3 inline block

## Decisions Made
- Contradiction candidates use section-level provenance grouping: body split at ## and ### headings, provenance markers collected per section, pairs normalized lexicographically
- has_contradictions sync runs under both --category contradiction and --category yaml (since it validates frontmatter)
- Red link resolution reuses the case-insensitive alias-aware resolution map from orphan detection (rebuilt if orphan check was skipped)
- Maturity guardrail for sparse coverage: requires 5+ distinct knowledge_domain values with 3+ having 2+ source pages

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all detection logic is fully wired with real data.

## Next Phase Readiness
- bin/lint.sh now has complete detection coverage across all finding categories: yaml, provenance, orphan, crossref, stale, contradiction, gap
- Ready for Plan 04 (lint report integration) or Plan 05 (AGENTS.md lint workflow documentation)

---
*Phase: 05-lint-quality*
*Completed: 2026-04-13*
