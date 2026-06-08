---
phase: 18-skills-overlay
plan: "00"
subsystem: testing
tags: [bash, gitignore, test-harness, tdd-red, skills-overlay]

# Dependency graph
requires:
  - phase: 17-workflow-extraction
    provides: schema/workflows/{ingest,query,lint,reflect}.md files that SKILL.md bodies point to
provides:
  - .gitignore uses .claude/* file-glob form so .claude/skills/ files are trackable
  - tests/phase-18/ RED harness (12 files) that will go GREEN after Plans 01-02
affects:
  - 18-01
  - 18-02

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "tests/phase-18/ follows phase-07/phase-08/phase-09.1 pattern: lib.sh + run.sh + test_*.sh"
    - "cmd && rc=0 || rc=$? capture pattern to avoid set -e aborting before rc=$? on non-zero exit"
    - "trap cleanup EXIT in drift-injection tests to restore working tree on early abort"

key-files:
  created:
    - tests/phase-18/lib.sh
    - tests/phase-18/run.sh
    - tests/phase-18/test_gen_skills_creates_files.sh
    - tests/phase-18/test_gen_skills_idempotent.sh
    - tests/phase-18/test_skill_body_thin.sh
    - tests/phase-18/test_skill_dir_purity.sh
    - tests/phase-18/test_skill_frontmatter.sh
    - tests/phase-18/test_gen_skills_check_clean.sh
    - tests/phase-18/test_gen_skills_check_drift.sh
    - tests/phase-18/test_skills_git_tracked.sh
    - tests/phase-18/test_hook_ordering_skills.sh
    - tests/phase-18/test_neutrality_covers_skills.sh
  modified:
    - .gitignore

key-decisions:
  - ".claude/ directory ignore changed to .claude/* file-glob: directory ignores cannot be negated for descendants in git; only file-glob form allows !.claude/skills/ to work (REVIEWS.md Verified Finding 1)"
  - "Three negation lines required: !.claude/skills/ (directory), !.claude/skills/*/ (subdirs), !.claude/skills/*/SKILL.md (files) — each level must be explicitly un-ignored"
  - "rc capture via cmd && rc=0 || rc=$? pattern for all non-zero-exit commands under set -euo pipefail (REVIEWS.md HIGH fix applied to both check and drift tests)"
  - "trap cleanup EXIT in drift-injection tests prevents stray drifted files in working tree on early abort (REVIEWS.md MEDIUM fix)"
  - "test_skills_git_tracked.sh guards stub dir creation so it only removes the stub if it created it, preserving real generated files after Plan 01"

patterns-established:
  - "Phase-18 test pattern: real-repo tests (no bare-repo fixtures) — lib.sh has only REPO_ROOT + assert_exit_code"
  - "RED state harness: 1/10 tests pass (gitignore fix already green); 9 fail until Plans 01-02"

requirements-completed:
  - SKILL-01
  - SKILL-02

# Metrics
duration: 4min
completed: 2026-06-08
---

# Phase 18 Plan 00: Skills Overlay Bootstrap Summary

**.gitignore un-ignores .claude/skills/ via file-glob form + three negations, and 10-test RED harness established (1/10 green)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-08T17:40:34Z
- **Completed:** 2026-06-08T17:44:51Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Fixed .gitignore to use `.claude/*` file-glob form with three negation lines, making `.claude/skills/` trackable by git (verified: `git check-ignore` exits non-zero)
- Created `tests/phase-18/` with 12 files: lib.sh, run.sh, and 10 test scripts in RED state
- Applied all REVIEWS.md HIGH/MEDIUM fixes: `rc` capture pattern, `trap cleanup EXIT`, word-boundary first-person grep, dir-purity checks any file type (not just .md)

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix .gitignore to un-ignore .claude/skills/** - `0b43772` (chore)
2. **Task 2: Create RED test harness** - `6705d98` (test)

**Plan metadata:** (SUMMARY commit — see below)

## Files Created/Modified

- `.gitignore` - Changed `.claude/` directory ignore to `.claude/*` file-glob + three negation lines for .claude/skills/
- `tests/phase-18/lib.sh` - REPO_ROOT resolver + assert_exit_code helper (phase-15 pattern, dead code stripped)
- `tests/phase-18/run.sh` - Aggregator emitting "PHASE 18 TESTS: N/10" over 10 test scripts
- `tests/phase-18/test_gen_skills_creates_files.sh` - RED: asserts 4 SKILL.md files created
- `tests/phase-18/test_gen_skills_idempotent.sh` - RED: asserts second run is byte-identical (checksum, not git diff)
- `tests/phase-18/test_skill_body_thin.sh` - RED: asserts ≤3 lines, single pointer, zero-behavior
- `tests/phase-18/test_skill_dir_purity.sh` - RED: asserts each skill dir contains ONLY SKILL.md (any file type)
- `tests/phase-18/test_skill_frontmatter.sh` - RED: asserts name + third-person description
- `tests/phase-18/test_gen_skills_check_clean.sh` - RED: asserts --check exits 0 clean, 1 on drift
- `tests/phase-18/test_gen_skills_check_drift.sh` - RED: asserts --check detects drift across all four ops
- `tests/phase-18/test_skills_git_tracked.sh` - GREEN: asserts .claude/skills/ingest/SKILL.md is NOT gitignored
- `tests/phase-18/test_hook_ordering_skills.sh` - RED: asserts gen-skills is between sync-claude and lint in pre-commit
- `tests/phase-18/test_neutrality_covers_skills.sh` - RED: asserts .claude/skills in check-neutrality.sh PUBLIC_PATHS

## Decisions Made

- `.claude/` directory ignore changed to `.claude/*` file-glob: git cannot re-include descendants of an ignored directory, only files/globs at the directory level. The `.claude/*` form treats items inside `.claude/` as individual un-ignorable paths. (REVIEWS.md Verified Finding 1, tested in scratch repo)
- Three negation lines required (`!.claude/skills/`, `!.claude/skills/*/`, `!.claude/skills/*/SKILL.md`) so git descends into each directory level before the final file negation applies.
- `cmd && rc=0 || rc=$?` capture pattern applied throughout all tests that invoke non-zero-exit commands — this is the only correct pattern under `set -euo pipefail`.

## Deviations from Plan

None - plan executed exactly as written. All REVIEWS.md HIGH/MEDIUM fixes from the plan spec were pre-incorporated into the task actions.

## Issues Encountered

None.

## Self-Check

**Created files exist:**
- `.planning/phases/18-skills-overlay/18-00-SUMMARY.md` (this file)
- `tests/phase-18/run.sh` (12 files in directory)
- `.gitignore` with `.claude/*` line

**Commits exist:**
- `0b43772` — chore(18-00): fix .gitignore to un-ignore .claude/skills/
- `6705d98` — test(18-00): create RED test harness for Phase 18 skills overlay

**Verification:**
- `grep -cx '\.claude/\*' .gitignore` returns 1
- `bash tests/phase-18/run.sh` emits "PHASE 18 TESTS: 1/10"
- `bash bin/sync-claude.sh --check` exits 0
- `bash bin/check-neutrality.sh` exits 0

## Self-Check: PASSED

## Next Phase Readiness

Plan 00 complete. Plans 01 and 02 can now proceed:
- Plan 01: implement `bin/gen-skills.sh` + wire pre-commit hook + extend `check-neutrality.sh` (unblocks 9 RED tests)
- Plan 02: author decision record + docs reference page

No blockers.

---
*Phase: 18-skills-overlay*
*Completed: 2026-06-08*
