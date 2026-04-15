---
phase: 04-query-structured-operations
plan: 03
subsystem: cli
tags: [bash, validation, yaml, python3, pyyaml, operations, privacy]

# Dependency graph
requires:
  - phase: 03-ingestion-provenance-pipeline
    provides: "wiki pages with frontmatter, provenance markers, source registry in wiki/sources/"
  - phase: 01-schema-structure-conventions
    provides: "AGENTS.md section 9 executor model rules, section 5 frontmatter schema, section 13 privacy routing"
provides:
  - "bin/validate-op.sh: deterministic operations validator with 5 mechanical checks and per-operation rules"
  - "Two-layer enforcement: AGENTS.md rules as policy, bash script as deterministic enforcement"
affects: [04-query-structured-operations, 05-lint-reflect-drift]

# Tech tracking
tech-stack:
  added: [python3-inline, pyyaml]
  patterns: [two-layer-enforcement, per-operation-validation-rules, privacy-inheritance-checking]

key-files:
  created:
    - bin/validate-op.sh
  modified: []

key-decisions:
  - "Provenance regex requires # delimiter to distinguish real [prov:id#loc] markers from prose mentions"
  - "Checks cascade: if target missing, later checks SKIP rather than producing misleading errors"
  - "MERGE privacy check warns (not fails) when local_only page is included, since merged result privacy is a downstream concern"

patterns-established:
  - "Per-operation validation rules: each operation type has specific constraints beyond the 5 shared checks"
  - "Privacy inheritance enforcement: validator checks contributing source pages' privacy against target page"
  - "Cascading check pattern: earlier check failures cause later checks to SKIP with clear messaging"

requirements-completed: [SOPS-06]

# Metrics
duration: 4min
completed: 2026-04-12
---

# Phase 04 Plan 03: Operations Validator Summary

**Deterministic bash validator (bin/validate-op.sh) enforcing 5 mechanical checks with per-operation rules, privacy inheritance, and schema enum validation using inline Python3+PyYAML**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-12T20:24:51Z
- **Completed:** 2026-04-12T20:28:27Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Created bin/validate-op.sh (407 lines) with 5 mechanical checks per AGENTS.md section 9
- Per-operation rules: ARCHIVE rejects already-archived, SUPERSEDE rejects already-superseded
- Privacy inheritance check enforces Section 13 rule (strictest source tier wins)
- Validated all 4 operation types (UPDATE, MERGE, SUPERSEDE, ARCHIVE) against real wiki pages
- Verified all failure modes: nonexistent targets, same-page MERGE, invalid ops, missing args

## Task Commits

Each task was committed atomically:

1. **Task 1: Create bin/validate-op.sh with 5 mechanical checks and per-operation rules** - `b31e75b` (feat)
2. **Task 2: Verify validate-op.sh against all 4 operation types and failure modes** - `f7d8570` (fix)

## Files Created/Modified
- `bin/validate-op.sh` - Deterministic operations validator: 5 checks (target exists, frontmatter schema+enums, provenance resolves, privacy inheritance, MERGE distinct), per-operation rules, usage help

## Decisions Made
- Provenance regex requires `#` delimiter after source ID to avoid matching prose text like `[prov:id...]` in narrative paragraphs
- Checks cascade on failure: if check 1 (target exists) fails, checks 2-4 SKIP rather than producing confusing errors on a missing file
- MERGE privacy check emits a WARN (not FAIL) when a local_only page is involved, since the merged result's privacy is set during the merge operation itself

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed provenance regex matching prose references**
- **Found during:** Task 2 (verification)
- **Issue:** Grep pattern `\[prov:([^#\]]+)` matched prose text `[prov:source_id...]` in narrative paragraphs, not just actual provenance markers `[prov:source_id#locator]`
- **Fix:** Changed regex to require `#` after source ID: `\[prov:([^#\]]+)#`
- **Files modified:** bin/validate-op.sh
- **Verification:** wiki/sources/src-2026-04-10-personal-decision-journal.md now passes (was falsely failing)
- **Committed in:** f7d8570 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Bug fix was necessary for correctness against real wiki content. No scope creep.

## Issues Encountered
None beyond the provenance regex fix documented above.

## Known Stubs
None - all functionality is complete and wired.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- bin/validate-op.sh is ready for integration with the structured operations workflow
- Validator can be called by LLM agents before applying any UPDATE/MERGE/SUPERSEDE/ARCHIVE operation
- Future plans can extend with batch validation (D-18) if needed

---
*Phase: 04-query-structured-operations*
*Completed: 2026-04-12*
