# Phase 24 Verification — Foundation: Package Skeleton + Frozen Shared Core + Parity Oracle

**Verified:** 2026-07-03. **Commits:** `ba1c9c3` (re-baseline) → `9f1093d` (freeze pin). All six
plans executed in five waves; the RB re-baseline (`24-REBASELINE.md`) governed every concrete count.

## Requirements

- [x] PKG-01: Complete
  — `pyproject.toml` (src layout, 16 console_scripts per RB-1, exact pins
  PyYAML==6.0.3/ruamel.yaml==0.19.1/setuptools==82.0.1/pytest==9.0.2 per RB-2);
  `pip install -e .` green in a bootstrapped venv; `import compendium` + `python3 -m
  compendium.<tool>` resolve for all 16 stubs (`tests/test_packaging.py` green).
- [x] PKG-02: Complete
  — `src/compendium/common/` = 5 byte-identical bin/lib lifts + `page.py`
  from authoritative lint.sh 1.12.0; audit≡lint precondition an automated gate (Test 0);
  `docs/reference/common-api-inventory.md` classifies every outside duplicate;
  `tests/test_common_extraction.py` 9/9.
- [x] PKG-03: Complete
  — `docs/reference/python-shim-contract.md` locks the checkout-hermetic
  shim form (shim OWNS its PYTHONPATH bootstrap; smoke test runs seam-env-cleared), the
  WIKI_IMPL worktree-oracle mechanism, divergent exit codes incl. the shim-owned exit-3
  preflight; `bin/` untouched all phase (no shim flipped — `git diff` empty at every plan).
- [x] PKG-04: Complete
  — 3 workflows + the required `skills-check` job install the package;
  6 required-check names unchanged, no matrix (introspection test 5/5); `parity.yml` adds
  `parity-suites (bash|py)` + `parity-equivalence` + `common-freeze` as NEW names.
- [x] TEST-01: Complete
  — the `invoke_tool` seam branches on `WIKI_IMPL` (worktree oracle /
  shim-if-ported), returns 0 with `IT_EXIT`, self-records 4 channels under the
  collision-proof key; 228 direct call sites across 141 files routed (via
  `invoke_tool_compat`, assertions untouched — D-13); `--require-parity` byte-compares
  channels with pid-independent pairing; the LIVE-path divergence test catches an injected
  one-byte divergence and passed its inverse.
- [x] TEST-02: Complete
  — enumerated suites `09 09.1 10 11 12.1 12.2 13 15 18 20 22 23 24`
  (RB-5) wired into `run-all-suites.sh` + `parity.yml` matrix; per-test manifest pinned
  (206 tests; 10 pre-existing stale FAILs); missing suite = loud failure.
- [x] TEST-03: Complete
  — 33 committed 4-channel golden case dirs: validate-op ×10 (zero tests
  before), search ×9 (incl. the piped-index latent-bug freeze + working bare-index cases),
  error paths ×8 (init-wizard exit 4 from a writable extracted tree + exit 3 via
  python3-only strip as committed exit goldens; MANDATORY gen-skills drift exit-1;
  sync-claude drift 2; checker 2; lint dual-mode), ingest mutating golden (tree channel
  load-bearing, frozen-`date` determinism, captured twice), release ×2 + requirements-sync
  ×3 (coverage-gap backfill). `tests/oracle-exempt.{md,txt}` registry live.
- [x] TEST-04: Complete
  — hashlib test asserts the op_hash VALUE from the confirmed channel;
  pdf-extract source-greps replaced by a local HTTP stub EFFECT assertion; the shim-level
  exit-3 contract test (manifest-driven per-shim loop) green;
  `tests/impl-assertion-inventory.md` classifies 12 entries (incl. 4 variable-indirected
  source-greps found during routing) with the discovery guard green.
- [x] TEST-05: Complete
  — `tests/conftest.py` fixtures behaviorally mirror
  `make_bare_repo`/`make_fixture_repo` (identity, `-b main`, gpgsign=false, README
  exclusion, fresh dir per call, unified SEED_MSG enforced against the bash source);
  `assert_golden_tree` + Ollama/network skipif markers; self-tests 5/5.

## Success criteria (ROADMAP Phase 24, 6 criteria)

1. **pip install -e . + pre-declared entry points** — TRUE (16 stubs, exit-70 sentinel, venv smoke).
2. **common/ over-extracted then frozen** — TRUE (6 modules; freeze guard live since `9f1093d`).
3. **invoke_tool seam, bash green baseline, py fallthrough** — TRUE (both legs of
   `run-all-suites.sh` exit 0; py green-by-fallthrough with the empty manifest).
4. **suites 09–20 wired into CI (re-derived: 09–24)** — TRUE (enumerated list + matrix + manifest).
5. **goldens frozen + coverage backfilled + anti-signal handled** — TRUE (33 case dirs;
   validate-op/search/error-exits/mutating covered; hashlib/pdf-extract rewritten; inventory+guard).
6. **pytest harness stood up** — TRUE (conftest fixtures + goldens helper + markers; 20 python
   tests green across packaging/extraction/conftest/CI-introspection).

## End-to-end validation (corrected post-review)

The claim originally recorded here — that the Plan-06 commit ran the gate live through the
hook — was FALSE: the code review found `core.hooksPath` pointing at the empty `.git/hooks`
(hooks disabled in this clone since April; no local commit ever ran the chain). What is
actually true after the review: hooks reinstalled (`core.hooksPath=.githooks`); the gate's
materialize/compare/block behaviors are proven by the behavior-level self-tests (which
execute the gate scripts directly, including the staged-broken-BLOCKED negative); the
divergence test drives the LIVE runner→seam→capture→compare path and catches an injected
byte; both full run-all legs + `--require-parity` were run explicitly and green; and the
REVIEW-FIX commit ran the real gated pre-commit chain end-to-end (freeze step with
FREEZE_ALLOW_REBASE per D-09, bash leg, empty-manifest short-circuit, lint --staged).
See 24-REVIEW.md findings #1/#2 for why this correction exists.

## Notable findings recorded during execution

- `search.sh` keyword/`--query`/`--paths-only` silently broken on piped-link indexes since
  Phase 14 (frozen as-is per the parity bar; todo filed).
- `tests/phase-09/test_lint_require_version.sh` is a pre-existing stale-pin FAIL (pinned).
- The N-4 loud-fail oracle guard and the freeze-guard tag-mismatch FATAL were both exercised
  live by tests (not just greps).

## Deviations

Documented per-plan in the six SUMMARYs; headline items: `invoke_tool_compat` routing form
(D-13-preserving), re-derived counts/pins per `24-REBASELINE.md`, release/requirements-sync
golden backfill, live-repo gen-skills test class kept direct + inventoried.
