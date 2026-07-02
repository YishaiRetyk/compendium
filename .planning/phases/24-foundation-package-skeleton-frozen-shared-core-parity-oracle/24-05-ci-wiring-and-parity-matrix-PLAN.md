---
phase: 22-foundation-package-skeleton-frozen-shared-core-parity-oracle
plan: 05
type: execute
wave: 4
depends_on: [01, 04]
files_modified:
  - .github/workflows/lint.yml
  - .github/workflows/neutrality.yml
  - .github/workflows/setup-parity.yml
  - .github/workflows/parity.yml
  - tests/phase-15/run.sh
  - tests/SUITE_MANIFEST.txt
  - tests/run-all-suites.sh
  - tests/lib/no-direct-bin-calls.sh
  - tests/test_ci_required_checks.py
  - tests/test_routed_parity_divergence.sh
  - tests/phase-09/
  - tests/phase-10/
  - tests/phase-11/
  - tests/phase-12.1/
  - tests/phase-12.2/
  - tests/phase-13/
  - tests/phase-15/
  - tests/phase-18/
  - tests/phase-20/
  - tests/phase-24/
  - tests/phase-09.1/
autonomous: true
requirements: [PKG-04, TEST-01, TEST-02]
user_setup: []

must_haves:
  decisions:
    - "D-06: CI runs on a single Python version (3.12) — no version matrix"
    - "D-14: the WIKI_IMPL=[bash,py] CI matrix is wired now, in Phase 24 (py green-by-fallthrough)"
  truths:
    - "the 3 existing workflows install the package via pip install -e . (additive) AND the required skills-check job installs the package; the 6 required-check names are unchanged"
    - "EVERY direct bash bin/<tool>.sh call in the parity suites is mechanically replaced with invoke_tool, and a gate REJECTS any remaining direct bin/<tool>.sh call in the parity suites (preserves cycle-1 HIGH#4-routing resolution)"
    - "phase-15 (tests but no run.sh) gets a run.sh AND phase-24 (the richest 4-channel goldens) is ADDED to the enumerated required-suite list `09 09.1 10 11 12.1 12.2 13 15 18 20 22` — explicit, not directory-discovered (addresses REVIEWS HIGH#5; preserves cycle-1 HIGH#7)"
    - "run-all-suites.sh --capture-channels propagates IT_CAPTURE_DIR per suite so EACH routed invoke_tool call self-records its normalized stdout/stderr/exit + tree snapshot into a COLLISION-PROOF keyed dir (Plan 03 keys by testbasename+pid+counter, so two distinct test files in one suite sharing the per-suite IT_CAPTURE_DIR do NOT overwrite each other — addresses REVIEWS cycle-3 HIGH finding #2 + cycle-4 finding #1, consumes Plan 03's collision-proof IT_CAPTURE_DIR contract)"
    - "run-all-suites.sh --require-parity BASH_DIR PY_DIR cmp/diffs the keyed channel files across bash and py per routed suite (byte-for-byte), so a port that changes user-visible bytes while keeping per-test PASS/FAIL identical FAILS parity (addresses REVIEWS HIGH#4 / cycle-3 finding #2 / TEST-01)"
    - "CYCLE-6 fix #4: --require-parity PAIRS the two --capture-channels runs by the PID-STRIPPED identity <suite>/<testbasename>/<tool>-<NN> (the on-disk <testbasename>-<pid> segment has a different pid per run), and FAILS on any UNPAIRED key (a zero-pairs walk over a non-empty capture set is a FAILURE) — so the comparison can no longer pass vacuously because the two runs' PIDs never matched"
    - "CYCLE-6 fix #1/#3: run-all-suites.sh gains a caller-supplied TEST-level exclusion knob (--exclude-test <basename> / WIKI_PARITY_EXCLUDE_TESTS) added BEFORE the Plan-06 freeze so Plan 06 CONSUMES it; the hook fallback excludes ONLY the recursive hook self-tests (test_precommit_hooks.sh, test_staged_parity_index.sh), NOT the whole phase-24 suite — every phase-24 golden still runs on the private-branch gate (resolves the cycle-5 freeze/interface deadlock + the whole-suite-drop regression)"
    - "CYCLE-6 MEDIUM a: per-routed-tool coverage requires ≥1 BEHAVIORAL (non-usage) captured invocation — a shallow --help/-h/no-arg usage path does not satisfy coverage"
    - "CYCLE-6 MEDIUM b: --require-parity consumes the MACHINE-READABLE tests/oracle-exempt.txt (a captured pairing key maps to its exemption via a pattern match), not ad-hoc matching against the prose oracle-exempt.md"
    - "the PRE-FIX-FAILING behavioral test (tests/test_routed_parity_divergence.sh) drives the LIVE run-all -> child test_*.sh -> invoke_tool -> capture_footprint path end-to-end (NOT a hand-built comparator-only channel dir): it runs a routed suite under --capture-channels for two impls (a stub ported tool that emits a divergent byte on one impl) and byte-cmps the captured channel files, asserting --require-parity EXITS NON-ZERO; AND it asserts every routed tool has golden coverage (addresses REVIEWS cycle-3 HIGH finding #2 + cycle-4 finding #1 — live byte-cmp path + per-tool coverage, no comparator stub)"
    - "per-routed-tool golden coverage is ASSERTED: every routed tool (audit-claims, brownfield, release, pdf-extract, requirements-sync — not just one) has phase-24 golden coverage / a captured channel under the parity net, so sparse-tool parity is not hollow (addresses REVIEWS cycle-4 finding #1 / Codex new-HIGH #1 — per-tool coverage)"
    - "oracle-exempt paths (tests/oracle-exempt.md, Plan 04) are NOT treated as parity-verifiable by the matrix — run-all/--require-parity skips or annotates them so the matrix does not silently claim parity for an unverifiable path (addresses REVIEWS cycle-3 finding #1 ripple)"
    - "the baseline is a PER-TEST result manifest (not suite-level GREEN/RED): run-all fails on ANY new per-test failure AND on any cross-impl channel byte-divergence"
    - "WIKI_IMPL=py is green-by-fallthrough in Phase 24 (ported.manifest empty); the matrix lights up per-port in Phase 25 with zero CI edits"
  artifacts:
    - path: ".github/workflows/parity.yml"
      provides: "New parity-suites (bash) / parity-suites (py) jobs running the enumerated suites (incl. 22) with the WIKI_IMPL matrix + a parity-equivalence job comparing channels byte-for-byte"
      contains: "WIKI_IMPL"
    - path: "tests/SUITE_MANIFEST.txt"
      provides: "Per-test result manifest (test-id -> PASS/FAIL) + explicit required-suite enumeration incl. phase-24 (no-regression baseline)"
    - path: "tests/run-all-suites.sh"
      provides: "Enumerated runner (incl. 22) + per-test no-regression check + --capture-channels (propagates IT_CAPTURE_DIR per suite, Plan 03's collision-proof key) + --require-parity CHANNEL byte-comparison across impls (REVIEWS HIGH#4 / cycle-3 finding #2)"
    - path: "tests/test_routed_parity_divergence.sh"
      provides: "PRE-FIX-FAILING behavioral test driving the LIVE run-all->child->invoke_tool->capture path: a routed-suite byte divergence (stub ported tool, one impl differs) makes --require-parity exit non-zero; identical captures pass; AND per-routed-tool golden coverage asserted (REVIEWS cycle-3 HIGH finding #2 + cycle-4 finding #1)"
      contains: "require-parity"
    - path: "tests/lib/no-direct-bin-calls.sh"
      provides: "Gate that rejects any remaining direct bin/<tool>.sh call in the parity suites"
    - path: "tests/phase-15/run.sh"
      provides: "The missing phase-15 aggregator"
    - path: "tests/test_ci_required_checks.py"
      provides: "PKG-04/TEST-01/TEST-02 introspection: 6 required names + no matrix + skills-check installs package + suites (incl. 22) wired + channel-comparison present"
  key_links:
    - from: ".github/workflows/lint.yml skills-check"
      to: "pip install -e ."
      via: "setup-python + install step added to the skills-check job"
      pattern: "pip install -e \\."
    - from: "tests/run-all-suites.sh --capture-channels"
      to: "IT_CAPTURE_DIR (Plan 03 seam) -> per-call COLLISION-PROOF keyed channel files"
      via: "export IT_CAPTURE_DIR=<out>/<suite> before running each suite; every routed invoke_tool call self-records under testbasename+pid+counter"
      pattern: "IT_CAPTURE_DIR"
    - from: "tests/run-all-suites.sh"
      to: "tests/SUITE_MANIFEST.txt + the captured channel maps"
      via: "per-test result comparison + cross-impl channel byte-comparison"
      pattern: "SUITE_MANIFEST"
---

<objective>
Wire all phase suites (09-20 PLUS phase-24) into CI as NEW jobs under a `WIKI_IMPL=[bash,py]` matrix, install the package additively in the 3 existing workflows AND in the required `skills-check` job, mechanically route every direct `bash bin/<tool>.sh` call in the parity suites through the frozen `invoke_tool` seam, add a gate rejecting any remaining direct call, add the missing `phase-15/run.sh`, and replace the suite-level GREEN/RED baseline with a PER-TEST result manifest that fails on any new failure AND a `--require-parity` mode that compares the CAPTURED stdout/stderr/exit/tree CHANNELS byte-for-byte across bash and py — collecting those channels from BLACK-BOX child test subprocesses via Plan 03's collision-proof `IT_CAPTURE_DIR` per-call self-record, and proving the comparison catches a routed divergence with a pre-fix-failing behavioral test that drives the LIVE path (not a comparator stub).

Purpose (PKG-04/TEST-01/TEST-02/D-14): The parity net must be ENFORCED byte-for-byte, not nominal. CYCLE-2 + CYCLE-3 + CYCLE-4 REVIEWS:
- CYCLE-3 HIGH finding #2 (routed-suite byte-for-byte capture under-specified): `run-all-suites.sh` runs each `test_*.sh` as a BLACK-BOX SUBPROCESS and has NO handle to the child's shell-local `IT_STDOUT/IT_STDERR/IT_EXIT`, invocation count, or `make_*_repo` fixture working dir — so the cycle-2 `--capture-channels` (which "reuses capture_footprint" needing a `<repo>` arg run-all does not possess) could NOT record per-test channels for routed suites, and there was NO pre-fix-failing test that injects a routed divergence and proves `--require-parity` catches it. This plan PINS the mechanism: Plan 03's `invoke_tool` honors `IT_CAPTURE_DIR` and self-records EACH call's channels (normalized stdout/stderr/exit + a tree snapshot of the test's cwd) into a keyed sub-dir; run-all `--capture-channels <dir>` EXPORTS `IT_CAPTURE_DIR=<out>/<suite>` before running each suite so every routed `invoke_tool` call self-records with NO `<repo>` arg from run-all; `--require-parity <bash-dir> <py-dir>` `cmp`/`diff`s the keyed channel files.
- CYCLE-2 HIGH#4 (cycle-1 HIGH#4 — TEST-01 byte-parity): the prior `--require-parity` compared only per-test PASS/FAIL across impls, with NO general mechanism comparing the captured channels for routed suites. So a port that changes user-visible BYTES while keeping a thin assertion green PASSED. The IT_CAPTURE_DIR mechanism + the cross-impl CHANNEL byte-comparison + the catch-a-divergence test close this.
- CYCLE-2 HIGH#5: the prior enumerated suite list `09 09.1 10 11 12.1 12.2 13 15 18 20` OMITTED `22`. This plan ADDS `22` to the list, run-all, and the introspection test (kept explicit — NOT a glob).
- CYCLE-3 finding #1 ripple: Plan 04 produces `tests/oracle-exempt.md` listing parity-EXEMPT paths (init-wizard exit-4 / the $0-relative state-dependent class). run-all/--require-parity must NOT treat those as parity-verifiable.
- CYCLE-4 finding #1 / Codex new-HIGH #1 (the routed-capture RESIDUAL — both reviewers): TWO localized defects in the otherwise-correct cycle-3 capture mechanism:
  (a) **capture-key collision (seam-side fix in Plan 03; wiring-side correctness here):** the cycle-3 seam keyed by `tool + per-PROCESS counter`, which collides across distinct test files sharing the per-suite `IT_CAPTURE_DIR` run-all exports. Plan 03 now keys by `<testbasename>-<pid>/<tool>-<counter>` (collision-proof). This plan's run-all STILL exports ONE `IT_CAPTURE_DIR=<out>/<suite>` per suite (the per-test-file discriminator lives in the key, not in a per-test dir), so NO coverage is dropped when two test files in one suite both record the first `lint` call. Document this: run-all relies on Plan 03's collision-proof key — it does NOT need a per-test sub-dir.
  (b) **the divergence test must drive the LIVE path + per-tool coverage asserted:** the cycle-3 `test_routed_parity_divergence.sh` built channel dirs MANUALLY (tested the comparator, not the live `run-all -> child -> invoke_tool -> capture` path; the live path was only "(Optional, stronger)"). Reviewers REJECT the comparator-only stub. This plan makes the LIVE path the REQUIRED form: a stub "ported" tool whose py module emits one different byte, run through a routed suite under `--capture-channels` for both impls, then `--require-parity` over the two REAL capture dirs — asserting it exits non-zero. AND it asserts per-routed-tool golden coverage EXISTS for every routed tool (audit-claims, brownfield, release, pdf-extract, requirements-sync — not just one).
Plus the preserved cycle-1 resolutions: the mechanical seam routing + no-direct-call gate (HIGH#4-routing), the phase-15 runner (HIGH#7), the skills-check package install (HIGH#10), and the per-test manifest (HIGH#6).

Output: edited `lint.yml`/`neutrality.yml`/`setup-parity.yml` (additive install + skills-check install), new `parity.yml` (matrix jobs incl. phase-24), `tests/phase-15/run.sh`, `tests/SUITE_MANIFEST.txt` (per-test manifest + enumerated suite list incl. 22), `tests/run-all-suites.sh` (with IT_CAPTURE_DIR-fed channel byte-comparison), `tests/test_routed_parity_divergence.sh` (the LIVE-path catch-a-divergence + per-tool-coverage behavioral test), `tests/lib/no-direct-bin-calls.sh`, `tests/test_ci_required_checks.py`, and the seam-routed parity suites.

CRITICAL: D-13 — route invocations, rewrite NO assertions, leave the 12 `make_*_repo` helpers untouched. The `WIKI_IMPL=bash` path MUST stay byte-identical (validate with the Plan-03 self-parity guard). Several suites are RED at HEAD (phase-07/09/10/11/13); the per-test manifest pins their CURRENT per-test results — "wire" does NOT mean "make them green." No task scopes "make suite-NN pass."

This plan depends on Plan 01 (pyproject for `pip install -e .` + `tests/ported.manifest` for the seam) and Plan 04 (which adds `tests/phase-24/` + `tests/oracle-exempt.md` and mutates phase-11/20 tests — the per-test manifest must be measured AFTER those land; phase-24 is now an enumerated suite). It consumes Plan 03's collision-proof `IT_CAPTURE_DIR` per-call self-record contract.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-CONTEXT.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md
@.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md

<interfaces>
<!-- The 6 FROZEN required-check names (branch-protection contract; NEVER rename, NEVER matrix): -->
lint, privacy-leak, strict, skills-check   @ .github/workflows/lint.yml (jobs at lines 33/54/71/89)
neutrality                                  @ .github/workflows/neutrality.yml (job at line 29)
setup-parity                                @ .github/workflows/setup-parity.yml (job at line 28)

<!-- CONFIRMED: the skills-check job (lint.yml ~89-103) has NO setup-python and NO pip install --
     it currently just runs `bash bin/gen-skills.sh --check`. Once gen-skills.sh becomes a python
     shim it fails without a package install. Add setup-python + pip install -e . to it. -->

<!-- Existing CI install pattern (lint.yml ~36-43/60-65/81-85): checkout@v6 -> setup-python@v6
     ('3.12', D-06 no matrix) -> `pip install pyyaml` (or `pip install pyyaml ruamel.yaml`).
     These become `pip install -e .` (pulls pinned deps from pyproject). -->

<!-- Suites that EXIST + run.sh status (CONFIRMED this session): -->
07,08 (already gate),09,09.1,10,11,12.1,12.2,13,18,20 have run.sh ; phase-15 has tests but NO run.sh ;
phase-24 is CREATED by Plan 04 (run.sh + characterization + error-path + mutating + inventory-guard tests).
<!-- 14/16/17/19 do NOT exist. The required-suite list is the ENUMERATED set, NOT a directory glob.
     The enumerated list (REVIEWS HIGH#5 — INCLUDES 22): 09 09.1 10 11 12.1 12.2 13 15 18 20 22. -->

<!-- The Plan-03 seam channel mechanism (the basis for the byte-for-byte channel comparison — REVIEWS HIGH#4 / cycle-3 finding #2 / cycle-4 finding #1):
     invoke_tool sets IT_STDOUT (path), IT_STDERR (path), IT_EXIT (value); capture_footprint <repo> <case-dir>
     writes <case-dir>/{stdout,stderr,exit,tree}; AND when IT_CAPTURE_DIR is set, EACH invoke_tool call SELF-RECORDS
     its channels into $IT_CAPTURE_DIR/<testbasename>-<pid>/<tool>-<NN>/{stdout,stderr,exit,tree} — keyed by a
     COLLISION-PROOF testbasename+pid discriminator + per-call counter (cycle-4 finding #1: a bare per-process
     counter would collide across distinct test files sharing one IT_CAPTURE_DIR).
     THIS is how run-all collects per-call channels from a black-box child test subprocess:
     run-all exports IT_CAPTURE_DIR=<out>/<suite> per suite (ONE per-suite dir — the per-test-file discriminator
     lives in the key, so no coverage is dropped); every routed invoke_tool call self-records there. -->

<!-- The Plan-04 oracle-exempt registry (cycle-3 finding #1 ripple + cycle-6 MEDIUM b): -->
tests/oracle-exempt.md   -> HUMAN prose: parity-EXEMPT paths (init-wizard exit-4 / $0-relative state-dependent class) with the WHY.
tests/oracle-exempt.txt  -> MACHINE-READABLE companion (Plan 04): one exemption per non-comment line as `<pattern>` (tool name
                            like `init-wizard`, or a pairing-key glob like `*/init-wizard-*`) + optional TAB reason. --require-parity
                            READS THIS .txt (not the prose .md) and SKIPs matching pairing keys, printing `EXEMPT: <key> (<reason>)`.

<!-- ROUTED TOOLS that must have asserted golden coverage (cycle-4 finding #1 / Codex new-HIGH #1 — per-tool coverage):
     audit-claims, brownfield, release, pdf-extract, requirements-sync (the script-relative / long-pole routed tools),
     plus the validate-op/search/sync-claude/gen-skills/lint/checkers covered by Plan 04's goldens. The divergence test
     asserts EVERY routed tool has a captured channel / golden under the parity net — not just one tool. -->

<!-- VERIFIED current bash baseline at HEAD (Pitfall 7 — pin per-test, not suite-level): -->
phase-07 = RED ; phase-09 = RED ; phase-09.1 = GREEN ; phase-10 = RED ; phase-11 = RED ; phase-13 = RED
<!-- (re-measure ALL suites per-test at execute time after Plan 04 lands.) -->

<!-- CONFIRMED direct-call shape in the parity suites (call sites are in test_*.sh, NOT lib.sh):
     dominant: `bash "$REPO_ROOT/bin/<tool>.sh"` (193 sites); variants `"$REPO_ROOT/bin/<tool>.sh"` (38),
     `bash $REPO_ROOT/bin/<tool>.sh` (4). Sourcing invoke_tool into lib.sh does NOT intercept these. -->

<!-- Suite aggregator unit a CI step invokes: bash tests/phase-NN/run.sh (iterates test_*.sh, exits non-zero on any failure). -->
<!-- The existing 07-08 suite-runner block precedent: setup-parity.yml lines 47-54. -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: phase-15/run.sh + add 22 to the enumerated list + mechanically route direct bin calls + no-direct-call gate + per-test manifest + run-all with IT_CAPTURE_DIR-fed cross-impl CHANNEL byte-comparison + a LIVE-path catch-a-routed-divergence + per-tool-coverage behavioral test</name>
  <files>tests/phase-15/run.sh, tests/lib/no-direct-bin-calls.sh, tests/SUITE_MANIFEST.txt, tests/run-all-suites.sh, tests/test_routed_parity_divergence.sh, tests/phase-09/, tests/phase-10/, tests/phase-11/, tests/phase-12.1/, tests/phase-12.2/, tests/phase-13/, tests/phase-15/, tests/phase-18/, tests/phase-20/, tests/phase-24/, tests/phase-09.1/</files>
  <read_first>
    - tests/phase-09/run.sh + tests/phase-10/run.sh (the aggregator shape — iterate test_*.sh, tally, exit non-zero on any failure; mirror for phase-15/run.sh)
    - tests/phase-24/run.sh (from Plan 04 — the new phase-24 aggregator that MUST be added to the enumerated list — REVIEWS HIGH#5)
    - tests/phase-09/test_lint_ci_mode.sh + tests/phase-10/test_brownfield_bootstrap_apply_clean.sh (the direct-call sites: `bash "$REPO_ROOT/bin/<tool>.sh" args... >out 2>err; rc=$?` — the EXACT shape to replace with invoke_tool)
    - tests/phase-15/ (the 13 test_*.sh files with no run.sh — read enough to write the aggregator)
    - tests/lib/invoke_tool.sh (Plan 03 — the seam: invoke_tool sets IT_STDOUT/IT_STDERR/IT_EXIT, ALWAYS returns 0; capture_footprint writes <case>/{stdout,stderr,exit,tree}; AND honors IT_CAPTURE_DIR, self-recording into $IT_CAPTURE_DIR/<testbasename>-<pid>/<tool>-<NN>/... — the COLLISION-PROOF key, cycle-4 finding #1. Replace `bash bin/X.sh a b >o 2>e; rc=$?` with `invoke_tool X a b; rc=$IT_EXIT; cp "$IT_STDOUT" o; cp "$IT_STDERR" e`)
    - tests/oracle-exempt.md + tests/oracle-exempt.txt (Plan 04 — the prose registry + its MACHINE-READABLE companion; --require-parity consumes the .txt patterns to SKIP exempt pairing keys — cycle-3 finding #1 ripple + cycle-6 MEDIUM b)
    - tests/ported.manifest (Plan 01 — the seam reads it; empty in P22 so py==bash; the divergence test temporarily seeds a stub ported tool)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (HIGH#4 [byte-for-byte CHANNEL comparison in --require-parity, not just PASS/FAIL], cycle-3 finding #2 [IT_CAPTURE_DIR per-call collection from black-box children + a catch-a-divergence behavioral test], HIGH#5 [add 22 to the enumerated list], cycle-4 finding #1 [collision-proof per-suite IT_CAPTURE_DIR + LIVE divergence test + per-tool coverage]; CYCLE-6 fixes #1/#3 [add the --exclude-test/WIKI_PARITY_EXCLUDE_TESTS TEST-level exclusion knob BEFORE the freeze], #4 [--require-parity pairs by the pid-STRIPPED it_pairing_key + fails on unpaired keys], MEDIUM a [≥1 behavioral non-usage case per routed tool], MEDIUM b [consume the machine-readable tests/oracle-exempt.txt]; + the preserved cycle-1 HIGH#2-routing/HIGH#7-phase15)
  </read_first>
  <action>
**Add the missing `phase-15/run.sh`.** Create `tests/phase-15/run.sh` as a `test_*.sh` aggregator mirroring `tests/phase-09/run.sh` (iterate the 13 `tests/phase-15/test_*.sh`, run each, tally PASS/FAIL, exit non-zero on any failure). Make it executable.

**Define the required-suite list EXPLICITLY and INCLUDE phase-24 (REVIEWS HIGH#5 — enumerate, do not glob).** In `tests/run-all-suites.sh` and `tests/SUITE_MANIFEST.txt`, the set of suites is an EXPLICIT enumerated list, not a `tests/phase-*/` directory discovery. The enumerated list is exactly: `09 09.1 10 11 12.1 12.2 13 15 18 20 22` — note the trailing `22` (Plan 04's richest 4-channel golden suite; OMITTED before, ADDED now — REVIEWS HIGH#5). (07/08 already gate via setup-parity.yml; they may be included for completeness but the TEST-02 target is 09-22.) Hard-code this list in `run-all-suites.sh` so a future missing/renamed suite is a LOUD failure, not a silently-skipped glob miss.

**Mechanically route every direct bin call through invoke_tool (preserves cycle-1 HIGH#4-routing).** The direct `bash bin/<tool>.sh` calls live in the `test_*.sh` files, not `lib.sh`. For each parity suite (09, 09.1, 10, 11, 12.1, 12.2, 13, 15, 18, 20, 22): (1) have its `lib.sh` `source "$REPO_ROOT/tests/lib/invoke_tool.sh"`; (2) MECHANICALLY rewrite every direct invocation in the `test_*.sh` files from the direct form to the seam form. The rewrite is a deterministic transform of the three confirmed shapes:
- `bash "$REPO_ROOT/bin/<tool>.sh" ARGS >OUT 2>ERR; rc=$?` → `invoke_tool <tool> ARGS; rc=$IT_EXIT; cp "$IT_STDOUT" OUT; cp "$IT_STDERR" ERR`. Where the original captured into a var via `$(bash "$REPO_ROOT/bin/<tool>.sh" ...)`, rewrite to `invoke_tool <tool> ...; OUT="$(cat "$IT_STDOUT")"`.
- `"$REPO_ROOT/bin/<tool>.sh" ARGS` (no leading `bash`) and `bash $REPO_ROOT/bin/<tool>.sh ARGS` (unquoted) → same `invoke_tool <tool> ARGS` form.
Do NOT change any ASSERTION (D-13) — only the invocation layer. Do NOT touch any `make_bare_repo`/`make_fixture_repo` body. Because the seam returns 0 with status via `$IT_EXIT` (Plan 03 HIGH#2 fix), the `rc=$IT_EXIT` capture works even in `set -e` suites. After rewriting a suite, run it under `WIKI_IMPL=bash` and confirm it is at-or-above its prior per-test status (any NEW failure is a SEAM bug, not a baseline change).

**The no-direct-call gate.** Create `tests/lib/no-direct-bin-calls.sh` — scans the parity suites (incl. phase-24) for any REMAINING direct `bin/<tool>.sh` invocation and FAILS if found. It greps each parity suite's `test_*.sh` for the direct-call shapes (`bash "$REPO_ROOT/bin/`, `"$REPO_ROOT/bin/[a-z_-]*\.sh"` used as a command, `bash $REPO_ROOT/bin/`) and excludes legitimate non-invocation mentions (allow a `# noqa: direct-bin` inline marker for the rare legitimate source-read, documented). Print every offending file:line. Make it executable.

**Per-test result manifest.** Create `tests/SUITE_MANIFEST.txt` recording the CURRENT per-test result for every test in the enumerated suites (incl. phase-24), one line per test: `phase-NN/test_name PASS|FAIL`. Measure it by running each suite's `test_*.sh` individually under `WIKI_IMPL=bash` at HEAD (after Plan 04 landed). Header comment: FAIL entries are the PINNED current per-test state and are NOT in-scope to fix in v1.5.

**`tests/run-all-suites.sh` — per-test no-regression PLUS IT_CAPTURE_DIR-fed cross-impl CHANNEL byte-comparison (REVIEWS HIGH#4 / cycle-3 finding #2 / cycle-4 finding #1 / TEST-01).** A single entrypoint that, for the ENUMERATED suite list (incl. 22) under a given `WIKI_IMPL`:
1. Runs each test individually, builds a current per-test result map, and:
   - FAILS on ANY test that is PASS in `SUITE_MANIFEST.txt` but FAIL now (a new per-test regression).
   - FAILS on ANY new failing test absent from the manifest; a new PASSing test is fine (append to the manifest).
1b. **CALLER-SUPPLIED TEST-EXCLUSION KNOB (CYCLE-6 fix #1 + #3 — the frozen interface Plan 06 consumes).** run-all iterates the enumerated suites' `test_*.sh` individually, so it can SKIP specific TEST FILES by basename. Add a repeatable `--exclude-test <basename>` flag AND a `WIKI_PARITY_EXCLUDE_TESTS` env var (space/colon-separated basenames); when building the per-test iteration, run-all SKIPs any `test_*.sh` whose basename is in the union of the two exclusion sets (matched with or without the `.sh` suffix). This is a TEST-level exclusion, NOT a suite-level drop: phase-24 STAYS in the enumerated list so its richest 4-channel goldens still run — Plan 06's local hook fallback passes ONLY `--exclude-test test_precommit_hooks.sh --exclude-test test_staged_parity_index.sh` (the two recursive hook self-tests), so the gate does NOT re-enter itself while EVERY other phase-24 golden still executes (Codex cycle-4 finding: dropping the WHOLE phase-24 suite would remove the richest goldens from the only gate that runs on private migration branches — this knob avoids that). This knob is added HERE (wave 4), BEFORE the Plan-06 freeze snapshot (end of wave 4), so `tests/run-all-suites.sh` freezes WITH the knob and Plan 06 CONSUMES it — resolving the cycle-5 freeze/interface deadlock (the runner had no such parameter and was frozen). Print each skipped test as `SKIP (excluded): <suite>/<basename>` so exclusions are visible, and NEVER apply an exclusion in the plain (non-`--exclude-test`) CI matrix run — the CI parity-suites job runs the FULL enumerated set incl. all phase-24 tests.
1c. **CALLER-SUPPLIED SUITE-SELECTION KNOB (positive counterpart to --exclude-test — the concrete live-runner entry the divergence test uses).** Add a repeatable `--only-suite <suite-dir-or-name>` flag AND a `WIKI_PARITY_ONLY_SUITES` env var (space/colon-separated): when either is set, run-all iterates ONLY the caller-supplied suite(s) — which MAY be a scaffold suite path NOT in the hard-coded enumerated list (e.g. a throwaway `tests/phase-XX-divtest/`) — instead of the enumerated set, while still driving the FULL LIVE `run-all -> child test_*.sh -> invoke_tool -> capture_footprint` path (per-suite `IT_CAPTURE_DIR` export, per-test iteration, channel self-record) for the selected suite. This is the ONE documented mechanism `tests/test_routed_parity_divergence.sh` uses to run its throwaway routed suite through the LIVE runner (it does NOT hand-roll a separate `IT_CAPTURE_DIR`-exported invocation). The plain CI matrix run passes neither knob and always runs the full enumerated set. KNOB-COMBINATION CONTRACT (frozen-interface clarity for Phase-23 callers): the two knobs compose on independent axes — `--only-suite`/`WIKI_PARITY_ONLY_SUITES` selects the suite SET, and `--exclude-test`/`WIKI_PARITY_EXCLUDE_TESTS` still filters per-test-file WITHIN whichever suite set is active (the enumerated set by default, or the `--only-suite` selection when passed). State this combination rule in the run-all-suites.sh header usage comment (no current Phase-22 caller combines them; the rule exists so the frozen contract is unambiguous).
2. **CHANNEL CAPTURE from BLACK-BOX CHILD SUBPROCESSES via the COLLISION-PROOF IT_CAPTURE_DIR (the cycle-3 finding #2 + cycle-4 finding #1 fix — TEST-01).** run-all CANNOT see a child test's shell-local IT_* or its fixture dir. The mechanism (consuming Plan 03's collision-proof IT_CAPTURE_DIR contract): when run-all is invoked with `--capture-channels <out-dir>`, for each suite it EXPORTS `IT_CAPTURE_DIR="<out-dir>/<suite>"` (and `mkdir -p` it) BEFORE running that suite's `test_*.sh`, so EVERY routed `invoke_tool` call inside the black-box child self-records its normalized stdout/stderr/exit + a tree snapshot of the test's cwd into `<out-dir>/<suite>/<testbasename>-<pid>/<tool>-<NN>/{stdout,stderr,exit,tree}` — NO `<repo>` arg needed from run-all (the seam captures the call's own cwd, which IS the test's fixture dir). CYCLE-4 finding #1: run-all exports ONE `IT_CAPTURE_DIR` PER SUITE (not per test) — it does NOT need per-test sub-dirs because the seam's `<testbasename>-<pid>` key already disambiguates DIFFERENT test files in the SAME suite. So two test files in one suite both recording their first `lint` call land in DISTINCT keyed dirs and NEITHER is dropped. (Do NOT re-implement capture_footprint here — the seam does it; run-all only sets/propagates IT_CAPTURE_DIR and `mkdir`s the per-suite dir. Document that run-all relies on Plan 03's collision-proof key.)
3. **`--require-parity <bash-channel-dir> <py-channel-dir>` — CROSS-IMPL CHANNEL BYTE-COMPARISON with PID-INDEPENDENT PAIRING (REVIEWS HIGH#4 / cycle-3 finding #2 / CYCLE-6 fix #4).** Walks the keyed channel sub-dirs produced by two `--capture-channels` runs (one bash, one py) and `cmp`/`diff`s the channel files (stdout/stderr/exit/tree) for EACH keyed routed call. **The two runs are SEPARATE processes, so the on-disk top segment `<testbasename>-<pid>` has a DIFFERENT `<pid>` on each side (cycle-5 flaw: keying the comparison on the raw `<testbasename>-<pid>` finds NO matching pairs → vacuous green).** So `--require-parity` PAIRS captures by the PID-INDEPENDENT identity `<suite>/<testbasename>/<tool>-<NN>`, computed by STRIPPING the trailing `-<pid>` from each top segment (reuse Plan 03's `it_pairing_key`, or an equivalent inline `sed -E 's/-[0-9]+$//'`). Build a map keyed by the pid-stripped pairing identity for EACH side, then compare. FAILS on: (a) ANY channel byte mismatch in ANY paired routed call, AND (b) **any pairing key present on ONE side but MISSING on the other** (an unpaired key means the walk is NOT vacuous — it must have compared ≥1 real pair; a zero-pairs walk over a non-empty capture set is itself a FAILURE). NOT merely a PASS/FAIL comparison. This closes the byte-parity hole AND the cross-run alignment hole: a py impl that produces identical per-test PASS/FAIL but DIFFERENT bytes now FAILS parity, and the comparison can no longer pass vacuously because the PIDs never matched. Tie this explicitly to TEST-01 + cycle-3 finding #2 + cycle-6 fix #4 in a header comment.
4. **Honor the MACHINE-READABLE oracle-exempt registry (cycle-3 finding #1 ripple + CYCLE-6 MEDIUM b).** The human registry `tests/oracle-exempt.md` is prose; the cycle-5 gate had NO machine-readable mapping from a captured call to its exemption, so `--require-parity`'s exempt-skipping relied on ad-hoc path matching. Plan 04 now also emits `tests/oracle-exempt.txt` — a MACHINE-READABLE companion, one exemption per non-comment line as `<pattern>` (a tool name like `init-wizard`, or a pairing-key glob like `*/init-wizard-*`) optionally followed by a TAB + reason. `--require-parity` READS `tests/oracle-exempt.txt` and, for each pairing key, if the key's tool name OR the pairing path matches any pattern, SKIPs it (does NOT count a divergence there as a parity FAIL) and prints an annotated `EXEMPT: <key> (<reason>)` line so the skip is auditable, not silent. Document that oracle-exempt entries are compat-boundary documentation, not bash-vs-py diffs; the `.txt` is the consumed form and MUST stay consistent with the `.md` prose (Plan 04 authors both).
Header:
```bash
#!/usr/bin/env bash
# Usage: WIKI_IMPL=bash bash tests/run-all-suites.sh                              (per-test no-regression vs SUITE_MANIFEST.txt)
#        WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels DIR       (exports IT_CAPTURE_DIR=DIR/<suite> per suite; each routed invoke_tool self-records under a collision-proof testbasename+pid+counter key)
#        bash tests/run-all-suites.sh --require-parity BASH_DIR PY_DIR            (PAIRS captures by the pid-STRIPPED <suite>/<testbasename>/<tool>-<NN> identity; FAILS on ANY channel byte-divergence AND on any unpaired key — REVIEWS HIGH#4 / cycle-3 finding #2 / cycle-6 fix #4 / TEST-01)
#        WIKI_IMPL=bash bash tests/run-all-suites.sh --exclude-test test_precommit_hooks.sh   (TEST-level exclusion for Plan 06's hook fallback; phase-24 stays in the suite list — cycle-6 fix #1/#3)
#        WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels DIR --only-suite tests/phase-XX-divtest   (run ONLY a caller-supplied suite — incl. a scaffold suite outside the enumerated list — through the LIVE runner; the single mechanism tests/test_routed_parity_divergence.sh uses)
# Enumerated suites (NOT a glob — REVIEWS HIGH#5 INCLUDES 22): 09 09.1 10 11 12.1 12.2 13 15 18 20 22.
# Channel capture relies on Plan 03's COLLISION-PROOF key (testbasename+pid+counter) so distinct test files
# in one suite sharing IT_CAPTURE_DIR=<DIR>/<suite> do NOT overwrite each other (cycle-4 finding #1); --require-parity
# STRIPS the -<pid> to pair the two runs' captures (cycle-6 fix #4 — the PIDs differ across the bash and py runs).
# --exclude-test <basename> / WIKI_PARITY_EXCLUDE_TESTS skip specific TEST FILES (NOT whole suites) so Plan 06's
# hook fallback drops ONLY the recursive hook self-tests while keeping every phase-24 golden (cycle-6 fix #1/#3).
# Knob combination: --exclude-test filters per-test-file WITHIN whichever suite set is active — the enumerated
# set by default, or the --only-suite selection when passed (independent axes; combining both is well-defined).
# oracle-exempt paths (machine-readable tests/oracle-exempt.txt) are NOT parity-verifiable — skipped/annotated (cycle-3 finding #1 ripple + cycle-6 MEDIUM b).
```
Make it executable. Also run `tests/lib/no-direct-bin-calls.sh` from within (or alongside) run-all so the seam-routing invariant is enforced on every CI run.

**`tests/test_routed_parity_divergence.sh` — the PRE-FIX-FAILING LIVE-path catch-a-routed-divergence + per-tool-coverage behavioral test (REVIEWS cycle-3 HIGH finding #2 + CYCLE-4 finding #1).** Reviewers REJECT a comparator-only stub / hand-built channel dirs. This test MUST drive the LIVE `run-all -> child test_*.sh -> invoke_tool -> capture_footprint` path and byte-`cmp` the REAL captured channels:
1. **LIVE divergence injection through the real seam (the REQUIRED form — cycle-4 finding #1):** in an isolated scaffold, add a stub "ported" tool to a temporary `tests/ported.manifest` whose py module emits ONE different byte on stdout vs the bash oracle (e.g. a `faketool` with a bash oracle body printing `OK\n` and a `src/compendium/faketool.py` printing `OK \n` — one trailing-space byte). Author a tiny throwaway routed suite (`tests/phase-XX-divtest/test_div.sh`) that `invoke_tool faketool` once. Run `WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels "$BASH_DIR" --only-suite tests/phase-XX-divtest` — the `--only-suite` knob added above drives JUST that throwaway suite through the LIVE `run-all -> child test_*.sh -> invoke_tool -> capture_footprint` path (this is the SINGLE concrete invocation mechanism; do NOT hand-roll a separate `IT_CAPTURE_DIR`-exported invocation) — then `WIKI_IMPL=py bash tests/run-all-suites.sh --capture-channels "$PY_DIR" --only-suite tests/phase-XX-divtest`. Then `bash tests/run-all-suites.sh --require-parity "$BASH_DIR" "$PY_DIR"` and assert it EXITS NON-ZERO — the injected one-byte stdout divergence is CAUGHT via the LIVE captured channels (NOT hand-built dirs). Clean up the temp manifest entry + throwaway suite on all exit paths (trap).
2. **Identical captures pass (the inverse):** with the stub py module emitting the SAME bytes as the bash oracle (or faketool absent from the manifest so both legs run the oracle), run the two `--capture-channels` legs and assert `--require-parity` EXITS 0 (identical live captures pass).
3. **PER-ROUTED-TOOL coverage asserted — with at least one BEHAVIORAL (non-usage) invocation each (cycle-4 finding #1 / Codex new-HIGH #1 + CYCLE-6 MEDIUM a):** assert that EVERY routed tool has golden/channel coverage under the parity net — at minimum that `tests/goldens/<tool>/` (or a captured channel from a routed suite) EXISTS for each of `audit-claims brownfield release pdf-extract requirements-sync` (the script-relative / long-pole routed tools) PLUS the validate-op/search/sync-claude/gen-skills/lint/checkers Plan 04 covers. **CYCLE-6 MEDIUM a — coverage must not be hollow: per routed tool, require at least ONE captured case that is a BEHAVIORAL (non-usage) invocation, NOT a shallow `--help`/`-h`/no-arg usage path.** Determine "behavioral" by: the case is not named `*usage*`/`*help*` AND its recorded invocation args are not `--help`/`-h`/empty AND its `stdout` (or `tree`) channel is non-trivial (a usage/help dump alone does not count). If a routed tool has coverage that is EXCLUSIVELY usage/help paths (or no coverage at all), the test FAILS naming the tool and the missing behavioral case. (Read `tests/goldens/` + the routed suites to build the coverage map; assert no routed tool is uncovered AND each has ≥1 behavioral case — so a tool cannot be "covered" by a hollow `--help` alone.)
WHY THIS IS PRE-FIX-FAILING: against the cycle-2 mechanism (no per-call IT_CAPTURE_DIR; run-all cannot capture routed channels from black-box children), the LIVE `--capture-channels` legs produce no keyed channel dirs to compare and `--require-parity` has nothing to diff — the injected divergence is NOT caught (step 1's "exits non-zero" assertion fails); AND against the cycle-3 comparator-only stub there was no live-path injection and no per-tool coverage assertion (step 1 and step 3 fail). It PASSES only once `--capture-channels`/the collision-proof IT_CAPTURE_DIR populate the keyed dirs through the LIVE seam, `--require-parity` byte-compares them, and every routed tool has coverage. Make it executable. (NOTE: the throwaway divtest suite is NOT added to the enumerated SUITE_MANIFEST list — it is a self-contained scaffold built + torn down inside this test.)
  </action>
  <verify>
    <automated>chmod +x tests/phase-15/run.sh tests/run-all-suites.sh tests/lib/no-direct-bin-calls.sh tests/test_routed_parity_divergence.sh && bash tests/lib/no-direct-bin-calls.sh && echo "no-direct-call gate clean" && bash tests/test_routed_parity_divergence.sh && echo "routed-divergence test pass" && WIKI_IMPL=bash bash tests/run-all-suites.sh; echo "run-all bash exit=$?"; WIKI_IMPL=py bash tests/run-all-suites.sh; echo "run-all py exit=$?"</automated>
  </verify>
  <acceptance_criteria>
    - `test -x tests/phase-15/run.sh` exits 0 (the missing aggregator added)
    - `test -x tests/lib/no-direct-bin-calls.sh && bash tests/lib/no-direct-bin-calls.sh` exits 0 (NO remaining direct bin/<tool>.sh call in the parity suites)
    - `grep -q 'source.*tests/lib/invoke_tool.sh' tests/phase-09/lib.sh && grep -q 'source.*tests/lib/invoke_tool.sh' tests/phase-10/lib.sh` exits 0 (seam available in the suites)
    - `grep -rl 'invoke_tool ' tests/phase-09 tests/phase-10 | head -1 | xargs test -f` exits 0 (test_*.sh files actually CALL invoke_tool)
    - `grep -qE '09 09.1 10 11 12.1 12.2 13 15 18 20 22' tests/run-all-suites.sh` exits 0 (the enumerated list INCLUDES 22 — REVIEWS HIGH#5; FAILS against the old `...18 20` list)
    - `grep -qE '(^|[^0-9])22([^0-9.]|$)' tests/SUITE_MANIFEST.txt || grep -q 'phase-24' tests/SUITE_MANIFEST.txt` exits 0 (phase-24 tests are pinned in the manifest — REVIEWS HIGH#5)
    - `grep -q 'require-parity' tests/run-all-suites.sh && grep -q 'IT_CAPTURE_DIR' tests/run-all-suites.sh && grep -q 'capture-channels' tests/run-all-suites.sh` exits 0 (IT_CAPTURE_DIR-fed CHANNEL capture from black-box children — REVIEWS cycle-3 finding #2 / TEST-01)
    - `grep -qiE 'collision-proof|testbasename|per-suite|per suite' tests/run-all-suites.sh` exits 0 (run-all exports ONE IT_CAPTURE_DIR per suite + relies on Plan 03's collision-proof key — cycle-4 finding #1)
    - `grep -qE 'cmp|diff' tests/run-all-suites.sh` exits 0 (the --require-parity path BYTE-compares channel files — REVIEWS HIGH#4)
    - `grep -qE 'it_pairing_key|sed -E .s/-\[0-9\]\+' tests/run-all-suites.sh && grep -qiE 'pair|strip.*pid|pid.*strip|unpaired|no pairs' tests/run-all-suites.sh` exits 0 (CYCLE-6 fix #4: --require-parity PAIRS captures by the pid-STRIPPED identity and FAILS on unpaired keys — no vacuous green when the two runs' PIDs differ)
    - `grep -qE '\-\-exclude-test|WIKI_PARITY_EXCLUDE_TESTS' tests/run-all-suites.sh` exits 0 (CYCLE-6 fix #1/#3: the caller-supplied TEST-level exclusion knob exists — the frozen interface Plan 06's hook fallback consumes to drop ONLY the recursive hook self-tests, keeping phase-24 in the suite list)
    - `grep -qE '\-\-only-suite|WIKI_PARITY_ONLY_SUITES' tests/run-all-suites.sh` exits 0 (the caller-supplied SUITE-SELECTION knob exists — the ONE concrete mechanism the divergence test uses to drive its throwaway suite through the LIVE runner; positive counterpart to --exclude-test)
    - `grep -qiE 'oracle-exempt' tests/run-all-suites.sh && grep -q 'oracle-exempt.txt' tests/run-all-suites.sh` exits 0 (CYCLE-6 MEDIUM b: --require-parity reads the MACHINE-READABLE tests/oracle-exempt.txt, not the prose .md — cycle-3 finding #1 ripple)
    - `test -x tests/test_routed_parity_divergence.sh && bash tests/test_routed_parity_divergence.sh` exits 0 (PRE-FIX-FAILING: a LIVE-path injected routed-suite byte divergence makes --require-parity exit non-zero AND identical captures pass AND per-routed-tool coverage holds — FAILS against the cycle-2 no-IT_CAPTURE_DIR mechanism AND the cycle-3 comparator-only stub — REVIEWS cycle-3 finding #2 + cycle-4 finding #1)
    - `grep -q 'require-parity' tests/test_routed_parity_divergence.sh && grep -q 'capture-channels' tests/test_routed_parity_divergence.sh && grep -q -- '--only-suite' tests/test_routed_parity_divergence.sh && grep -qiE 'ported.manifest|faketool|stub.*tool' tests/test_routed_parity_divergence.sh` exits 0 (the test drives the LIVE run-all -> seam -> capture path via a stub ported tool routed through run-all's --only-suite knob, NOT hand-built comparator dirs — cycle-4 finding #1 + cycle-6 warning 5)
    - `grep -qE 'audit-claims.*brownfield.*release.*pdf-extract.*requirements-sync|requirements-sync.*pdf-extract.*release.*brownfield.*audit-claims' tests/test_routed_parity_divergence.sh || (grep -q 'audit-claims' tests/test_routed_parity_divergence.sh && grep -q 'brownfield' tests/test_routed_parity_divergence.sh && grep -q 'release' tests/test_routed_parity_divergence.sh && grep -q 'pdf-extract' tests/test_routed_parity_divergence.sh && grep -q 'requirements-sync' tests/test_routed_parity_divergence.sh)` exits 0 (per-routed-tool coverage asserted for EVERY routed tool, not just one — cycle-4 finding #1 / Codex new-HIGH #1)
    - `! grep -qiE 'hand-built|comparator.*stub|build two channel dirs.*manually|manually.*channel dir' tests/test_routed_parity_divergence.sh` (the comparator-only hand-built-channel-dir form REVIEWS rejects is NOT the test's mechanism — the LIVE path is — cycle-4 finding #1)
    - `grep -qiE 'behavioral|non-usage|not.*help|no.*help|exclude.*usage' tests/test_routed_parity_divergence.sh` exits 0 (CYCLE-6 MEDIUM a: per-tool coverage requires ≥1 BEHAVIORAL non-usage captured invocation — a shallow --help does not satisfy coverage)
    - `grep -cE 'phase-[0-9].* (PASS|FAIL)' tests/SUITE_MANIFEST.txt` returns a count ≥ the total number of tests in the enumerated suites (PER-TEST granularity)
    - `WIKI_IMPL=bash bash tests/run-all-suites.sh` exits 0 (no new per-test regression vs the manifest)
    - `WIKI_IMPL=py bash tests/run-all-suites.sh` exits 0 (py falls through to the bash oracle — identical per-test results in P22)
    - `git diff tests/phase-10/lib.sh tests/phase-13/lib.sh` shows no change inside any make_bare_repo/make_fixture_repo body (D-13)
  </acceptance_criteria>
  <done>phase-15/run.sh added; phase-24 ADDED to the enumerated suite list `09 09.1 10 11 12.1 12.2 13 15 18 20 22` (REVIEWS HIGH#5); every direct bin call in the parity suites is mechanically routed through invoke_tool with a gate rejecting any remaining direct call; SUITE_MANIFEST.txt pins PER-TEST results (incl. phase-24) and run-all-suites.sh fails on any new per-test failure AND --capture-channels propagates ONE IT_CAPTURE_DIR per suite so routed invoke_tool calls in black-box children self-record under Plan 03's COLLISION-PROOF key (no cross-test-file overwrite — cycle-4 finding #1), and --require-parity BYTE-compares the stdout/stderr/exit/tree channels across impls (REVIEWS HIGH#4 / cycle-3 finding #2 / TEST-01), honoring tests/oracle-exempt.md; a pre-fix-failing behavioral test drives the LIVE run-all->seam->capture path via a stub ported tool to inject a routed byte divergence and prove --require-parity catches it, AND asserts per-routed-tool golden coverage for every routed tool (cycle-4 finding #1 — no comparator stub, no sparse-tool hollow parity); WIKI_IMPL=bash byte-identical (assertions + make_*_repo helpers untouched).</done>
</task>

<task type="auto">
  <name>Task 2: Additive package install in 4 jobs (incl. skills-check) + new parity.yml matrix (suites incl. 22) + required-check introspection test</name>
  <files>.github/workflows/lint.yml, .github/workflows/neutrality.yml, .github/workflows/setup-parity.yml, .github/workflows/parity.yml, tests/test_ci_required_checks.py</files>
  <read_first>
    - .github/workflows/lint.yml (READ FULLY — jobs lint/privacy-leak/strict at 33/54/71; the install pattern checkout@v6 -> setup-python@v6 -> `pip install pyyaml` at ~36-43/60-65/81-85; AND the skills-check job at ~89-103 which has checkout but NO setup-python and NO pip install)
    - .github/workflows/neutrality.yml (READ FULLY — job `neutrality` at 29; Install PyYAML at ~36-38)
    - .github/workflows/setup-parity.yml (READ FULLY — job `setup-parity` at 28; the 07-08 suite-runner block at 47-54 — THE precedent for running a phase suite as a CI step)
    - tests/SUITE_MANIFEST.txt + tests/run-all-suites.sh (from Task 1 — what parity.yml invokes; note the IT_CAPTURE_DIR --capture-channels + --require-parity channel-comparison + the enumerated list incl. 22)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (the CI workflows section — Pitfall 4 [no matrix on existing required job], the new-jobs-new-names rule, the additive install-step rule)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (HIGH#4 / cycle-3 finding #2 [parity-equivalence does CHANNEL byte-comparison via IT_CAPTURE_DIR captures], HIGH#5 [phase-24 in the matrix + asserted in the introspection test], + preserved HIGH#10 skills-check install)
  </read_first>
  <action>
**Additive package install in the 3 existing dep-installing jobs.** In `lint.yml` (`lint`/`privacy-leak`/`strict`), `neutrality.yml`, and `setup-parity.yml`, replace each `pip install pyyaml` / `pip install pyyaml ruamel.yaml` step's `run:` with `pip install -e .` (pulls the pinned `PyYAML==6.0.1` + `ruamel.yaml==0.19.1` from `pyproject.toml`). Keep `actions/setup-python@v6` with `python-version: '3.12'` (D-06 — no matrix on existing jobs). Do NOT rename any job key. Do NOT add a matrix to any required job (Pitfall 4).

**Add a package install to the required `skills-check` job (preserves cycle-1 HIGH#10).** The `skills-check` job (lint.yml ~89-103) currently has `actions/checkout@v6` then `bash bin/gen-skills.sh --check` with NO `setup-python` and NO `pip install`. Add, BEFORE the `gen-skills` step: an `actions/setup-python@v6` step (`python-version: '3.12'`) and a `run: pip install -e .` step. Do NOT rename the `skills-check` job key and do NOT add a matrix. Confirm `lint`/`privacy-leak`/`strict`/`neutrality`/`setup-parity` all now install via `pip install -e .`.

**New `parity.yml` — suites under the WIKI_IMPL matrix incl. phase-24 (TEST-01/TEST-02/D-14 + REVIEWS HIGH#4/HIGH#5 + cycle-3 finding #2).** Create `.github/workflows/parity.yml` with NEW jobs and NEW names (NOT any of the 6 required names):
- A `parity-suites` job with `strategy.matrix.impl: [bash, py]` → `parity-suites (bash)` / `parity-suites (py)`. Steps: `actions/checkout@v6` → `actions/setup-python@v6` ('3.12') → `pip install -e .` → run the no-direct-call gate (`bash tests/lib/no-direct-bin-calls.sh`) → `WIKI_IMPL=${{ matrix.impl }} bash tests/run-all-suites.sh` (per-test no-regression vs SUITE_MANIFEST.txt over the enumerated list INCLUDING 22).
- A SEPARATE `parity-equivalence` job (new name) that runs BOTH impls with `--capture-channels` and asserts BYTE-FOR-BYTE channel parity (the HIGH#4 / cycle-3 finding #2 cross-impl CHANNEL check, NOT just PASS/FAIL): `WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels bashch` → `WIKI_IMPL=py bash tests/run-all-suites.sh --capture-channels pych` → `bash tests/run-all-suites.sh --require-parity bashch pych`. In Phase 24 this is green-by-fallthrough (ported.manifest empty → py channels == bash channels byte-for-byte). It lights up real byte-level signal per Phase-23 port.
- Trigger on `pull_request` (and optionally `push` for early-warning).
Model the YAML on the existing jobs. Do NOT put the `common-freeze` guard here — Plan 06 owns it. Confirm the file parses with `yaml.safe_load`.

**`tests/test_ci_required_checks.py` — PKG-04/TEST-01/TEST-02 introspection.** A pytest test parsing the workflow YAMLs (`yaml.safe_load`) asserting:
1. The 6 required job names exist as EXACT keys. Fail if any renamed/missing.
2. None of those 6 jobs has a `strategy.matrix`.
3. `parity.yml` exists; its `parity-suites` job has `strategy.matrix.impl` containing both `bash` and `py`; and a `parity-equivalence` job exists.
4. ALL of `lint`, `privacy-leak`, `strict`, `neutrality`, `setup-parity` AND `skills-check` install the package: each has a step whose `run` contains `pip install -e .`.
5. Suites 09-22 are wired: assert `tests/run-all-suites.sh` exists, is invoked by `parity.yml`, AND its enumerated suite list CONTAINS `22` (read the file, assert the token `22` is in the hard-coded suite list — REVIEWS HIGH#5). Also assert `run-all-suites.sh` contains the IT_CAPTURE_DIR-fed `--require-parity` channel-comparison path (`IT_CAPTURE_DIR` + `cmp`/`diff` over channel files — REVIEWS HIGH#4 / cycle-3 finding #2 / TEST-01).
Write clear assertion messages naming the offending workflow/job/missing-suite.
  </action>
  <verify>
    <automated>python3 -c "import yaml; [yaml.safe_load(open(f)) for f in ['.github/workflows/lint.yml','.github/workflows/neutrality.yml','.github/workflows/setup-parity.yml','.github/workflows/parity.yml']]; print('workflows parse')" && python3 -m venv /tmp/p22v5 && /tmp/p22v5/bin/pip -q install pytest pyyaml -e . && /tmp/p22v5/bin/python -m pytest tests/test_ci_required_checks.py -q</automated>
  </verify>
  <acceptance_criteria>
    - `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/parity.yml'))"` exits 0 (valid YAML)
    - `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/lint.yml')); j=d['jobs']['skills-check']; steps=j['steps']; assert any('setup-python' in str(s.get('uses','')) for s in steps), 'skills-check missing setup-python'; assert any('pip install -e .' in str(s.get('run','')) for s in steps), 'skills-check missing pip install -e .'"` exits 0 (skills-check installs the package)
    - `! grep -q 'pip install pyyaml$' .github/workflows/lint.yml` (the bare pyyaml install replaced)
    - `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/lint.yml')); req=['lint','privacy-leak','strict','skills-check']; assert all(j in d['jobs'] for j in req); assert all('strategy' not in d['jobs'][j] or 'matrix' not in d['jobs'][j].get('strategy',{}) for j in req), 'matrix on required job'"` exits 0
    - `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/parity.yml')); m=d['jobs']['parity-suites']['strategy']['matrix']['impl']; assert 'bash' in m and 'py' in m, m; assert 'parity-equivalence' in d['jobs'], d['jobs'].keys()"` exits 0 (WIKI_IMPL matrix + channel-equivalence job — REVIEWS HIGH#4)
    - `grep -q 'no-direct-bin-calls.sh' .github/workflows/parity.yml && grep -q 'run-all-suites.sh' .github/workflows/parity.yml && grep -q 'require-parity' .github/workflows/parity.yml && grep -q 'capture-channels' .github/workflows/parity.yml` exits 0 (the gate + runner + capture-channels + channel-equivalence run in CI)
    - `pytest tests/test_ci_required_checks.py` passes in the venv (incl. the `22`-in-suite-list assertion + the IT_CAPTURE_DIR channel-comparison assertion)
  </acceptance_criteria>
  <done>the 3 existing workflows + the required skills-check job install the package via pip install -e . (6 required-check names unchanged, no matrix); parity.yml runs the enumerated suites INCLUDING phase-24 under WIKI_IMPL=[bash,py], enforces the no-direct-call gate and a parity-equivalence job that captures channels via IT_CAPTURE_DIR and BYTE-compares them across impls (REVIEWS HIGH#4 / cycle-3 finding #2); the introspection test enforces the frozen names + matrix shape + skills-check install + phase-24 in the suite list (REVIEWS HIGH#5) + the IT_CAPTURE_DIR channel-comparison path (REVIEWS HIGH#4 / cycle-3 finding #2 / TEST-01).</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| CI required-check names ↔ branch protection | The 6 names are a public-template merge-gate contract; a rename silently disables the gate |
| skills-check ↔ package install | A required job that cannot run the python shim breaks the merge gate |
| parity suite ↔ the seam | A direct (un-routed) bin call bypasses the oracle entirely — no parity signal |
| run-all ↔ black-box child test process | run-all cannot see a child's IT_*/fixture dir; without IT_CAPTURE_DIR, routed channels are uncollectable (cycle-3 finding #2) |
| per-suite IT_CAPTURE_DIR ↔ distinct test files | Two test files in one suite sharing the per-suite IT_CAPTURE_DIR must NOT overwrite each other's keys (cycle-4 finding #1) — relies on Plan 03's collision-proof key |
| divergence test ↔ live path | A comparator-only stub tests the comparator, not the live run-all->seam->capture path; reviewers reject it (cycle-4 finding #1) |
| routed-tool coverage ↔ parity net | A routed tool with no golden/channel coverage is parity-hollow even when the comparator works (cycle-4 finding #1) |
| per-test status ↔ byte-level behavior | Comparing only PASS/FAIL hides a port that changes user-visible bytes while keeping a thin assertion green (REVIEWS HIGH#4 / cycle-3 finding #2 / TEST-01) |
| enumerated suite list ↔ coverage | Omitting phase-24 means the richest 4-channel goldens never run in the matrix (REVIEWS HIGH#5) |
| oracle-exempt registry ↔ parity claim | Treating a parity-exempt path as verifiable yields a false parity claim (cycle-3 finding #1 ripple) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-22-17 | Tampering | required-check name change disables the merge gate | mitigate | New jobs get NEW names; no matrix on any of the 6 required jobs. `test_ci_required_checks.py` asserts the 6 names + no matrix. |
| T-22-30 | Denial of Service | skills-check fails once gen-skills becomes a python shim | mitigate | The skills-check job gains setup-python + `pip install -e .`; the introspection test asserts it specifically. |
| T-22-31 | Spoofing | a port diverges but the test bypasses the seam (direct bin call) | mitigate | Every direct bin call is mechanically routed AND `no-direct-bin-calls.sh` rejects any remaining direct call, run in the parity job. |
| T-22-39 | Spoofing | a port changes user-visible bytes but keeps per-test PASS/FAIL green | mitigate | `run-all-suites.sh --capture-channels` (IT_CAPTURE_DIR) collects per-call channels from black-box children + `--require-parity` BYTE-compares them across impls; the `parity-equivalence` CI job runs it; `tests/test_routed_parity_divergence.sh` drives the LIVE path and proves an injected routed divergence is caught (REVIEWS HIGH#4 / cycle-3 finding #2 / cycle-4 finding #1 / TEST-01). |
| T-22-50 | Spoofing | routed channels uncollectable from black-box children (capture silently empty) | mitigate | run-all exports IT_CAPTURE_DIR per suite so each routed invoke_tool self-records; the LIVE-path catch-a-divergence behavioral test fails if the keyed dirs are empty/uncompared (cycle-3 finding #2 / cycle-4 finding #1). |
| T-22-59 | Tampering | distinct test files in one suite overwrite each other's captured channels (dropped coverage) | mitigate | run-all exports ONE IT_CAPTURE_DIR per suite; Plan 03's COLLISION-PROOF key (testbasename+pid+counter) keeps distinct test files' captures separate; the divergence test drives the live multi-file path (cycle-4 finding #1). |
| T-22-68 | Spoofing | --require-parity passes vacuously (the two runs' PIDs never match, zero pairs compared) | mitigate | --require-parity pairs by the pid-STRIPPED `<suite>/<testbasename>/<tool>-<NN>` identity and FAILS on any unpaired key (a zero-pairs walk over a non-empty capture set is a failure); the divergence test drives two real runs (different PIDs) and asserts the injected divergence is caught (cycle-6 fix #4). |
| T-22-69 | Denial of Service | dropping the whole phase-24 suite removes the richest goldens from the private-branch gate | mitigate | run-all's `--exclude-test <basename>` excludes ONLY specific TEST FILES; Plan 06's hook fallback excludes only the two recursive hook self-tests, keeping phase-24 in the enumerated list so every 4-channel golden still runs (cycle-6 fix #1/#3). The CI matrix run applies NO exclusion. |
| T-22-70 | Spoofing | a routed tool is "covered" only by a shallow --help (hollow parity) | mitigate | The divergence test requires ≥1 BEHAVIORAL (non-usage) captured case per routed tool and FAILS naming a tool whose coverage is usage/help-only (cycle-6 MEDIUM a). |
| T-22-60 | Spoofing | a routed tool is parity-hollow (no golden/channel coverage) | mitigate | `test_routed_parity_divergence.sh` asserts per-routed-tool coverage for EVERY routed tool (audit-claims/brownfield/release/pdf-extract/requirements-sync + the Plan-04-covered tools); a tool with no coverage FAILS the test naming it (cycle-4 finding #1 / Codex new-HIGH #1). |
| T-22-40 | Spoofing | the richest 4-channel goldens never run in the matrix | mitigate | phase-24 is ADDED to the enumerated suite list + run-all + the introspection test (REVIEWS HIGH#5); the matrix executes tests/phase-24/run.sh under both impls. |
| T-22-51 | Spoofing | a parity-exempt path counted as parity-verified (false claim) | mitigate | run-all/--require-parity consumes the MACHINE-READABLE tests/oracle-exempt.txt (pattern → capture-key match) and skips/annotates listed paths with an audit line, not ad-hoc prose matching (cycle-3 finding #1 ripple + cycle-6 MEDIUM b). |
| T-22-32 | Spoofing | a RED suite gains N new failures undetected | mitigate | The PER-TEST manifest + run-all's per-test no-regression check catch any new failing test. |
| T-22-18 | Denial of Service | gate asserts universal green and blocks the phase forever | mitigate | run-all fails ONLY on a NEW per-test failure or a NEW channel divergence vs the pinned baseline; FAIL-stays-FAIL is allowed. |
| T-22-19 | Tampering | CI install floats a dep | mitigate | `pip install -e .` pulls the exact `==` pins from pyproject; the bare `pip install pyyaml` is removed. |
| T-22-20 | Information Disclosure | privacy-leak / neutrality gates accidentally weakened | mitigate | This plan only ADDS install lines + a new additive parity workflow; the gate steps are untouched. |
</threat_model>

<verification>
- `bash tests/lib/no-direct-bin-calls.sh` exits 0 (no un-routed direct bin call).
- `bash tests/test_routed_parity_divergence.sh` exits 0 (a LIVE-path injected routed byte divergence is caught; identical captures pass; per-routed-tool coverage holds — REVIEWS cycle-3 finding #2 + cycle-4 finding #1, pre-fix-failing).
- `WIKI_IMPL=bash bash tests/run-all-suites.sh` and `WIKI_IMPL=py bash tests/run-all-suites.sh` both exit 0 (no new per-test regression; py falls through).
- `WIKI_IMPL=bash bash tests/run-all-suites.sh --capture-channels bashch && WIKI_IMPL=py bash tests/run-all-suites.sh --capture-channels pych && bash tests/run-all-suites.sh --require-parity bashch pych` exits 0 in P22 (py channels == bash channels — REVIEWS HIGH#4 / cycle-3 finding #2).
- `grep -qE '09 09.1 10 11 12.1 12.2 13 15 18 20 22' tests/run-all-suites.sh` (phase-24 enumerated — REVIEWS HIGH#5).
- `grep -q IT_CAPTURE_DIR tests/run-all-suites.sh` (channels collected from black-box children — cycle-3 finding #2).
- `bash tests/phase-15/run.sh` runs.
- `pytest tests/test_ci_required_checks.py` passes (6 names + no matrix; skills-check installs package; parity matrix + channel-equivalence job present; 22 in the list; IT_CAPTURE_DIR channel-comparison present).
- All 4 workflow YAMLs parse with `yaml.safe_load`.
- `git diff --name-only HEAD -- bin/` is empty (no tool ported).
</verification>

<success_criteria>
- PKG-04: CI installs the package via an additive edit to the 3 workflows AND the required skills-check job; all 6 required-check names unchanged.
- TEST-01: `run-all-suites.sh --require-parity` BYTE-compares the captured stdout/stderr/exit/tree channels across bash and py for the routed suites, collected from black-box children via the COLLISION-PROOF IT_CAPTURE_DIR (REVIEWS HIGH#4 / cycle-3 finding #2 / cycle-4 finding #1) — a byte-divergence fails parity even when per-test PASS/FAIL matches; the LIVE-path catch-a-divergence behavioral test proves it and asserts per-routed-tool coverage.
- TEST-02: all phase suites 09-20 PLUS phase-24 (REVIEWS HIGH#5) are wired into CI under a `WIKI_IMPL=[bash,py]` matrix as new jobs; every direct bin call routes through the seam with a rejecting gate.
- REVIEWS HIGH#4 (byte-for-byte channel comparison), cycle-3 finding #2 (routed channel capture via IT_CAPTURE_DIR + catch-a-divergence test), cycle-4 finding #1 (collision-proof per-suite capture + LIVE-path divergence test + per-routed-tool coverage), HIGH#5 (phase-24 in the matrix), cycle-3 finding #1 ripple (oracle-exempt not parity-verified) + preserved cycle-1 HIGH#2-routing / HIGH#7-phase15 / HIGH#10-skills-check / HIGH#6-per-test-manifest all resolved.
</success_criteria>

<output>
After completion, create `.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-05-SUMMARY.md`
</output>
</content>
