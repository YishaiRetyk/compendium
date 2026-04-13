---
phase: 05-lint-quality
plan: 02
subsystem: cli-tooling
tags: [lint, python3, pyyaml, staleness, orphan-detection, provenance, yaml-validation]

# Dependency graph
requires:
  - phase: 05-01
    provides: AGENTS.md schema extensions (decay rates, severity tiers, knowledge_domain field, has_contradictions field)
provides:
  - bin/lint.sh CLI helper with structural checks and staleness detection
  - wiki/maintenance/lint-report.md persistent lint report page
  - Finding accumulator pattern (severity|category|path|message)
affects: [05-03, 05-04]

# Tech tracking
tech-stack:
  added: []
  patterns: [bash-wrapper-with-inline-python3, finding-accumulator, environment-variable-passing-to-heredoc]

key-files:
  created:
    - bin/lint.sh
    - wiki/maintenance/lint-report.md
  modified:
    - wiki/log.md

key-decisions:
  - "Single comprehensive python3 block rather than multiple invocations for efficiency"
  - "Environment variables for passing bash args to python3 heredoc (avoids module-path confusion)"
  - "Exit 0 for successful runs regardless of finding count (findings are expected output, not failures)"

patterns-established:
  - "Finding accumulator: severity|category|path|message pipe-delimited format"
  - "Lint report as wiki page with AGENTS.md section 5 compliant frontmatter"
  - "Log entry format: ## [YYYY-MM-DD] lint | wiki health check"

requirements-completed: [LINT-01, LINT-02, LINT-03, LINT-04, STALE-01, STALE-02, CLI-03]

# Metrics
duration: 4min
completed: 2026-04-13
---

# Phase 5 Plan 2: Lint CLI Helper Summary

**bin/lint.sh with YAML validation, provenance checks, orphan detection, cross-ref analysis, domain-based staleness decay, and persistent lint report generation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-13T19:36:30Z
- **Completed:** 2026-04-13T19:40:59Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Created bin/lint.sh (694 lines) following established bash + inline python3 pattern
- Implemented 5 check categories: YAML frontmatter, provenance, orphan, cross-ref, staleness
- Case-insensitive alias-aware wikilink resolution for orphan detection
- Domain-based decay rates with epistemic modifiers and hash override for staleness
- Stale marker auto-fix with idempotency guarantees (--fix flag)
- Persistent lint report at wiki/maintenance/lint-report.md with preserved created_at
- Lint log entry appended to wiki/log.md

## Task Commits

Each task was committed atomically:

1. **Task 1: Create bin/lint.sh scaffold with structural checks** - `f278a95` (feat)
2. **Task 2: Add lint report generation and log entry** - `de779eb` (feat)

## Files Created/Modified
- `bin/lint.sh` - CLI lint helper with 5 check categories, finding accumulator, report generation
- `wiki/maintenance/lint-report.md` - Generated lint report page with AGENTS.md-compliant frontmatter
- `wiki/log.md` - Appended lint log entry

## Decisions Made
- Combined all checks into a single python3 inline block (efficiency: one interpreter invocation)
- Used environment variables (LINT_WIKI_DIR, etc.) to pass bash args to python3 heredoc, avoiding the issue where positional args after heredoc delimiter are treated as python module paths
- Exit code 0 for successful runs even with error-level findings (per plan spec); exit 1 only for process failures
- Existing wiki has 0 findings on first run (all pages have valid frontmatter, provenance, and cross-references)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed python3 heredoc argument passing**
- **Found during:** Task 1 (initial script creation)
- **Issue:** `python3 << 'PYEOF' "$WIKI_DIR"` treats the positional args as a module path, not script args
- **Fix:** Switched to environment variables (export LINT_WIKI_DIR, etc.) read via os.environ in python
- **Files modified:** bin/lint.sh
- **Verification:** Script runs successfully with --dry-run and full mode
- **Committed in:** f278a95 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential fix for script to function. No scope creep.

## Issues Encountered
None beyond the heredoc argument passing issue documented above.

## Known Stubs
None -- all lint checks are fully wired with real data sources.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- bin/lint.sh is ready for 05-03 (contradiction detection) and 05-04 (gap analysis) to extend
- The finding accumulator pattern and report generation handle new categories without modification
- wiki/maintenance/lint-report.md exists as the persistent report target

---
*Phase: 05-lint-quality*
*Completed: 2026-04-13*
