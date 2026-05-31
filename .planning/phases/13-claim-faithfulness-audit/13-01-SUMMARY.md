---
phase: 13-claim-faithfulness-audit
plan: 01
subsystem: testing
tags: [bash, test-harness, verifier-contract, fixtures, faithfulness-audit]

# Dependency graph
requires:
  - phase: 12.2-local-wiki-write-gate
    provides: "tests/phase-12.2 harness shell (run.sh aggregator + lib.sh make_bare_repo/write_page/assert_exit_code/cleanup_fixture_repo) copied as the phase-13 base"
provides:
  - "tests/phase-13/run.sh — per-phase aggregator emitting 'PHASE 13 TESTS: N/M'"
  - "tests/phase-13/lib.sh — four copied fixture helpers + three new verifier helpers (make_fake_verifier / make_recording_verifier / make_argv_verifier) honoring the D-01 verifier subprocess contract"
  - "tests/phase-13/fixtures/README.md — the self-contained (BOTH summary AND raw-at-path:) fixture contract with all nine variants documented"
  - "tests/phase-13/test_harness_red_canary.sh — a green Wave-0 canary wiring the aggregator (1/1)"
affects: [13-02, 13-03, 13-04]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Fake/recording/argv verifier stubs make the non-deterministic LLM verdict step reproducible and prove the fail-closed privacy partition by negative assertion"
    - "Self-contained inline fixtures: each test writes BOTH the wiki/sources summary AND the raw source at its path: (no fixtures/ data dir)"

key-files:
  created:
    - tests/phase-13/run.sh
    - tests/phase-13/lib.sh
    - tests/phase-13/fixtures/README.md
    - tests/phase-13/test_harness_red_canary.sh
  modified: []

key-decisions:
  - "Canary is green-on-a-canary (always PASS), not a literally-failing RED suite — aggregator exits 0 with PHASE 13 TESTS: 1/1 (REVIEW LOW wording precision)"
  - "make_argv_verifier kept SEPARATE from make_fake_verifier so the shlex.split / stdin-only-payload contract has a dedicated argv-dumping stub (resolves cycle-2 LOW)"
  - "recording verifier uses \"$(cat)\" not a single read -r line so multi-line JSON passages land intact in verifier-saw.log"

patterns-established:
  - "Verifier-stub contract (D-01): stdin {claim,passage,support_type} -> stdout {verdict,rationale,sub_claims}; downstream tests inject a deterministic verdict engine"
  - "Negative-assertion privacy proof: recording verifier's sentinel log must NEVER contain a local_only source's distinctive passage text (D-02)"

requirements-completed: [FAITH-01, FAITH-02, FAITH-03, FAITH-04]

# Metrics
duration: 10min
completed: 2026-06-01
---

# Phase 13 Plan 01: Claim-Faithfulness Wave-0 Test Harness Summary

**Wired the phase-13 test harness (aggregator + fixture/verifier helper library + self-contained fixture contract) green-on-a-canary, with three D-01 verifier stubs that make the non-deterministic verdict step reproducible and prove the fail-closed privacy partition by negative assertion.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-01
- **Completed:** 2026-06-01
- **Tasks:** 2
- **Files created:** 4

## Accomplishments
- `tests/phase-13/run.sh` aggregator (copied from phase-12.2, banner → `PHASE 13 TESTS:`) — nullglob `test_*.sh` loop, PASS/FAIL tally, non-zero exit on any failure.
- `tests/phase-13/lib.sh` — four fixture helpers copied verbatim (mktemp prefix bumped to `phase13-`) plus three new verifier helpers (`make_fake_verifier`, `make_recording_verifier`, `make_argv_verifier`); all seven exported via `export -f`.
- `tests/phase-13/fixtures/README.md` — documents the self-contained BOTH-artifacts fixture contract (summary + raw at `path:`), real locator anchors (`## headings`, blank-line paragraphs, `<!-- page: N -->` markers), all nine fixture variants, and the `local_only`-default note (high `skipped-privacy` is not a failure).
- `tests/phase-13/test_harness_red_canary.sh` — a green Wave-0 canary that wires the aggregator (`PHASE 13 TESTS: 1/1`, exit 0).

## Task Commits

Each task was committed atomically:

1. **Task 1: Copy the phase-12.2 harness shell + add the two verifier helpers** — `6f99dcf` (test)
2. **Task 2: Document the self-contained fixture contract + ship one green canary** — `35b8672` (test)

**Plan metadata:** committed separately (this SUMMARY).

## Files Created/Modified
- `tests/phase-13/run.sh` — per-phase aggregator emitting `PHASE 13 TESTS: N/M`.
- `tests/phase-13/lib.sh` — fixture + verifier helper library (4 copied + 3 new, all `export -f`'d).
- `tests/phase-13/fixtures/README.md` — the self-contained fixture contract + nine variants.
- `tests/phase-13/test_harness_red_canary.sh` — green Wave-0 canary.

## Decisions Made
None beyond the plan — followed plan as specified. The three key-decisions above are the plan's own locked wording choices (green-canary not RED; separate argv verifier; `$(cat)` for multi-line capture), reaffirmed during execution.

## Deviations from Plan

None — plan executed exactly as written.

The three verifier helpers were functionally exercised before committing: the fake verifier emits a canned verdict and ignores argv; the recording verifier captured a multi-line JSON passage intact to `verifier-saw.log`; the argv verifier dumped `--tag mytag` to `verifier-argv.log` while the stdin claim text did NOT reach argv (no-leak confirmed). These checks are over-and-above the plan's `bash -n` + `grep` acceptance criteria and required no source changes.

## Issues Encountered
None. (A trailing `ZSH_VERSION: unbound variable` noise line appeared from a shell-snapshot teardown during one ad-hoc functional test, after all assertions had already passed; it is not part of the committed harness and does not affect `bash tests/phase-13/run.sh`, which exits 0.)

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Plans 02/03/04 can now author `tests/phase-13/test_*.sh` against `make_bare_repo` / `write_page` / the three verifier helpers and run them per-commit via `bash tests/phase-13/run.sh`.
- Plan 02 should DELETE `test_harness_red_canary.sh` when it adds its real tests (the canary prints an INFO hint to stderr once `bin/audit-claims.sh` exists), per the Rule-3 prior-phase-test obsolescence precedent.

## Self-Check: PASSED

- `tests/phase-13/run.sh` — FOUND
- `tests/phase-13/lib.sh` — FOUND
- `tests/phase-13/fixtures/README.md` — FOUND
- `tests/phase-13/test_harness_red_canary.sh` — FOUND
- Commit `6f99dcf` — FOUND
- Commit `35b8672` — FOUND
- `bash tests/phase-13/run.sh` → `PHASE 13 TESTS: 1/1`, exit 0 — VERIFIED

---
*Phase: 13-claim-faithfulness-audit*
*Completed: 2026-06-01*
