# Phase 26 Verification — Wholesale CLI→Pytest Conversion (CUT-02)

**Verified:** 2026-07-03, against HEAD (the 3 phase-26 commits: 74aff85, a8df146, cf1d6fa).
**Method:** direct execution of the single `pytest -n auto` entrypoint (unit + black-box
bridge), the surviving phase-24 characterization goldens run against the shipped Python,
the 6 required-check scripts run locally, and `requirements-sync --phase 26 --strict
--require-complete`.

## CUT-02 — Wholesale CLI→Pytest Conversion

- **CUT-02**: Complete

Maps to the milestone brief's three success criteria:

### Criterion 1 — black-box + characterization suite on pytest; goldens still hold

`tests/test_blackbox_suites.py` (26-01, D-26-01 bridge) collects every
`tests/phase-<suite>/test_*.sh` across the enumerated suites (09 09.1 10 11 12.1 12.2 13
15 18 20 22 23 24) — **205 files ↔ 205 SUITE_MANIFEST rows** (bijection asserted by
`test_manifest_matches_suite_files`), of which the 10 pinned prior-phase FAILs are
`xfail(strict=True)`. Each runs against the REAL Python `bin/` shims. The phase-24
characterization goldens (validate-op, search modes, release/reqsync, error-path exit
codes, the ingest mutating footprint) were rewired from oracle-capture to **direct-Python**
capture (26-02) and still byte-match their frozen goldens — i.e. Python ≡ the retired
frozen-bash oracle, so the behavioral assertions are reproduced, not weakened. The
`shim_preflight_exit3` contract test now drives the REAL `bin/init-wizard.sh` shim
(previously vacuous under an empty manifest).

### Criterion 2 — single parallel `pytest` entrypoint; bash runner retired

A bare `pytest` IS the whole suite: `addopts = -n auto --dist loadgroup` (pyproject.toml).
`tests/run-all-suites.sh` (the bash runner) is DELETED. Measured on this machine (20 cores):

| Entrypoint | Wall-clock | Result |
|-----------|-----------|--------|
| retired serial bash runner (`WIKI_IMPL=py bash run-all-suites.sh`, pre-deletion) | 30.46s | baseline |
| **`pytest -n auto` (unit + bridge)** | **~7.4s** | **348 passed, 10 xfailed** |

~4× faster while running strictly more (149 unit + the black-box bridge). Stable across
repeated parallel runs (the three shared-live-state suites 12.2/18/24 + two live-skills
unit tests pinned to one worker via `xdist_group`).

### Criterion 3 — CI green; required-check contract preserved

The 6 branch-protected required checks keep their EXACT names and workflows — Phase 26 did
NOT touch `lint.yml` / `neutrality.yml` / `setup-parity.yml`. Only the ADDED parity jobs
went away: `parity.yml` (WIKI_IMPL matrix + parity-equivalence) deleted, replaced by
`tests.yml` (a NEW `tests` job running `pytest`, not one of the 6). `tests/test_ci_required_checks.py`
(green) enforces the 6-name contract + package-install + that `tests.yml` runs pytest, and
adds a resurrection guard for the deleted machinery.

Local runs of the required-check scripts:

| Check | Command | Local result |
|-------|---------|-------------|
| privacy-leak | `check-privacy.sh` + `check-sources-cloud-safe.sh` | exit 0 ✓ |
| strict | `lint.sh --require-version 1.1.0 --strict` | exit 0 ✓ |
| skills-check | `gen-skills.sh --check` | exit 0 ✓ |
| neutrality | `check-neutrality.sh` | exit 0 ✓ |
| lint | `lint.sh --ci --format json` | exit 1 — **pre-existing wiki content** (37 `crossref` red-link errors from recent ingests; clean on the empty public-template checkout the gate actually runs against) |
| setup-parity | `tests/phase-08/run.sh` | exit 1 — **pre-existing**: the wizard test is non-hermetic against an already-initialized repo ("repo already initialized"); passes on CI's fresh checkout |

Both non-zero results are independent of Phase 26 (my lint change gated the report *write*,
never the `--ci` exit logic; the wizard + phase-08 test are untouched but for one shim
comment) and reflect the local private-wiki/initialized-repo state, not the neutralized
template the required checks gate. The 348-green pytest suite exercises all six tools.

## Deferred / out-of-scope (recorded honestly)

- The optional cheap 25-REVIEW faithful-bash items (validate_op/check_privacy `encoding=`
  guard; release.py SIGTERM cleanup; search byte-vs-char; audit except→None) were NOT
  bundled (26-03 SUMMARY) — a v1.6 behavior/test-hygiene follow-on.
- The optional full file-by-file idiomatic rewrite of the bash suites into Python (the
  gold-plated end state beyond the bridge) is explicitly NOT part of CUT-02 (D-26-01).
- phase-08 setup-parity test is non-hermetic (writes into the live repo on a local run) —
  a pre-existing test-hygiene nit, not in the Phase-26 (bridge) scope.
