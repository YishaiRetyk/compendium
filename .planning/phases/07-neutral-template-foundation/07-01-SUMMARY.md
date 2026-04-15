---
phase: 07-neutral-template-foundation
plan: 01
subsystem: testing
tags: [bash, python3, traceability, verification, debt-03, wave-0, tdd]

requires:
  - phase: 06-reflection-drift-detection
    provides: Prior phase precedent for VERIFICATION.md truth file pattern (06-VERIFICATION.md)
provides:
  - bin/requirements-sync.sh (DEBT-03 mechanical traceability check)
  - tests/phase-07/run.sh Wave 0 test aggregator
  - tests/phase-07/test_requirements_sync.sh with 6 behavior tests
  - Fixture layout for REQUIREMENTS vs VERIFICATION drift testing
affects:
  - 07-02 through 07-05 (all extend Wave 0 harness tests/phase-07/run.sh)
  - All future phases (DEBT-03 closes traceability drift gap mechanically)

tech-stack:
  added: []
  patterns:
    - Bash flag parsing + python3 inline heredoc (matches bin/lint.sh convention)
    - Exit code matrix 0/1/2 (ok/script-failure/strict-findings)
    - Advisory-default with --strict gate at milestone close
    - --root DIR override for fixture-driven testing of file-scanning scripts

key-files:
  created:
    - bin/requirements-sync.sh
    - tests/phase-07/run.sh
    - tests/phase-07/test_requirements_sync.sh
    - tests/phase-07/fixtures/requirements-sync/REQUIREMENTS.md
    - tests/phase-07/fixtures/requirements-sync/07-VERIFICATION.md
    - tests/phase-07/fixtures/requirements-sync/07-drift-VERIFICATION.md
  modified: []

key-decisions:
  - "Markdown output adds Note column (5th col) so tests can grep human-readable reasons ('Phase not yet run', 'DRIFT') without parsing JSON"
  - "Lexicographic last-write-wins for duplicate REQ-IDs across VERIFICATION files; WARN emitted per duplicate to stderr (REVIEWS.md medium finding)"
  - "Missing VERIFICATION.md for a REQ-ID is NOT drift — 'OK - Phase not yet run' note, drift=false (matches research D-15 advisory semantics)"
  - "Temp-file sentinel pattern used to pass DRIFT_COUNT from python heredoc back to bash for --strict exit code decision"

patterns-established:
  - "Wave 0 harness shape: tests/phase-07/run.sh iterates test_*.sh files; each test file runs its own behavior functions and tallies PASS/FAIL — later plans extend by adding more test_*.sh siblings"
  - "Fixture-driven bash script testing: scripts accept --root DIR to swap real .planning/ for a mktemp staging dir"
  - "VERIFICATION.md parser tolerance: strips '- [x]', emoji prefixes, '**' bold before extracting 'REQ-ID: status'"

requirements-completed: [DEBT-03]

duration: ~6min
completed: 2026-04-15
---

# Phase 07 Plan 01: Wave 0 Harness + Requirements-Sync Summary

**bin/requirements-sync.sh mechanically detects REQUIREMENTS.md vs VERIFICATION.md drift (advisory default, --strict gate at milestone close); Wave 0 test aggregator tests/phase-07/run.sh established for all subsequent Phase 7 plans.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-04-15T20:13:48Z
- **Completed:** 2026-04-15T20:19:30Z
- **Tasks:** 2 (TDD RED + GREEN)
- **Files created:** 6

## Accomplishments

- DEBT-03 requirement satisfied: single script mechanically closes REQUIREMENTS.md vs VERIFICATION.md drift gap, eliminating a retrospective failure mode (pitfall m-4) from v1.0.
- Wave 0 test harness (tests/phase-07/run.sh) established — the aggregator every subsequent Phase 7 plan extends with its own test_*.sh sibling.
- All 6 behavior tests pass: clean-advisory, drift-advisory, drift-strict (exit 2), JSON format, --phase filter, missing-VERIFICATION (not drift).
- Real .planning/ smoke test green: 78 REQ-IDs, 0 drift (expected — no VERIFICATION files yet for Phase 7).

## Task Commits

1. **Task 1: Build Wave 0 test harness + requirements-sync fixtures (RED)** — `af0ebc6` (test)
2. **Task 2: Implement bin/requirements-sync.sh to pass the harness (GREEN)** — `2e03096` (feat)

_TDD flow: Task 1 committed failing harness; Task 2 committed passing implementation. No refactor commit needed — first implementation was clean._

## Files Created/Modified

- `bin/requirements-sync.sh` — DEBT-03 mechanical traceability check (bash + python3 heredoc, flags: --help, --format text|json, --strict, --phase N, --root DIR)
- `tests/phase-07/run.sh` — Wave 0 aggregator (iterates test_*.sh, tallies pass/fail, supports --full no-op)
- `tests/phase-07/test_requirements_sync.sh` — 6 behavior tests: t1_clean_advisory, t2_drift_advisory, t3_drift_strict, t4_json_format, t5_phase_filter, t6_missing_verification
- `tests/phase-07/fixtures/requirements-sync/REQUIREMENTS.md` — fixture traceability table with TMPL-01/02/03, NEUT-01, DEBT-03, FOO-01 (Phase 8 for filter test)
- `tests/phase-07/fixtures/requirements-sync/07-VERIFICATION.md` — clean fixture (matches REQUIREMENTS)
- `tests/phase-07/fixtures/requirements-sync/07-drift-VERIFICATION.md` — drift fixture (TMPL-03 marked Complete where REQUIREMENTS says Pending)

## Artifacts — Flags and Exit Codes

**bin/requirements-sync.sh flags:**

| Flag | Arg | Purpose |
|------|-----|---------|
| `--help`, `-h` | — | Show usage |
| `--format` | `text` \| `json` | Output format (default `text`) |
| `--strict` | — | Exit 2 on any drift row (default advisory exit 0) |
| `--phase` | `N` (integer) | Restrict to REQ-IDs whose traceability row says `Phase N` |
| `--root` | `DIR` | Override default root `.planning/`; REQUIREMENTS.md read from `<root>/REQUIREMENTS.md`, VERIFICATION.md discovered via `find <root> -maxdepth 3 -name '*VERIFICATION.md'` |

**Exit codes:**

| Code | Meaning |
|------|---------|
| 0 | Success (advisory mode, or strict with no drift) |
| 1 | Script failure (missing files, bad flags, python error) |
| 2 | Strict mode found drift rows |

**Output formats:**

- `text` (default): Leading advisory note, then markdown table with columns `REQ-ID | REQUIREMENTS.md | VERIFICATION.md | Drift | Note`, trailing drift count.
- `json`: array of `{req_id, requirements_md, verification_md, drift, note, phase}`.

**Parser tolerance (REVIEWS.md medium finding):** VERIFICATION.md lines match all of `- REQ-ID: Status`, `- [x] REQ-ID: Status`, `- ✅ REQ-ID: Status`, `- **REQ-ID**: Status`. Status tokens normalized case-insensitively (Complete|Done|Pass|Passing → "Complete"; Pending|Todo|In Progress|Blocked → "Pending").

**Duplicate handling (REVIEWS.md medium finding):** Files processed in lexicographic path order; last-write-wins; `WARN: duplicate REQ-ID <id> seen in <earlier-path>; using <later-path> per last-write-wins` emitted to stderr per duplicate.

## Decisions Made

See `key-decisions` in frontmatter. Summary:

- **Added Note column to markdown table** (5 columns total; header still matches acceptance regex). Enables t6_missing_verification to grep "Phase not yet run" in stdout without parsing JSON.
- **Lexicographic last-write-wins + stderr WARN** for duplicate REQ-IDs across VERIFICATION files (REVIEWS medium finding honored).
- **Temp-file sentinel** to bridge python DRIFT_COUNT back to bash for --strict exit code (avoids parsing stdout after it was already printed for humans).

## Deviations from Plan

**Minor deviation (in-scope UX improvement):** The plan specified 4-column markdown table `REQ-ID | REQUIREMENTS.md | VERIFICATION.md | Drift`. Implementation adds a 5th `Note` column (`OK`, `DRIFT`, `OK - Phase not yet run`, or raw status for Unknown). Header regex `REQ-ID.*REQUIREMENTS\.md.*VERIFICATION\.md.*Drift` still matches. Added because test 6 (missing VERIFICATION must not be drift) needs the rationale visible in stdout, and pushing users to `--format json` just to see why a row is non-drift contradicts the "advisory default" design.

No Rule 1/2/3/4 auto-fixes were triggered — plan was written precisely enough that first implementation passed 5/6 tests; the 6th was fixed by the Note column addition above.

## Issues Encountered

None.

## User Setup Required

None — zero new runtime dependencies. Script uses only bash and python3 (both already required by bin/lint.sh).

## Next Phase Readiness

- Wave 0 harness ready for 07-02..07-05 to extend with sibling `test_*.sh` files.
- DEBT-03 closed — future phases can append their VERIFICATION.md truths and mechanically validate against REQUIREMENTS.md checkboxes.
- Real `.planning/` run: 78 rows, 0 drift (all Pending, all VERIFICATION missing — expected baseline before Phase 7 writes its 07-VERIFICATION.md).

---
*Phase: 07-neutral-template-foundation*
*Completed: 2026-04-15*

## Self-Check: PASSED

Verified:
- FOUND: bin/requirements-sync.sh
- FOUND: tests/phase-07/run.sh
- FOUND: tests/phase-07/test_requirements_sync.sh
- FOUND: tests/phase-07/fixtures/requirements-sync/REQUIREMENTS.md
- FOUND: tests/phase-07/fixtures/requirements-sync/07-VERIFICATION.md
- FOUND: tests/phase-07/fixtures/requirements-sync/07-drift-VERIFICATION.md
- FOUND commit af0ebc6 (Task 1 RED)
- FOUND commit 2e03096 (Task 2 GREEN)
- All 6 behavior tests PASS; `bash tests/phase-07/run.sh` exits 0
