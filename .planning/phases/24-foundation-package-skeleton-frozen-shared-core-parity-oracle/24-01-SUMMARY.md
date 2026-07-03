# Plan 24-01 Summary — Package skeleton + ported.manifest + shim-contract doc (wave 1)

**Executed:** 2026-07-03. **Requirements:** PKG-01, PKG-03. **Status:** Complete.

## What shipped

- `pyproject.toml` — src-layout package `compendium` v1.5.0; **16** `console_scripts` (re-baselined
  from the plan's 15 per RB-1: `compendium-repo-snapshot` added) bound to stub modules; exact pins
  re-derived per RB-2: `PyYAML==6.0.3`, `ruamel.yaml==0.19.1` (runtime), `setuptools==82.0.1`
  (build backend), `pytest==9.0.2` (dev) — the plan's 6.0.1/80.9.0/8.4.1 numbers were laptop-era;
  the requirement is the exact `==` pin, recorded here as mandated. `requires-python = ">=3.11"`.
- `src/compendium/` — `__init__.py` + 16 stubs, each `main()` returning the NOT_IMPLEMENTED
  sentinel **70** (fails loudly if accidentally activated) + `__main__` block for the D-04
  `python3 -m` form. Each stub names its Phase-25 MIG cluster (repo_snapshot → MIG-05 wiki-ops).
- `tests/ported.manifest` — zero tool lines (nothing ported); documents the py-lane-via-shim
  switch, the D-08/D-09 freeze posture, and the N-4 loud-fail rule.
- `tests/test_packaging.py` — PKG-01 smoke: bootstraps a venv (no system-pip assumption),
  `pip install -e .`, imports (incl. `compendium.repo_snapshot`), asserts the `python -m` stub
  contract (exit 70 + "not yet implemented" stderr). **Passed** (1 passed, nested-venv form).
- `docs/reference/python-shim-contract.md` — the LOCKED contract: checkout-hermetic shim form with
  the PYTHONPATH bootstrap OWNED BY THE SHIM (§1a: smoke test runs with seam PYTHONPATH cleared —
  cycle-4 finding #3), WIKI_IMPL mechanism (worktree oracle for bash + shim-on-parity-path for py;
  no stale committed-copy language — cycle-3 finding #3), divergent exit codes incl. the exit-3
  shim-owned preflight compat boundary (cross-ref Plan 04's test), downstream callers.
- AGENTS.md §2: `src/` + `tests/` added to permitted top-level dirs; propagated via
  `bin/sync-claude.sh` (`--check` exit 0; `cmp -s` byte-equal).

## Verification

pyproject tomllib assertions (16 scripts, exact pins, src find) ✓; all 16 stubs grep
`NOT_IMPLEMENTED_EXIT = 70` + `__main__` ✓; `tests/test_packaging.py` green in a bootstrapped venv ✓;
shim-doc acceptance greps (incl. the negative COMMITTED-COPY/tests-oracle checks) ✓;
`bin/check-neutrality.sh` exit 0 ✓; `git diff --name-only HEAD -- bin/` empty ✓;
`src/compendium/common/` NOT created (Plan 02 owns it) ✓.

## Deviations from plan

- 15 → 16 tools throughout (RB-1). Dep/toolchain pins re-derived (RB-2) via the plan's own
  escape clause. Package version 1.5.0 (not 1.4.0 — RB-2, milestone renumbering).
- ruamel.yaml was absent on this machine; installed 0.19.1 (brew pip, `--break-system-packages`)
  during the re-baseline so the bash brownfield oracle runs; brownfield goldens verified green
  under PyYAML 6.0.3 + ruamel 0.19.1 (phase-10 31/32, phase-11 47/48; failures are the known
  stale AGENTS-section tests).
