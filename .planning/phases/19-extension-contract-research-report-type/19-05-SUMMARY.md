---
phase: 19-extension-contract-research-report-type
plan: "05"
subsystem: wiki-schema
tags: [lint, provenance, markdown, table-cell, rstrip, gap-closure, D-08]

# Dependency graph
requires:
  - phase: 19-extension-contract-research-report-type plan 03
    provides: "Initial 103-marker sweep of |direct| → |derived| for research-report sources"
  - phase: 19-extension-contract-research-report-type plan 04
    provides: "D-08 lint gate and LINT_VERSION 1.9.0"
provides:
  - "11 table-cell escaped-pipe \\|direct\\| markers rewritten to \\|derived\\| in two comparison files"
  - "bin/lint.sh D-08 loop now strips trailing backslash from support_type (table-cell normalization)"
  - "bin/audit-claims.sh applies same rstrip normalization per re-copy contract"
  - "Decision record DR count corrected from 103 to 114 (103 prose + 11 table-cell)"
  - "D-08 is no longer vacuously passing for table-cell markers — regression test confirms gate fires"
affects:
  - "Phase 20 (PDF ingestion) — inherits corrected lint gate"
  - "Phase 21 (video ingestion) — inherits corrected lint gate"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "rstrip('\\\\') normalization at PROV_RE extraction point to handle markdown table-cell pipe escaping"
    - "Line-by-line grep pattern preferred over multiline regex for escaped-pipe marker detection"

key-files:
  created: []
  modified:
    - wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md
    - wiki-cloud/comparisons/claude-code-orchestration-frameworks.md
    - wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md
    - wiki-cloud/log.md
    - bin/lint.sh
    - bin/audit-claims.sh

key-decisions:
  - "rstrip('\\\\') applied at extraction point (not inside PROV_RE) to avoid ripple effects on other callers"
  - "Placeholder <report> in DR RPT-03 bullet changed to descriptive prose to avoid validate-op.sh false positive"
  - "D-08 regression test uses synthetic tmpdir wiki tree to avoid polluting real wiki during test"

patterns-established:
  - "Table-cell provenance markers are serialized as [prov:id#loc\\|type\\|date] on disk — any support_type comparison must rstrip('\\\\') first"
  - "Verify escaped-pipe patterns using str.count or line-by-line contains, not raw multiline regex"

requirements-completed:
  - RPT-03
  - RPT-06

# Metrics
duration: 25min
completed: 2026-06-11
---

# Phase 19 Plan 05: Gap Closure Summary

**Table-cell escaped-pipe blind spot closed: 11 \\|direct\\| markers corrected, D-08 gate patched with rstrip normalization, and decision record count corrected from 103 to 114.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-11T22:20:00Z
- **Completed:** 2026-06-11T22:44:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Fixed 10 table-cell escaped-pipe `\|direct\|` markers in `ocr-pipeline-vs-vlm-ingestion.md` (5 comparison rows, 2 markers each)
- Fixed 1 table-cell escaped-pipe `\|direct\|` marker in `claude-code-orchestration-frameworks.md` (Origin row)
- Patched `bin/lint.sh` D-08 loop to add `support_type.rstrip('\\')` normalization immediately after PROV_RE findall loop
- Patched `bin/audit-claims.sh` worklist builder with same rstrip normalization per re-copy contract
- Corrected decision record pre-sweep count from 103 to 114 (103 prose + 11 table-cell); added gap-closure note
- D-08 regression test confirmed: injecting a table-cell `\|direct\|` marker now fires "Epistemic laundering" error
- Full lint on real wiki: 0 errors after all changes

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite 11 table-cell markers and correct decision record count** - `0033b0d` (lint)
2. **Task 2: Patch PROV_RE normalization in lint.sh and audit-claims.sh** - `a2a98d8` (lint)

## Files Created/Modified

- `wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md` - 10 table-cell markers rewritten direct→derived; updated_at bumped to 2026-06-11
- `wiki-cloud/comparisons/claude-code-orchestration-frameworks.md` - 1 table-cell marker rewritten direct→derived; updated_at bumped to 2026-06-11
- `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` - Count corrected 103→114; gap-closure prose added; RPT-03 example changed from code span to prose; updated_at bumped
- `wiki-cloud/log.md` - 3 UPDATE log entries appended (one per changed page)
- `bin/lint.sh` - `support_type.rstrip('\\')` added at line 1143 inside PROV_RE findall loop (D-08 comparison)
- `bin/audit-claims.sh` - `(support_type or '').rstrip('\\')` added at line 815 after `support_type = mprov.group(3)`

## Decisions Made

- `rstrip('\\')` applied at the extraction point (immediately after PROV_RE group capture) rather than modifying PROV_RE itself — avoids ripple effects on callers that use raw captured groups for other purposes (e.g., locator resolver in audit-claims.sh that strips the `#` prefix separately)
- Changed `<report>` placeholder in DR RPT-03 bullet to descriptive prose to prevent `validate-op.sh` from misidentifying it as an unresolvable provenance source reference
- Used synthetic tmpdir wiki tree for D-08 regression test rather than modifying the real wiki temporarily

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Fixed validate-op.sh false positive on DR placeholder**
- **Found during:** Task 1 (validate-op.sh pre-flight for decision record)
- **Issue:** The decision record body contained `` `[prov:<report>#...|direct|...]` `` inside backticks as a code-span example. `validate-op.sh check_provenance` uses grep which matches even inside backtick code spans, extracting `<report>` as a source ID and failing because `wiki-cloud/sources/<report>.md` doesn't exist.
- **Fix:** Changed the example code span on RPT-03 bullet from `` `[prov:<report>#...|direct|...]` `` to descriptive prose: "a `|direct|` provenance marker on a research-report source is an error"
- **Files modified:** `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md`
- **Verification:** `bin/validate-op.sh UPDATE wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` exits 0
- **Committed in:** `0033b0d` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — missing critical functionality: validate-op.sh pre-flight must pass before editing)
**Impact on plan:** Minimal change — altered a code-span example to prose in the decision record. Semantically equivalent, and actually clearer.

## Issues Encountered

- The plan's Python verification regex `r'\[prov:[^\]]*\\\|direct\\\|[^\]]*\]'` matches across newlines (via `[^\]]*`) causing false positives when run as a single findall on the full file body. Used `str.contains` with `chr(92)+'|direct'+chr(92)+'|'` for accurate verification instead. This was a verification-script issue only — the actual file edits were correct.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 19 gap-closure complete: all RPT-03 and RPT-06 requirements are now fully closed
- D-08 lint gate is non-vacuous: table-cell escaped-pipe markers are correctly detected
- Full lint exits 0 with 0 errors on the real wiki
- Phases 20 (PDF) and 21 (video) inherit the corrected lint gate and can proceed without risk of the same blind spot

## Known Stubs

None — all changes are complete corrections; no placeholder data or stub patterns introduced.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced.

## Self-Check

Files exist:
- `wiki-cloud/comparisons/ocr-pipeline-vs-vlm-ingestion.md` — modified
- `wiki-cloud/comparisons/claude-code-orchestration-frameworks.md` — modified
- `wiki-cloud/decisions/dr-2026-06-10-source-type-contract.md` — modified
- `bin/lint.sh` — modified
- `bin/audit-claims.sh` — modified

Commits exist:
- `0033b0d` — Task 1: rewrite 11 table-cell markers + correct DR count
- `a2a98d8` — Task 2: patch PROV_RE normalization

## Self-Check: PASSED

---
*Phase: 19-extension-contract-research-report-type*
*Completed: 2026-06-11*
