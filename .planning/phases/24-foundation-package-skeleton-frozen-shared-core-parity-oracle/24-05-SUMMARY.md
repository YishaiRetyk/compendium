# Plan 24-05 Summary — CI wiring + parity matrix (wave 4)

**Executed:** 2026-07-03. **Requirements:** PKG-04, TEST-01, TEST-02. **Status:** Complete.

## What shipped

- **Seam routing (228 sites / 141 files, suites 09–23):** every direct `bash "$REPO_ROOT/bin/<tool>.sh"`
  call routed through the seam. Mechanism deviation (documented): the real call shapes span
  if-conditions, `||`-lists, and env-prefixed cd-subshell command substitutions — the plan's literal
  3-pattern rewrite would have rewritten assertions. Instead the seam gained **`invoke_tool_compat`**
  (direct-call semantics — payload→stdout, diagnostics→stderr, tool's own exit — over the full
  seam path: WIKI_IMPL branch + worktree oracle + IT_CAPTURE_DIR self-record), and the router
  substituted the invocation token only. D-13 held: zero assertions rewritten.
  **Per-test results verified IDENTICAL to the pre-routing baseline (205 tests: 195 PASS / 10
  pinned FAIL)** — the one delta, `test_lint_workflow`, is the PLANNED workflow-content change
  (its assertion updated from `pip install pyyaml` to `pip install -e .`).
- **Routing repairs found + fixed at execute time:** (a) six file-existence checks
  (`test -x`/`[ -f` on bin paths) mangled by the router → restored + `# noqa: direct-bin`;
  (b) six path-variable assignments hiding SOURCE-GREPS behind variable indirection →
  restored + noqa + **4 new impl-assertion-inventory rows** (the mechanical discovery cannot see
  `grep … "$VAR"`); (c) the 4 phase-18 gen-skills tests are LIVE-REPO state-dependent (the
  `$0`-relative class — routing them made the drift test regenerate the WORKTREE's skills and
  leak a real-repo mutation, caught + reverted) → direct calls + noqa + inventory row;
  (d) two self-contained tests (mask_fences, linkres) lacked the seam source → added.
- `tests/lib/no-direct-bin-calls.sh` — the routing gate (3 direct-call shapes, noqa-aware),
  also run inside run-all. Clean.
- `tests/phase-15/run.sh` — the missing aggregator (13 tests).
- `tests/SUITE_MANIFEST.txt` — pinned per-test baseline (206 rows; 10 pinned FAILs, all the
  stale prior-phase AGENTS-section/docs class).
- `tests/run-all-suites.sh` — enumerated list `09 09.1 10 11 12.1 12.2 13 15 18 20 22 23 24`
  (RB-5: real 22/23 join; missing suite = LOUD failure); per-test no-regression vs the manifest;
  `--capture-channels` (one IT_CAPTURE_DIR per suite, Plan 03's collision-proof key);
  `--require-parity` with pid-stripped pairing + unpaired-key failure + zero-pairs-is-failure
  (cycle-6 #4) + machine-readable `tests/oracle-exempt.txt` consumption with `EXEMPT:` audit
  lines (MEDIUM b); `--exclude-test`/`WIKI_PARITY_EXCLUDE_TESTS` + `--only-suite`/
  `WIKI_PARITY_ONLY_SUITES` knobs with the documented combination rule (cycle-6 #1/#3).
- **Coverage-gap backfill (cycle-4 #1 per-tool coverage):** the census found `release` and
  `requirements-sync` with ZERO behavioral coverage → new
  `tests/phase-24/test_release_reqsync_characterization.sh` + 5 goldens (release usage exit 1 +
  the deterministic dry-run allowlist plan; requirements-sync advisory/`--strict` drift exit 2/
  `--require-complete` exit 2 against a `--root` fixture).
- `tests/test_routed_parity_divergence.sh` — the LIVE-path test: a scaffold git repo (committed
  bash faketool = oracle; working-tree shim→python = py lane; **scaffold baseline pinned in
  `tests/freeze-baseline.sha` because the N-4 loud-fail fired live on the unpinned non-empty
  manifest — the guard works**) run through `run-all --only-suite` on both legs; injected
  one-byte divergence CAUGHT via `--require-parity`; identical bytes pass; per-routed-tool
  behavioral coverage asserted for all 16 tools.
- **CI:** 3 workflows now `pip install -e .` (pinned deps); `skills-check` gains
  setup-python + install (HIGH#10); new `parity.yml` — `parity-suites (bash|py)` matrix +
  `parity-equivalence` (capture both legs + byte-compare), Python 3.14 on new jobs (RB-2),
  poppler/jq installed, seam self-tests as a step; no required name touched/matrixed.
- `tests/test_ci_required_checks.py` — 5 introspection tests (names exact, no matrix on
  required jobs, matrix+equivalence jobs present, installs everywhere, suites 22/23/24
  enumerated + channel comparison present). 5/5 green.

## Verification

`WIKI_IMPL=bash bash tests/run-all-suites.sh` → OK (no new regression);
`WIKI_IMPL=py …` → OK (green-by-fallthrough); routing gate clean; divergence test green
(catch + inverse + 16-tool coverage); 4 workflow YAMLs parse; introspection 5/5;
`git diff bin/` empty; per-test before/after routing identical.

## Deviations from plan

- `invoke_tool_compat` routing form (above) — same seam guarantees, zero assertion rewrites.
- The plan's suite list `…20 22` re-derived to `…20 22 23 24` (RB-5).
- release/requirements-sync goldens added (the per-tool coverage assertion would otherwise fail
  truthfully — the gap was real).
- phase-18 gen-skills tests remain direct-with-noqa (live-repo class) — inventoried.
