# Plan 24-03 Summary — Parity seam (WIKI_IMPL) + pytest harness (wave 2)

**Executed:** 2026-07-03. **Requirements:** TEST-01, TEST-05. **Status:** Complete.

## What shipped

- `tests/lib/oracle-worktree.sh` — the worktree-backed held-fixed bash oracle: baseline ref
  resolution `phase-24-freeze^{commit}` → `tests/freeze-baseline.sha` → HEAD (loud-FATAL on
  ported+HEAD fallthrough and on tag-vs-SHA mismatch — N-4); per-repo/per-baseline-keyed cached
  worktree path (N-5, `WIKI_ORACLE_WORKTREE` override); the two CYCLE-6 per-lane root knobs
  `WIKI_EXEC_ROOT`/`WIKI_ORACLE_GIT_ROOT` (both default `$REPO_ROOT`; all oracle git commands run
  against `_oracle_git_root`, never bare `$REPO_ROOT`).
- `tests/lib/invoke_tool.sh` — the branching seam: bash leg = `<worktree>/bin/<tool>.sh`; py leg
  = the REAL `bin/<tool>.sh` shim from the exec root, gated by `tests/ported.manifest`
  (empty → green-by-fallthrough); `return 0` always, status via `IT_EXIT` (HIGH#2);
  `LC_ALL=C TZ=UTC PYTHONPATH=<exec-root>/src` pinned on the normal lane; `IT_CAPTURE_DIR`
  per-call self-record under the collision-proof `<testbasename>-<pid>/<tool>-<NN>` key
  (cycle-4 #1); `_it_footprint_root` snapshots the `--root` fixture, not `$PWD` (cycle-6 #4);
  `it_pairing_key` pid-strip for cross-run pairing (cycle-6 #4); `capture_footprint` 4-channel
  `<case>/{stdout,stderr,exit,tree}` with mode/exec-bit + symlink target + empty dirs;
  `assert_parity` all-4-channel cmp.
- `tests/lib/normalize.sh` — time-bearing-timestamp + tmp/fixture-path redaction ONLY (no bare
  dates, no hex, no sort).
- Six self-tests, all green: normalize (wrong contractual values NOT masked; JSON order held),
  seterm (set -e caller survives, `IT_EXIT=1` captured), capture-dir (keyed record;
  fileA/fileB first-call collision-proofing; injected byte divergence caught; `--root` tree;
  pid-strip pairing), shim-smoke (canonical shim passes with seam PYTHONPATH cleared;
  bootstrap-free shim fails with ModuleNotFoundError; broken shim caught via the py lane
  `IT_EXIT=1`; manifest-driven per-shim loop flags a bootstrap-free scaffold, passes canonical,
  no-ops on the real empty manifest), selfparity (seam byte-identical to direct oracle calls for
  lint --help / validate-op usage / search usage), scriptrelative (audit-claims via
  `--sample 3 --format json` past :123, brownfield `scan --root` past :730, gen-skills --check —
  all through the worktree without aborting).
- `tests/conftest.py` + `tests/test_conftest_fixtures.py` — `git_repo`/`fixture_repo` mirroring
  the bash helpers (identity, `-b main`, gpgsign=false, README exclusion, fresh dir per factory
  call), unified `SEED_MSG="seed"` (enforced against the bash source by a test),
  `assert_golden_tree`, Ollama/network skipif markers. 5 tests green (15 total python tests).

## Verification

All six seam self-tests pass; all plan acceptance greps pass (incl. the negative ones: no
`return $IT_EXIT`, no `cmd=(python3 -m`, no `capture_footprint "$PWD"`, no flat
`tests/lib/oracle/` dir, no sort/bare-date/hex redaction in normalize);
`git diff tests/phase-09 tests/phase-10 tests/phase-13` empty (D-13);
pytest 15/15 in the pinned venv.

## Deviations / findings during execution

- Fixed at execute time (behavior probe): the brownfield scan banner goes to **stderr** — the
  scriptrelative self-test asserts it there (the plan text implied stdout).
- Replaced `grep -q X && fail` idioms with `if grep; then fail; fi` in the scriptrelative test —
  under `set -e` a non-matching grep would abort the AND-list silently (latent test bug).
- audit-claims reach-lib invocation is `--sample 3 --format json` (the plan's example
  `--since 1970-01-01` would pass a non-ref; `--since` takes a git ref — any non-help invocation
  reaches :123, verified empirically: exit 0, real JSON).
- GNU `stat -c`/`sha256sum` dependency in `capture_footprint` — known LOW portability item,
  acceptable per the pinned Linux environment (recorded as the plan requires).
