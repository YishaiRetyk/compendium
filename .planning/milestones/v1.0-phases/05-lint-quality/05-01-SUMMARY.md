---
phase: 05-lint-quality
plan: 01
subsystem: schema
tags: [decay-rates, contradictions, severity-tiers, frontmatter, staleness]

# Dependency graph
requires:
  - phase: 03-ingestion-provenance-pipeline
    provides: "Provenance syntax, epistemic markers, source registry"
  - phase: 04-query-structured-operations
    provides: "Compilation status fields, structured operations"
provides:
  - "Domain-based decay rate table in AGENTS.md section 6"
  - "Contradiction inline syntax [contradiction:src_a vs src_b]"
  - "Severity tiers (error/warning/info) in AGENTS.md section 11.3"
  - "Auto-fix boundary documentation"
  - "has_contradictions and knowledge_domain frontmatter fields"
  - "All wiki pages backfilled with knowledge_domain and has_contradictions"
affects: [05-02, 05-03, 05-04, 05-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "knowledge_domain (staleness bucket) vs domains (topical classification) separation"
    - "Layered staleness: domain base -> epistemic modifier -> hash override"
    - "Mechanical auto-fix boundary: deterministic + reversible = auto-fix"

key-files:
  created: []
  modified:
    - AGENTS.md
    - wiki/concepts/cognitive-biases.md
    - wiki/concepts/loss-aversion.md
    - wiki/concepts/prospect-theory.md
    - wiki/entities/daniel-kahneman.md
    - wiki/comparisons/system-1-vs-system-2.md
    - wiki/overviews/decision-making.md
    - wiki/overviews/personal-decision-patterns.md
    - wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md
    - wiki/sources/src-2026-04-10-kahneman-prospect-theory.md
    - wiki/sources/src-2026-04-10-personal-decision-journal.md

key-decisions:
  - "knowledge_domain is the staleness policy bucket, distinct from domains which is topical classification"
  - "Contradiction detection excludes comparison and overview page types (inherently multi-source)"
  - "Auto-fix limited to stale marker updates and has_contradictions sync; contradictions, gaps, orphans are report-only"

patterns-established:
  - "knowledge_domain field on every wiki page maps to Section 6 decay rate table"
  - "Contradiction inline syntax: [contradiction:source_a#locator vs source_b#locator]"
  - "Severity tiers: error (must fix), warning (should fix), info (nice to know)"

requirements-completed: [STALE-03, STALE-04, CNTR-03, LINT-07]

# Metrics
duration: 3min
completed: 2026-04-13
---

# Phase 05 Plan 01: Schema Extensions Summary

**Domain-based decay rate table, contradiction inline syntax, severity tiers, auto-fix boundary, and knowledge_domain/has_contradictions frontmatter fields across AGENTS.md and all wiki pages**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-13T19:30:27Z
- **Completed:** 2026-04-13T19:34:03Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Extended AGENTS.md section 5 with has_contradictions and knowledge_domain field definitions, including explicit distinction from domains field
- Extended AGENTS.md section 6 with domain-based decay rate table (5 domains), epistemic modifiers (4 statuses), hash override rule, date fallback chain, contradiction inline syntax, and staleness auto-fix rules
- Replaced AGENTS.md section 11.3 skeleton with fully operational 13-step lint workflow including severity tiers, auto-fix boundary, contradiction candidate detection (excluding comparison/overview pages), has_contradictions sync, knowledge gap heuristics, and source coverage maturity guardrail
- Backfilled knowledge_domain and has_contradictions on all 10 existing wiki pages with correct domain assignments

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend AGENTS.md sections 5, 6, and 11.3** - `e08e38e` (feat)
2. **Task 2: Backfill knowledge_domain and has_contradictions** - `d5c5ff2` (feat)

## Files Created/Modified
- `AGENTS.md` - Extended sections 5, 6, and 11.3 with all Phase 5 schema definitions
- `wiki/concepts/cognitive-biases.md` - Added knowledge_domain: science, has_contradictions: false
- `wiki/concepts/loss-aversion.md` - Added knowledge_domain: science, has_contradictions: false
- `wiki/concepts/prospect-theory.md` - Added knowledge_domain: science, has_contradictions: false
- `wiki/entities/daniel-kahneman.md` - Added knowledge_domain: biography, has_contradictions: false
- `wiki/comparisons/system-1-vs-system-2.md` - Added knowledge_domain: science, has_contradictions: false
- `wiki/overviews/decision-making.md` - Added knowledge_domain: science, has_contradictions: false
- `wiki/overviews/personal-decision-patterns.md` - Added knowledge_domain: personal-goals, has_contradictions: false
- `wiki/sources/src-2026-04-09-thinking-fast-and-slow-part1.md` - Added knowledge_domain: science, has_contradictions: false
- `wiki/sources/src-2026-04-10-kahneman-prospect-theory.md` - Added knowledge_domain: science, has_contradictions: false
- `wiki/sources/src-2026-04-10-personal-decision-journal.md` - Added knowledge_domain: personal-goals, has_contradictions: false

## Decisions Made
- knowledge_domain is the staleness policy bucket (how fast content goes stale), distinct from domains which is topical classification (what the page is about)
- Contradiction candidate detection in step 7 excludes comparison and overview page types since they are inherently multi-source by design
- Auto-fix boundary is strictly mechanical: stale marker updates and has_contradictions sync only; contradictions, knowledge gaps, orphan pages, and missing cross-references are report-only

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all schema definitions are complete and all wiki pages have been backfilled.

## Next Phase Readiness
- AGENTS.md schema is complete and authoritative for lint rule implementation
- All wiki pages have knowledge_domain and has_contradictions fields ready for lint validation
- Plans 02-05 can reference Section 5, 6, and 11.3 definitions as the source of truth

---
*Phase: 05-lint-quality*
*Completed: 2026-04-13*

## Self-Check: PASSED
