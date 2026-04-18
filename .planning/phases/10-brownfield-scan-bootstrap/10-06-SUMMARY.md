---
phase: 10-brownfield-scan-bootstrap
plan: 10-06-fixture-created-at-override
subsystem: brownfield
tags:
  - brownfield
  - fixtures
  - byte-equality
  - BRWN-21
  - gap-closure
requires:
  - 10-01-harness
  - 10-03-bootstrap
  - 10-05-verification
provides:
  - BROWNFIELD_FIXTURE_CREATED_AT env override
  - BRWN-21 transformed-output byte-equality contract (restored)
affects:
  - bin/lib/brownfield_yaml.py::build_d14_sentinel_set
  - tests/phase-10/test_brownfield_bootstrap_apply_*.sh (5 files)
tech_stack_added: []
tech_stack_patterns:
  - env-var date-pinning override (mirrors BROWNFIELD_FIXTURE_TODAY precedent)
  - fail-loud ValueError on malformed ISO-date inputs
key_files_created: []
key_files_modified:
  - bin/lib/brownfield_yaml.py
  - tests/phase-10/test_brownfield_bootstrap_apply_clean.sh
  - tests/phase-10/test_brownfield_bootstrap_apply_no_fm.sh
  - tests/phase-10/test_brownfield_bootstrap_apply_crlf.sh
  - tests/phase-10/test_brownfield_bootstrap_apply_dataview.sh
  - tests/phase-10/test_brownfield_bootstrap_apply_comments.sh
  - docs/reference/brownfield.md
decisions:
  - env-var override path preferred over mtime-pinning in make_fixture_repo (more orthogonal; fix lives in the same module that authors the date policy)
  - fail-loud ValueError on malformed ISO-date rather than silent fallback (matches mechanical-only brownfield contract D-11)
  - single commit for the plan (AGENTS.md §3 one-commit-per-logical-operation)
  - seven other BROWNFIELD_FIXTURE_TODAY-using tests left untouched (per-test audit documented in 10-06-PLAN.md Task 3)
metrics:
  duration: "2min"
  completed: "2026-04-18"
  files_changed: 7
  tasks_completed: 5
  commits: 1
requirements_completed:
  - BRWN-21
---

# Phase 10 Plan 06: Fixture created_at Override Summary

Closes the BRWN-21 transformed-output byte-equality gap by adding a `BROWNFIELD_FIXTURE_CREATED_AT` env-var override to `build_d14_sentinel_set()` that mirrors the existing `BROWNFIELD_FIXTURE_TODAY` pattern.

## One-Liner

Added `BROWNFIELD_FIXTURE_CREATED_AT` env override inside `bin/lib/brownfield_yaml.py::build_d14_sentinel_set` to pin `created_at` for fixture regression tests; phase-10 aggregator returns from 27/32 to 32/32 on any calendar date.

## What Changed

### Code path (bin/lib/brownfield_yaml.py)

- Extended module docstring bullet for `file_mtime_iso()` to reference the new override.
- Replaced the bare `created_at = file_mtime_iso(path)` / `OSError` fallback inside `build_d14_sentinel_set()` with a three-way path:
  1. `BROWNFIELD_FIXTURE_CREATED_AT` set → `datetime.date.fromisoformat()` with fail-loud `ValueError` on malformed input.
  2. Env var unset + file exists → `file_mtime_iso(path)` (production code path, unchanged).
  3. Env var unset + file unreadable → today fallback (production `OSError` path, unchanged).
- No new imports (`os` was already imported at line 26).
- `__all__` list is unchanged.
- `updated_at` / `bootstrap_date` distinct-datetime construction preserved verbatim (ruamel anchor/alias comment still applies).

### Test fixes (5 files)

Each of the five `tests/phase-10/test_brownfield_bootstrap_apply_*.sh` files now exports:

```bash
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"
export BROWNFIELD_FIXTURE_CREATED_AT="2026-04-17"
```

Insertion is strictly adjacent (no blank line between the two exports) per Task 2's adjacency assertion.

### Documentation (docs/reference/brownfield.md)

Added a new `## Fixture testing environment variables` section between `## Known limitations` and `## See also`. The section:

- Documents both `BROWNFIELD_FIXTURE_TODAY` and `BROWNFIELD_FIXTURE_CREATED_AT` in a two-row table.
- States explicit fixture-testing-only scope.
- Carries a `> **Scope warning:**` blockquote warning operators not to export the variable in production shells.
- Documents fail-loud semantics (ValueError on malformed input).

File length: 194 → 207 lines (13-line net addition).

## Gap Closure Evidence

**Before (2026-04-18 morning):** `PHASE 10 TESTS: 27/32` — five apply_* tests failing on `created_at` mtime drift per 10-VERIFICATION.md gap.

**After:**

```
$ PYTHONPATH=$HOME/.local/lib/python3/dist-packages bash tests/phase-10/run.sh
...
PHASE 10 TESTS: 32/32
```

Prior-phase regression suite (captured):

```
PHASE 07 TESTS: 22/22
PHASE 08 TESTS: 21/21
PHASE 09 TESTS: 28/28
PHASE 09.1 TESTS: 11/11
```

All five apply_* tests pass individually and via the aggregator.

## Fail-Loud Verification

Per Task 1 automated-verify block:

```
$ python3 -c "import os, sys, datetime; os.environ['BROWNFIELD_FIXTURE_CREATED_AT']='not-a-date'; \
   sys.path.insert(0, 'bin/lib'); from brownfield_yaml import build_d14_sentinel_set; \
   try: build_d14_sentinel_set('/tmp/nonexistent-brownfield-test', '', datetime.date(2026,4,18)); \
   except ValueError as e: assert 'BROWNFIELD_FIXTURE_CREATED_AT' in str(e); print('OK-fail-loud')"
OK-fail-loud
```

All three override sentinels were observed:
- `OK-override` — pinned date path returns `datetime.date(2026,4,17)` while `updated_at` remains `2026-04-18`.
- `OK-fallback` — env var absent → today fallback on OSError.
- `OK-fail-loud` — malformed value raises `ValueError` containing `BROWNFIELD_FIXTURE_CREATED_AT`.

## Seven Audited Tests Remain Untouched

Task 3 recorded explicit per-test decisions for the seven remaining `BROWNFIELD_FIXTURE_TODAY`-using tests. None required the new export:

| Test | Reason |
|------|--------|
| `test_brownfield_bootstrap_applied_manifest.sh` | Asserts APPLIED.md headers + page.md string only; no `created_at` assertion. |
| `test_brownfield_bootstrap_typed_merge.sh` | Custom inline vault; asserts `type` / `privacy` / `bootstrap_stage` / `bootstrap_date` via grep. |
| `test_brownfield_bootstrap_skip_tabs.sh` | Unparseable YAML routes to SKIPPED.md; sentinel injection never runs. |
| `test_brownfield_bootstrap_skip_dupkeys.sh` | Duplicate-key pre-scan routes to SKIPPED.md; sentinel injection never runs. |
| `test_brownfield_bootstrap_dryrun.sh` | Asserts REPORT.md shape only; no byte-equality against transformed output. |
| `test_brownfield_bootstrap_help.sh` | Exercises `--help`; never invokes bootstrap. Existing `BROWNFIELD_FIXTURE_TODAY` export is vestigial. |
| `test_brownfield_bootstrap_idempotent.sh` | Compares sha256 across two runs of the same vault (not against a committed fixture). `before == after` invariant is provided by `bootstrap_stage` idempotency skip at `bin/brownfield.sh:324`, not date determinism. |

Verified clean via `git diff --name-only HEAD -- <7 paths>` returning zero lines and `grep -l 'BROWNFIELD_FIXTURE_CREATED_AT' <7 paths>` returning zero matches.

## Deviations from Plan

None. Plan executed exactly as written. The plan-checker-approved spec was followed verbatim including:
- Two edits in `bin/lib/brownfield_yaml.py` (docstring bullet + `build_d14_sentinel_set` block replacement).
- Five adjacent `export` lines in the apply_* tests.
- New `## Fixture testing environment variables` section inserted between `## Known limitations` and `## See also`.
- Seven audited tests left untouched.

## Commits

| Commit | Files | Purpose |
|--------|-------|---------|
| `8b7d5b4` | 7 | fix(phase-10): pin created_at in fixture tests via BROWNFIELD_FIXTURE_CREATED_AT override |

Per AGENTS.md §3 one-commit-per-logical-operation and the plan's `<verification>` guidance ("this plan ships as ONE commit"), all five tasks landed in a single commit.

## Note for Phase 11 / Downstream

The `BROWNFIELD_FIXTURE_CREATED_AT` variable is scoped to fixture-testing only per `docs/reference/brownfield.md` `## Fixture testing environment variables`. Production `bin/brownfield.sh bootstrap` continues to derive `created_at` from file mtime per D-11 — the override code path is only reached when operators explicitly export the variable. The `## Scope warning:` blockquote documents that operators must not set this variable in production shells.

This fix is orthogonal to the three open WR-01/WR-02/WR-03 warnings from `10-REVIEW.md` (orphan-raw-sources REPORT.md drift on re-runs; idempotency narrowing for `raw`/`verified` stages; AGENTS.md §11.5 forward-reference mismatch) — those remain deferred per the plan's explicit out-of-scope declaration.

## Self-Check: PASSED

- File `bin/lib/brownfield_yaml.py` exists with `BROWNFIELD_FIXTURE_CREATED_AT` string present (grep matched).
- Files `tests/phase-10/test_brownfield_bootstrap_apply_{clean,no_fm,crlf,dataview,comments}.sh` all contain `BROWNFIELD_FIXTURE_CREATED_AT="2026-04-17"`.
- File `docs/reference/brownfield.md` contains `## Fixture testing environment variables` heading and is 207 lines (>= 194).
- Commit `8b7d5b4` exists: `git log --all | grep -q 8b7d5b4` — matched.
- Phase 10 aggregator reports `32/32`.
- Phase 07/08/09/09.1 aggregators green at their committed totals.
