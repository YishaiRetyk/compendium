# 26-02 SUMMARY — retire the frozen-bash parity oracle (post-migration)

**Status:** Complete (2026-07-03)

## What was removed

The entire migration-only parity apparatus — its sole job was diffing two
implementations, and there is now only one (Python behind the shims). **22 files deleted:**

- **The oracle + seam machinery:** `tests/lib/oracle-worktree.sh` (git-worktree oracle at
  the frozen ref), `tests/lib/no-direct-bin-calls.sh` (seam-routing invariant), the 6
  `tests/lib/test_*.sh` seam self-tests, `tests/test_routed_parity_divergence.sh`.
- **The runner + pins:** `tests/run-all-suites.sh` (superseded by the 26-01 bridge),
  `tests/ported.manifest`, `tests/freeze-baseline.sha`, `tests/oracle-exempt.{md,txt}`,
  `tests/impl-assertion-inventory.md`.
- **The gates:** `bin/check-staged-parity.sh`, `bin/check-common-freeze.sh`,
  `.github/workflows/parity.yml` (the WIKI_IMPL matrix + parity-equivalence jobs).
- **The parity self-tests:** `tests/phase-24/test_{freeze_guard,staged_parity_index,`
  `impl_assertion_inventory,precommit_hooks}.sh` (they tested the deleted gates/guard/old
  hook shape) — pruned from `SUITE_MANIFEST.txt` (209 → 205 rows).
- **`git tag -d phase-24-freeze`** (local-only, never pushed — nothing to clean remotely).

## What was kept (and rewired to the single impl)

The phase-24 **characterization goldens** are real regression coverage — validate-op,
search modes, release/reqsync, the error-path exit codes, and the ingest mutating
footprint each had ZERO other coverage. They captured "through the oracle," but the oracle
was byte-certified equal to the shipped Python, so the goldens are preserved by capturing
the shipped Python directly:

- **`tests/lib/invoke_tool.sh`** simplified to a direct seam: `invoke_tool` runs
  `bin/<tool>.sh` (shim → Python) — no `WIKI_IMPL` branch, no worktree oracle, no
  `ported.manifest`, no cross-run channel-capture. `capture_footprint`/`assert_parity` +
  `normalize.sh` survive for the goldens (golden-normalization, not oracle-specific).
- **`tests/phase-24/lib.sh`**: `extract_writable_tree` now `git archive HEAD` (HEAD's tools
  ≡ the retired baseline); the parity-gate scaffold helpers dropped.
- **`tests/phase-24/test_shim_preflight_exit3.sh`** rewired off `ported.manifest` +
  `_oracle_exec_root` onto a contract registry — and its case (c) now drives the REAL
  shipped `bin/init-wizard.sh` shim (previously vacuous under an empty manifest → now a
  genuine assertion that the exit-3 preflight survives).
- **`tests/phase-11/test_hashlib_not_sha256sum.sh`** reads the canonical migration script
  from `$REPO_ROOT` instead of the oracle worktree (schema/ was never migrated).

All 6 surviving phase-24 tests + the hashlib test pass against the direct-Python seam,
confirming the goldens still hold (Python ≡ retired oracle).

## New hook + CI shape

- **`.githooks/pre-commit`**: dropped `check-common-freeze` + `check-staged-parity`; kept
  `sync-claude --check`, `gen-skills --check`, `lint --strict --staged`. Added a **scoped**
  regression smoke: the hermetic unit tests (`pytest --ignore=…blackbox…`) run ONLY when the
  commit touches code (`bin/`/`src/`/`tests/`/`pyproject.toml`); a wiki/planning commit skips
  it, so routine commits stay fast (opt out `WIKI_SKIP_PYTEST=1`). A bin/src commit no longer
  runs the ~50-min oracle gate.
- **`.github/workflows/tests.yml`** (new `tests` job): `pip install -e .[dev]` + `pytest`.
  Replaces parity.yml as the regression net. The 6 required checks (lint, privacy-leak,
  strict, skills-check, neutrality, setup-parity) keep their names and workflows untouched.
- **`tests/test_ci_required_checks.py`** rewritten: keeps the 6-required-check contract,
  drops the parity-matrix assertions, adds a tests.yml-runs-pytest check + a resurrection
  guard (the deleted machinery must stay deleted).

## Verification

- `pytest -n auto`: **345 passed, 10 xfailed** (349 − the 4 removed parity self-tests);
  stable across repeated parallel runs; `wiki-cloud/` byte-clean after runs.
- `bin/check-neutrality.sh` green (the new `.github/workflows/tests.yml` is placeholder-clean).
- Stray-reference scan: no runtime reference to any deleted file remains; the only textual
  mentions are retirement comments + the resurrection-guard's string list.

## Commit note

Committed through the NEW (lighter) hook to exercise it — sync-claude/gen-skills clean, the
scoped pytest smoke ran the unit layer green, no freeze/parity gate. The `lint --staged`
step still clobbers `wiki-cloud/{log.md,lint-report.md}` (the 26-03 target); those writes
were stripped post-commit and are not part of this commit. The user's concurrent `.planning/`
notes were left unstaged (pathspec-scoped).
