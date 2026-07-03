---
phase: 26-cli-pytest-conversion
plan: 01
type: execute
wave: 1
depends_on: []
requirements: [CUT-02]
files_modified:
  - tests/conftest.py (extend — bash-suite collector)
  - tests/test_blackbox_suites.py (new — the bridge)
  - pyproject.toml ([tool.pytest.ini_options] addopts / markers; pytest-xdist dep)
autonomous: true
---

<objective>
Deliver CUT-02 success criterion #2: a SINGLE `pytest` entrypoint that runs the entire
black-box suite in PARALLEL against the real Python `bin/`. Bridge, not rewrite (D-26-01):
a pytest collector parametrizes over the existing bash test files and runs each in a
worker, asserting its pinned pass/FAIL state. The bash *runner* is superseded; the bash
test *files* stay as the behavioral spec.
</objective>

<context>
- The enumerated suites (SUITES in tests/run-all-suites.sh: 09 09.1 10 11 12.1 12.2 13 15
  18 20 22 23 24) + their per-test pass/FAIL baseline live in tests/SUITE_MANIFEST.txt
  (10 pinned FAILs). The bridge must reproduce that baseline exactly: a pinned-FAIL test
  is `xfail(strict=True)`; everything else must pass.
- Post-migration the tools ARE Python behind the shims. The bridge runs each bash test
  with the DEFAULT impl (no WIKI_IMPL bash-oracle needed) so it exercises the real
  Python. The seam (tests/lib/invoke_tool.sh) still routes tool calls; 26-02 simplifies
  it. In THIS plan, run tests as `WIKI_IMPL=py` (or default) so the bridge is green
  against the shipped Python before the oracle is removed.
- pytest-xdist gives `-n auto` parallelism. Add it to the dev deps + pin it.
- Suite 24 is the parity-harness self-test suite; its tests are about the oracle
  machinery being retired in 26-02. Include it in the bridge for now (green), and 26-02
  removes the obsolete ones.
</context>

<tasks>
1. Add pytest-xdist to pyproject (pinned) + `[tool.pytest.ini_options]` (addopts, the
   requires_ollama/requires_network markers already exist).
2. Write tests/test_blackbox_suites.py: discover every `tests/phase-*/test_*.sh`,
   parametrize (id = `<suite>/<testfile>`), run each via subprocess against the repo,
   assert exit 0 — EXCEPT the SUITE_MANIFEST.txt-pinned FAILs, which are marked
   xfail(strict=True) by looking up the manifest. Honor the same env the runner set
   (LC_ALL=C TZ=UTC PYTHONPATH=src). Skip Ollama/network-dependent tests via the existing
   markers/skipif.
3. Verify: `pytest -n auto` runs the FULL suite (bash-bridge + the 149 existing unit
   tests) green, reproducing the manifest baseline (pinned FAILs xfail, no unexpected
   fails), and materially faster than the serial bash runner. Record wall-clock.
4. Commit `feat(26): pytest bridge — single parallel entrypoint over the black-box suite
   (CUT-02)`. (Touches tests/ + pyproject → the parity gate may run; it should pass, this
   adds no behavior change. If pyproject is frozen surface and the gate blocks a pytest-
   only addition, use the D-09 flow — but prefer 26-02 landing first if friction arises.)
</tasks>

<acceptance>
- `pytest -n auto` is the single command that runs everything; exit 0 with the manifest
  baseline reproduced (pinned FAILs xfail-strict).
- Parallel wall-clock recorded and materially below the serial bash runner.
- No behavior change to any tool; no golden touched.
</acceptance>
