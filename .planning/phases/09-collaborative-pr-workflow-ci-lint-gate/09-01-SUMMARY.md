---
phase: 09-collaborative-pr-workflow-ci-lint-gate
plan: 01
subsystem: testing
tags: [bash, git, fixtures, test-harness, ci]

# Dependency graph
requires:
  - phase: 08-two-track-setup-wizard-manual
    provides: tests/phase-08 aggregator pattern (nullglob + PASS/FAIL + "PHASE NN TESTS: N/M") and lib.sh helper conventions
provides:
  - tests/phase-09/run.sh — Phase 9 test aggregator
  - tests/phase-09/lib.sh — shared bash helpers (make_fixture_repo, setup_git_author, seed_origin_main_ref, assert_json_has_finding, assert_exit_code, cleanup_fixture_repo)
  - 8 fixture directories under tests/phase-09/fixtures/ covering CI-06 (strict-missing-dr, strict-missing-prov, strict-escape-hatch), CI-07 (privacy-leak-public, privacy-ok-wiki), COLAB-04 (contributor-single, contributor-multi), and CI-02/03 (ci-lint-json)
affects: [09-02, 09-03, 09-04, 09-05, 09-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "phase-NN test harness: nullglob + PASS/FAIL + PHASE NN TESTS: N/M summary line (Phase 7/8/9)"
    - "Shared bash helpers in lib.sh + per-test source line (no inline boilerplate)"
    - "Static fixture directories (no committed .git/); make_fixture_repo instantiates throwaway git repo at test time via mktemp + git init -b main"
    - "README.md per fixture documenting purpose; excluded from fixture copy via find ! -name README.md"
    - "LF line endings + UTF-8 encoding discipline for all seeded .md files (line-number-sensitive assertions downstream)"
    - "seed_origin_main_ref stages canonical refs/remotes/origin/main for --strict tests' origin/main...HEAD diffs (P1 review fix)"
    - "setup_git_author uses per-call unique filename (email-slug + nanoseconds + RANDOM) replacing collision-prone .ts (P2 review fix)"

key-files:
  created:
    - tests/phase-09/run.sh
    - tests/phase-09/lib.sh
    - tests/phase-09/fixtures/strict-missing-dr/
    - tests/phase-09/fixtures/strict-missing-prov/
    - tests/phase-09/fixtures/strict-escape-hatch/
    - tests/phase-09/fixtures/privacy-leak-public/
    - tests/phase-09/fixtures/privacy-ok-wiki/
    - tests/phase-09/fixtures/contributor-single/
    - tests/phase-09/fixtures/contributor-multi/
    - tests/phase-09/fixtures/ci-lint-json/
  modified: []

key-decisions:
  - "Harness copies Phase-08 pattern verbatim with only 08->09 rename in header comment and summary-line substring; zero semantic drift preserves operator muscle memory."
  - "Fixtures are static input (no .git/ committed); make_fixture_repo seeds a throwaway mktemp git repo at test time via git init -b main, decoupling fixture content from test-time state mutations."
  - "README.md in each fixture is documentation; find ! -name README.md excludes it from the fixture-to-test-repo copy so it never appears in the repo under test."
  - "setup_git_author uses per-call unique seed filename (email-slug + %s%N + RANDOM) to survive tight-loop calls without collision — replaces the .ts primitive flagged in Codex LOW review."
  - "seed_origin_main_ref is a first-class helper (not per-test plumbing) — Plan 09-03 strict tests depend on origin/main...HEAD semantics and reinventing the ref setup in each test would be MEDIUM tech debt."
  - "All seeded .md files use LF + UTF-8 (no BOM, no CRLF); critical for Plan 09-03 line-number-sensitive assertions (adjacency of escape-hatch marker to [inferred] claim, diff hunk line numbers)."

patterns-established:
  - "Per-fixture README.md documenting triggers, contents, and encoding discipline — makes fixture intent self-documenting for future agents adding test cases."
  - "Helper signature: make_fixture_repo <fixture-name> -> echoes tmp path (stdout-only contract; callers capture with $())."
  - "Helper signature: setup_git_author <repo> <name> <email> — config + one commit per call; unique file per invocation."
  - "Helper signature: seed_origin_main_ref <repo> — idempotent; prefers refs/heads/main, falls back to current HEAD branch."
  - "Helper signature: assert_json_has_finding <json-file> <category> <severity> — python3 heredoc parse, stderr diagnostics on failure listing all present findings."

requirements-completed: [CI-06, CI-07, COLAB-04]

# Metrics
duration: 4min
completed: 2026-04-16
---

# Phase 09 Plan 01: Test Harness and Fixtures Summary

**Phase 9 test aggregator + shared bash lib + 8 fixture directories (CI-06 strict/DR/prov, CI-07 privacy, COLAB-04 contributor, CI-02/03 JSON) with LF+UTF-8 encoding discipline, enabling all downstream Phase 9 plans to call `make_fixture_repo <name>` instead of reinventing git/fixture plumbing per test.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-04-16T07:39:26Z
- **Completed:** 2026-04-16T07:43:30Z
- **Tasks:** 2
- **Files created:** 18 (run.sh, lib.sh, 8 READMEs, 8 seeded files including .gitkeep and .git-author-map.txt)

## Accomplishments

- `tests/phase-09/run.sh` — Phase 9 aggregator cloned from phase-08 with only the `08 -> 09` rename in summary line and header comment (zero semantic drift).
- `tests/phase-09/lib.sh` — six exported bash helpers: `make_fixture_repo`, `setup_git_author`, `seed_origin_main_ref`, `assert_exit_code`, `assert_json_has_finding`, `cleanup_fixture_repo`.
- 8 fixture directories with per-fixture READMEs documenting purpose and contents; all seeded `.md` and `.txt` files pass LF + UTF-8 discipline (verified: `! find ... -exec grep -lP '\r'` and `file -bi | grep charset=(utf-8|us-ascii)`).
- Smoke-tested `make_fixture_repo`, `setup_git_author` (3 distinct authors, zero filename collisions), and `seed_origin_main_ref` (refs/remotes/origin/main + refs/remotes/origin/HEAD populated).

## Task Commits

Each task was committed atomically:

1. **Task 1: Harness + lib helpers** — `dfc050c` (feat)
2. **Task 2: 8 fixture directories** — `c1da80a` (feat)

## Files Created/Modified

### Harness
- `tests/phase-09/run.sh` — Phase 9 test aggregator (nullglob + PASS/FAIL + "PHASE 09 TESTS: N/M").
- `tests/phase-09/lib.sh` — shared helpers sourced by downstream `test_*.sh`.

### Fixtures (each has `README.md` + seeded content files)
- `tests/phase-09/fixtures/strict-missing-dr/` — `wiki/concepts/attention.md` with `[epistemic:: inferred]` and no DR (CI-06 negative case).
- `tests/phase-09/fixtures/strict-missing-prov/` — `wiki/concepts/new-concept.md` with zero `[prov:` markers (CI-06 D-10 new-page case).
- `tests/phase-09/fixtures/strict-escape-hatch/` — `wiki/concepts/attention.md` with `<!-- lint:expect-inferred -->` on line immediately above `[inferred]` claim (D-09 positive case, line 28 + 29).
- `tests/phase-09/fixtures/privacy-leak-public/` — `docs/sample.md` with `privacy: local_only` (CI-07 leak).
- `tests/phase-09/fixtures/privacy-ok-wiki/` — `wiki/local.md` with `privacy: local_only` (valid user content).
- `tests/phase-09/fixtures/contributor-single/` — `.gitkeep` only (seed commit provides single author; D-20).
- `tests/phase-09/fixtures/contributor-multi/` — `.git-author-map.txt` mapping `alice@example.com -> @alice`, bob intentionally unmapped (COLAB-04 map-coverage branches).
- `tests/phase-09/fixtures/ci-lint-json/` — `wiki/index.md` skeleton (tests seed additional triggering files inline so fixture stays minimal and resilient to lint-rule drift).

## Public API (lib.sh exports)

```bash
make_fixture_repo <fixture-name> -> echoes /tmp/phase09-fixture-XXXXXX path
setup_git_author <repo-path> <name> <email> -> adds one commit as that author (unique per-call file)
seed_origin_main_ref <repo-path> -> stages refs/remotes/origin/main + origin/HEAD
assert_exit_code <expected> <actual> <description> -> returns non-zero on mismatch
assert_json_has_finding <json-file> <category> <severity> -> python3 parse, stderr diagnostics
cleanup_fixture_repo <path> -> safe rm -rf scoped to /tmp/
```

All helpers `export -f`ed so subshells in `test_*.sh` can call them.

## Decisions Made

- **Harness pattern:** Phase-08 clone with `08 -> 09` rename only. Operator muscle memory from Phase 7/8 transfers to Phase 9 with no relearning.
- **Fixture strategy:** Static content on disk; throwaway git repo created at test time via `git init -b main` on a mktemp dir. Avoids committing nested `.git/` and lets tests freely mutate state.
- **README-per-fixture:** Every fixture directory self-documents its purpose, triggers (which requirement / decision), and expected behavior. READMEs are excluded from the fixture-to-repo copy by `find ! -name README.md`.
- **Encoding discipline:** LF + UTF-8 verified post-write; critical for Plan 09-03 line-number assertions (escape-hatch marker must be on line N-1 of the `[inferred]` claim on line N; CRLF would shift byte offsets and break adjacency checks).
- **`setup_git_author` filename scheme:** `.author-{email_slug}-{nanoseconds}-{RANDOM}.seed` replaces the collision-prone `.ts` primitive (Codex LOW review item). Smoke-tested with 3 back-to-back authors in one fixture — zero collisions, 3 distinct commits.
- **`seed_origin_main_ref` as first-class helper:** Plan 09-03's strict tests need canonical `origin/main...HEAD` semantics. Centralizing the remote-ref setup prevents the MEDIUM tech-debt of each test reinventing branch/remote plumbing.

## Deviations from Plan

None — plan executed exactly as written. All verification checks pass:

- `bash -n tests/phase-09/run.sh` syntax-clean.
- `bash -n tests/phase-09/lib.sh` syntax-clean.
- `PHASE 09 TESTS:` summary-line substring present in `run.sh`.
- All 6 helper names present in `lib.sh` (grep count >= 4 required, actual is 13 matches across function definitions and exports).
- `git init -q -b main` substring present (deterministic primary branch).
- `author-.*seed` pattern present (unique-per-call filename).
- `! grep -q 'date > .ts'` (old collision-prone primitive absent).
- 8 fixture directories exist; `find ... -name README.md | wc -l` == 8.
- `strict-missing-dr/wiki/concepts/attention.md` contains `[epistemic:: inferred]`.
- `strict-missing-prov/wiki/concepts/new-concept.md` has zero `[prov:` occurrences.
- `strict-escape-hatch` marker on line 28, `[inferred]` claim on line 29 (adjacent, no blank line).
- `privacy-leak-public/docs/sample.md` + `privacy-ok-wiki/wiki/local.md` both contain `privacy: local_only`.
- `contributor-multi/.git-author-map.txt` contains exact `alice@example.com  ->  @alice` (two-space-arrow-two-space).
- No `.git/` subdirectory in any fixture.
- No CRLF in any `.md` fixture; all files pass `file -bi` charset check (utf-8 or us-ascii).

## Issues Encountered

- **Parallel execution interaction:** Plan 09-02's executor (running concurrently) had already created `tests/phase-09/test_lint_version.sh`, which meant `bash tests/phase-09/run.sh` did not literally print `PHASE 09 TESTS: 0/0` (it counted that one test and reported 0/1 since `bin/lint.sh --version` isn't implemented yet — that's Plan 09-02's job). The aggregator itself worked correctly; the "0/0" acceptance sub-check assumed sequential execution. Core Task 1 acceptance criteria (harness shape, helper definitions, syntax cleanliness) all pass. No action needed — this is expected parallel-execution behavior, and Plan 09-02 will land the `--version` flag that makes its own test pass.

## Next Plan Readiness

- **Plan 09-02 (lint-flags-json-ci-version):** Can add `test_lint_version.sh`, `test_lint_json.sh`, `test_lint_ci_severity_remap.sh` under `tests/phase-09/`, each sourcing `lib.sh` and calling `make_fixture_repo ci-lint-json`.
- **Plan 09-03 (strict/escape-hatch/contributor):** Can call `make_fixture_repo strict-missing-dr` / `strict-missing-prov` / `strict-escape-hatch`, then `seed_origin_main_ref "$FIXTURE"` to exercise `--strict` with `origin/main...HEAD` diff semantics.
- **Plan 09-04 (privacy/ingest/search/contributor):** Can call `make_fixture_repo privacy-leak-public` / `privacy-ok-wiki` / `contributor-single` / `contributor-multi`, and chain `setup_git_author "$FIXTURE" Alice alice@example.com` for multi-author scenarios.
- **Plan 09-05 (CI workflow):** No direct harness dependency, but CI runs `bash tests/phase-09/run.sh` — the aggregator is ready.
- **Plan 09-06 (contributing docs):** No direct harness dependency.

## Self-Check: PASSED

- `tests/phase-09/run.sh` — FOUND
- `tests/phase-09/lib.sh` — FOUND
- `tests/phase-09/fixtures/strict-missing-dr/wiki/concepts/attention.md` — FOUND
- `tests/phase-09/fixtures/strict-missing-prov/wiki/concepts/new-concept.md` — FOUND
- `tests/phase-09/fixtures/strict-escape-hatch/wiki/concepts/attention.md` — FOUND
- `tests/phase-09/fixtures/privacy-leak-public/docs/sample.md` — FOUND
- `tests/phase-09/fixtures/privacy-ok-wiki/wiki/local.md` — FOUND
- `tests/phase-09/fixtures/contributor-single/.gitkeep` — FOUND
- `tests/phase-09/fixtures/contributor-multi/.git-author-map.txt` — FOUND
- `tests/phase-09/fixtures/ci-lint-json/wiki/index.md` — FOUND
- Commit `dfc050c` (Task 1) — FOUND
- Commit `c1da80a` (Task 2) — FOUND

---
*Phase: 09-collaborative-pr-workflow-ci-lint-gate*
*Plan: 01*
*Completed: 2026-04-16*
