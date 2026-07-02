---
phase: 22-foundation-package-skeleton-frozen-shared-core-parity-oracle
plan: 06
type: execute
wave: 5
depends_on: [01, 02, 03, 04, 05]
files_modified:
  - bin/check-common-freeze.sh
  - bin/check-staged-parity.sh
  - .githooks/pre-commit
  - .github/workflows/parity.yml
  - tests/freeze-baseline.sha
  - tests/phase-24/test_freeze_guard.sh
  - tests/phase-24/test_precommit_hooks.sh
  - tests/phase-24/test_staged_parity_index.sh
autonomous: true
requirements: [PKG-04, TEST-02]
user_setup: []

must_haves:
  decisions:
    - "D-07: frozen is enforced by a per-plan guard diffing each plan branch against a pinned baseline"
    - "D-08: the freeze covers all shared surfaces (common/ + pyproject.toml + shared test seam)"
    - "D-09: frozen is deliberate-additions-allowed via the ownership-rebase fallback, not absolute immutability"
  truths:
    - "a check-common-freeze guard fails (exit 2) if any commit touches the frozen surface vs a pinned baseline, with an explicit FROZEN-surface scope"
    - "the baseline is pinned at PRE-PLAN-06 HEAD (the wave-4 commit finalizing the frozen surface), NOT at this plan's own commit — so the committed freeze-baseline.sha is not its own circular SHA (preserves cycle-1 HIGH#3/#6)"
    - "the annotated phase-24-freeze tag is compared via ^{commit} everywhere it is matched to a commit SHA (preserves cycle-1 HIGH#7-deref)"
    - "check-common-freeze REQUIRES the tag^{commit} and tests/freeze-baseline.sha to be EQUAL when both exist (a stale tag must not silently override a bumped committed SHA), matching the oracle's N-4 guard in Plan 03 (addresses REVIEWS cycle-3 N-4)"
    - "the pre-commit hook captures the freeze guard's exit code with the CORRECT idiom `if cmd; then fc_rc=0; else fc_rc=$?; fi` (NOT `if ! cmd; then fc_rc=$?` which always sets 0) so the exit-3 unreachable-baseline SKIP branch is actually reached, not dead (preserves REVIEWS HIGH#2 hook leg)"
    - "a hook-level self-test drives the unreachable-baseline path THROUGH the hook and asserts the SKIP (exit-3) BEHAVIOR is reached (not a hard block) — checking behavior, not merely grepping for the strings fc_rc/= 3/skip (preserves REVIEWS HIGH#2 hook leg)"
    - "a LOCAL parity gate (pre-commit) runs the affected tool's parity suites when bin/, src/compendium/, or tests/ported.manifest is in the staged set — so a Phase-23 port's parity runs WITHOUT GitHub Actions (which never runs on the never-pushed private branches) (preserves REVIEWS HIGH#6)"
    - "check-staged-parity tests the STAGED CONTENT, not the working tree, via an EXPLICIT STAGED_EXEC_ROOT vs ORACLE_GIT_ROOT split IMPLEMENTED BY CONSUMING Plan 03's FROZEN per-lane root knobs as env vars (the gate sets WIKI_EXEC_ROOT=$STAGED_EXEC_ROOT + WIKI_ORACLE_GIT_ROOT=$ORACLE_GIT_ROOT; it never edits the frozen seam — cycle-6 fix #1/#2): STAGED_EXEC_ROOT = a materialized temp tree of the index (git checkout-index, NO .git) the seam's py leg reads (shim body/src/manifest via _oracle_exec_root); ORACLE_GIT_ROOT = the REAL repo (.git intact) the seam's worktree-oracle git commands run against (git worktree add / rev-parse the baseline via _oracle_git_root) — so BOTH legs work: the py leg reads STAGED files AND the bash-oracle git resolution succeeds against a real .git; the cycle-5 <staged-tool-bodies-from-STAGED_EXEC_ROOT> placeholder is replaced with concrete env-var wiring (addresses REVIEWS cycle-3 HIGH finding #4 + cycle-4 finding #4 + cycle-6 fix #2)"
    - "the negative staged test SEEDS a temporary tests/ported.manifest entry + a broken staged module so it genuinely exercises the Python parity leg under staging (an EMPTY manifest means the py leg never runs and the block never triggers); it asserts the commit is BLOCKED by a real Python-leg parity divergence (addresses REVIEWS cycle-4 finding #4)"
    - "the local parity self-test does NOT recurse infinitely AND the parity-path run-assertion is NON-VACUOUS: ONLY the two recursive hook self-tests (test_precommit_hooks.sh, test_staged_parity_index.sh) are excluded from the hook fallback run-all via the TEST-level `--exclude-test <basename>` knob (Plan 05, consumed here) — phase-24 STAYS in the run so every OTHER phase-24 golden still executes (Codex cycle-4 finding: dropping the whole suite would remove the richest goldens from the only private-branch gate), with the WIKI_PARITY_GATE_ACTIVE guard retained as a belt-and-suspenders bound — so test_precommit_hooks.sh can assert the parity path EXECUTES (reaches materialize+compare, not the skip branch) AND recursion still terminates (addresses REVIEWS cycle-3 HIGH finding #5 + cycle-4 finding #5 + cycle-6 fix #3)"
    - "a bounded-termination acceptance test runs test_precommit_hooks.sh under `timeout` and asserts it EXITS 0 within the bound (does NOT recurse / does NOT hit the timeout 124) (addresses REVIEWS cycle-3 HIGH finding #5)"
    - "freeze + parity enforcement coexist in .githooks/pre-commit with explicit order/skip semantics, reusing the corrected exit-capture idiom"
    - "the freeze pins LAST, after common/, pyproject.toml, the seam, goldens, and the per-test manifest are final"
    - "use of FREEZE_ALLOW_REBASE / PARITY_GATE_SKIP must be recorded in the plan SUMMARY (the escape hatches are documented + their use is auditable — N-7)"
  artifacts:
    - path: "bin/check-common-freeze.sh"
      provides: "The freeze guard: ^{commit}-resolved baseline diff over the explicit frozen surface -> exit 2 on change; SKIP (exit 3, not 0) on unreachable baseline; tag-vs-SHA equality required when both exist (N-4); stderr not swallowed"
      contains: "git diff"
    - path: "bin/check-staged-parity.sh"
      provides: "The LOCAL parity gate testing the STAGED INDEX via STAGED_EXEC_ROOT (materialized index, no .git) vs ORACLE_GIT_ROOT (real repo, for the oracle's git worktree/rev-parse): runs the affected tool's parity suites + --require-parity channel comparison and blocks on failure; re-entrancy-guarded (WIKI_PARITY_GATE_ACTIVE) + phase-24 excluded from the hook fallback (REVIEWS HIGH#6 + cycle-3 findings #4, #5 + cycle-4 findings #4, #5)"
      contains: "run-all-suites.sh"
    - path: ".githooks/pre-commit"
      provides: "Freeze + parity enforcement in the REAL local gate, with the corrected `if cmd; then rc=0; else rc=$?; fi` exit capture (REVIEWS HIGH#2 + HIGH#6)"
      contains: "check-common-freeze"
    - path: "tests/freeze-baseline.sha"
      provides: "Committed baseline SHA pinned at PRE-PLAN-06 HEAD (wave-4 final surface) — not circular"
    - path: "tests/phase-24/test_precommit_hooks.sh"
      provides: "Hook-level behavior self-test: skip-branch reached on unreachable baseline + parity gate EXECUTES the parity path (reaches materialize+compare, NOT the skip branch) on a staged src/compendium change; recursion-safe via phase-24 exclusion + WIKI_PARITY_GATE_ACTIVE (REVIEWS HIGH#2 + HIGH#6 + cycle-3 finding #5 + cycle-4 finding #5)"
    - path: "tests/phase-24/test_staged_parity_index.sh"
      provides: "Negative behavioral test: staged-broken + working-good is BLOCKED, with a SEEDED temporary ported.manifest entry + broken module so the Python leg genuinely runs (proves the gate tests the staged blob via STAGED_EXEC_ROOT while the oracle git resolution succeeds against ORACLE_GIT_ROOT); bounded-termination assertion via timeout + parity-path-executes assertion (REVIEWS cycle-3 findings #4 + #5 + cycle-4 findings #4 + #5)"
      contains: "git diff --cached"
    - path: ".github/workflows/parity.yml"
      provides: "common-freeze job wired into CI (non-vacuous: ^{commit} resolve, no swallowed stderr, skip-not-pass on unreachable)"
      contains: "common-freeze"
  key_links:
    - from: "bin/check-common-freeze.sh"
      to: "the explicit frozen surface (src/compendium/common, pyproject.toml, tests/lib seam+oracle+normalizer, tests/conftest.py, tests/goldens, tests/SUITE_MANIFEST.txt, tests/run-all-suites.sh)"
      via: "git diff --name-only <baseline>^{commit}..HEAD over the frozen paths (stderr surfaced)"
      pattern: "src/compendium/common"
    - from: "bin/check-staged-parity.sh"
      to: "STAGED_EXEC_ROOT (materialized temp tree of the index, no .git) + ORACLE_GIT_ROOT (the real repo, .git intact)"
      via: "git checkout-index materializes STAGED_EXEC_ROOT; the oracle's git worktree/rev-parse run against ORACLE_GIT_ROOT; trap cleanup"
      pattern: "checkout-index"
    - from: ".githooks/pre-commit"
      to: "bin/check-common-freeze.sh + bin/check-staged-parity.sh"
      via: "staged-diff freeze check + conditional staged parity gate, both with the corrected exit-capture idiom"
      pattern: "check-common-freeze"
---

<objective>
Pin the frozen-foundation baseline correctly and stand up TWO local gates in `.githooks/pre-commit` (the ONLY gate that runs on the real, never-pushed Phase-23 work): (1) the `check-common-freeze` guard over the EXPLICIT frozen surface, and (2) a `check-staged-parity` gate that runs the affected tool's parity suites — AGAINST THE MATERIALIZED STAGED INDEX, not the working tree, via an EXPLICIT `STAGED_EXEC_ROOT` (the materialized index, no `.git`) vs `ORACLE_GIT_ROOT` (the real repo, `.git` intact) split so BOTH legs work — when `bin/`/`src/compendium/`/`tests/ported.manifest` is staged. Both reuse the CORRECT `if cmd; then rc=0; else rc=$?; fi` exit-capture idiom. The freeze guard diffs against a baseline pinned at PRE-PLAN-06 HEAD, dereferences the annotated tag via `^{commit}`, REQUIRES the tag and committed SHA to be equal when both exist (N-4), never swallows the diff stderr, and SKIPs (exit 3) rather than passes on an unreachable baseline. The staged-parity gate is re-entrancy-guarded AND excludes phase-24's own suite from the hook fallback so its self-test's parity-path run-assertion is non-vacuous.

Purpose (D-07/D-08/D-09 + the REVIEWS oracle-integrity fixes). CYCLE-2 + CYCLE-3 + CYCLE-4 REVIEWS:
- HIGH#2 (hook leg, preserved): the prior hook used `if ! bash bin/check-common-freeze.sh --staged; then fc_rc=$?` — inside the `then` branch `$?` is the status of the negated condition `!`, which is ALWAYS 0 when the branch runs, so `fc_rc=0` always, `[ "$fc_rc" = "3" ]` is never true, and the exit-3 unreachable-baseline SKIP path is DEAD. This plan uses `if bash bin/check-common-freeze.sh --staged; then fc_rc=0; else fc_rc=$?; fi` and a BEHAVIOR-level hook self-test.
- HIGH#6 (preserved): the prior plan wired only the FREEZE guard into pre-commit; the PARITY suites ran only in GitHub Actions, which NEVER executes on the private Phase-23 migration branches (origin is the public neutralized template — local main/branches are never pushed). This plan adds a LOCAL `check-staged-parity` pre-commit gate.
- CYCLE-3 HIGH finding #4 (staged gate tests the working tree, not the staged index): `check-staged-parity.sh` filtered with `git diff --cached --name-only` to DECIDE whether to run, but then ran `tests/run-all-suites.sh` against the WORKING-TREE files. An unstaged fix can make parity pass while the staged commit is still broken. The cycle-3 fix materialized the index into a temp tree (`git checkout-index`) and ran parity THERE.
- CYCLE-4 finding #4 (the staged-tree-has-no-.git contradiction — Codex new-HIGH #3): SOURCE-VERIFIED — the cycle-3 materialized tree (`git checkout-index -a -f --prefix="$STAGE_TREE/"`) has NO `.git`, but the seam's worktree oracle runs `git -C "$REPO_ROOT" worktree add` / `git -C "$REPO_ROOT" rev-parse` which REQUIRE a real `.git`. The cycle-3 plan ASSERTED "the oracle still uses the REAL repo" but did NOT implement the split: if `REPO_ROOT` points at the staged tree, the oracle git commands FAIL (no .git); if it points at the real repo, the py leg runs WORKING-tree files (not staged). This plan implements the EXPLICIT split: `STAGED_EXEC_ROOT` = the materialized staged tree (no `.git`) where the staged tool bodies execute / the py leg reads from; `ORACLE_GIT_ROOT` = the REAL repo (`.git` intact) where the oracle's `git worktree add` / baseline `rev-parse` run. The seam's `REPO_ROOT` for the bash-oracle git resolution is set to `ORACLE_GIT_ROOT`; the staged py/tool bodies under test come from `STAGED_EXEC_ROOT`. So both legs work. ALSO: the cycle-3 negative test staged a broken module but the EMPTY `tests/ported.manifest` meant the py leg NEVER ran (an unported tool falls through to the bash oracle on both legs) → the block never triggered → the test was vacuous. This plan's negative test SEEDS a temporary `ported.manifest` entry + a broken staged module so the Python parity leg GENUINELY runs and the divergence genuinely blocks.
- CYCLE-3 HIGH finding #5 (local parity self-test recurses infinitely): Plan 04's `tests/phase-24/run.sh` auto-discovers every `test_*.sh`; Plan 06's `test_precommit_hooks.sh` stages a python change and invokes `check-staged-parity.sh`; that gate's safe fallback runs the FULL `tests/run-all-suites.sh` INCLUDING phase-24 → which re-runs `test_precommit_hooks.sh` → unbounded recursion. The cycle-3 fix added a `WIKI_PARITY_GATE_ACTIVE` re-entrancy guard.
- CYCLE-4 finding #5 (the guard makes the run-assertion vacuous — Codex new-HIGH #4): SOURCE-VERIFIED — the cycle-3 guard correctly bounds recursion, BUT the nested `test_precommit_hooks.sh` is required to "assert it RUNS the parity path (not the skip path)" — yet the nested call inherits `WIKI_PARITY_GATE_ACTIVE=1` and SHORT-CIRCUITS (`exit 0`), making that assertion vacuous-or-failing. This plan RECONCILES it, and CYCLE-6 fix #3 refines the reconciliation: EXCLUDE ONLY the two recursive hook self-tests (`test_precommit_hooks.sh`, `test_staged_parity_index.sh`) from the hook's fallback `run-all-suites.sh` invocation via the TEST-level `--exclude-test <basename>` knob Plan 05 added to the FROZEN runner (NOT a whole-suite `--exclude-suite 22` drop — Codex's cycle-4 finding: dropping the whole phase-24 suite removes the richest four-channel goldens from the ONLY gate that runs on the never-pushed private migration branches). So phase-24 STAYS in the run and every non-recursive phase-24 golden still executes, while the gate does not re-enter itself. KEEP the `WIKI_PARITY_GATE_ACTIVE` guard as a belt-and-suspenders bound. With only the recursive hook self-tests excluded, `test_precommit_hooks.sh` runs the gate ONCE on the FIRST entry (guard unset) and the gate reaches the materialize+compare parity path WITHOUT triggering the recursion — so the "parity path EXECUTES" assertion is genuine AND recursion still terminates. The acceptance asserts this FUNCTIONING runner behavior (bounded termination via `timeout` + parity-path-executes), not exclusion-related text.
- N-4 (preserved + tightened): the freeze guard prefers the local tag over `tests/freeze-baseline.sha`; when BOTH exist they MUST be equal (a stale tag must not override a bumped SHA) — matching Plan 03's oracle guard.
- N-7: the FREEZE_ALLOW_REBASE / PARITY_GATE_SKIP escape hatches stay documented; their use must be recorded in the plan SUMMARY (auditable).
- CYCLE-6 fix #1/#2/#3 (the freeze/interface deadlock — resolved by ORDERING, not by re-architecture): the cycle-5 revision froze `tests/lib/invoke_tool.sh`, `tests/lib/oracle-worktree.sh`, and `tests/run-all-suites.sh` while THIS plan's fixes needed to change their interfaces — an impossible position. The fix moves the interface additions UPSTREAM of the freeze: Plan 03 (wave 2) adds the per-lane root knobs `WIKI_EXEC_ROOT`/`WIKI_ORACLE_GIT_ROOT` to the seam; Plan 05 (wave 4) adds the `--exclude-test`/`WIKI_PARITY_EXCLUDE_TESTS` knob + the pid-stripped `--require-parity` to the runner. Because this plan's freeze baseline is pinned at PRE-PLAN-06 HEAD (= end of wave 4), the frozen snapshot INCLUDES all three knobs. So this plan's `check-staged-parity.sh` CONSUMES them (sets `WIKI_EXEC_ROOT=$STAGED_EXEC_ROOT` + `WIKI_ORACLE_GIT_ROOT=$ORACLE_GIT_ROOT`; passes `--exclude-test test_precommit_hooks.sh --exclude-test test_staged_parity_index.sh`) — it never edits a frozen file, so `check-common-freeze.sh` never trips. This is the direct resolution of the cycle-5 NEW-HIGH deadlock.
Plus the preserved cycle-1 resolutions: pre-Plan-06 non-circular baseline (HIGH#3/#6), `^{commit}` tag deref (HIGH#7), non-vacuous CI guard (HIGH#12-design), explicit frozen-surface scope (MEDIUM).

Output: `bin/check-common-freeze.sh`, `bin/check-staged-parity.sh` (with the STAGED_EXEC_ROOT/ORACLE_GIT_ROOT split + phase-24-excluded fallback), the `.githooks/pre-commit` freeze + parity checks, the committed `tests/freeze-baseline.sha` (pre-Plan-06 HEAD), the `common-freeze` CI job, the freeze-guard self-test, the hook-behavior self-test (parity-path-executes + recursion-terminates), and the staged-index/negative/bounded-termination test (with a SEEDED manifest entry + broken module).

CRITICAL ORDERING (preserves cycle-1 HIGH#6): The baseline is pinned at the commit IMMEDIATELY BEFORE this plan's first commit (= the merged HEAD of Plans 01-05, the end of wave 4 = the FINAL frozen surface). Plan 06's own files (`bin/check-common-freeze.sh`, `bin/check-staged-parity.sh`, `.githooks/pre-commit`, `tests/freeze-baseline.sha`, the `common-freeze` job, the self-tests) are ALL OUTSIDE the frozen surface, so the guard at post-Plan-06 HEAD still diffs clean against the pre-Plan-06 baseline. Do NOT pin the baseline at Plan-06's own HEAD.

ORACLE↔FREEZE RECONCILIATION (acyclic — see Plan 03): Plan 03's worktree oracle READS the baseline ref this plan PINS (`phase-24-freeze` / `tests/freeze-baseline.sha`), with a HEAD fallback (loud-fail if ported+HEAD) so it never requires this plan to function. This plan SUPPLIES that ref. No cycle: Plan 03 (wave 2) builds the mechanism with a HEAD fallback; Plan 06 (wave 5) pins the frozen ref the mechanism prefers once it exists. After this plan lands, Plan 03's `WIKI_IMPL=bash` oracle checks out the FROZEN ref, so it keeps running the frozen bash even after Phase 25 flips a shim.
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
<!-- The drift-gate-as-CI-check precedent the guard models on: -->
bin/sync-claude.sh   --check -> exit 2 on drift  (sync-claude.sh:20-30)
bin/gen-skills.sh    --check -> exit 1 on drift   (gen-skills.sh:11-12)

<!-- The REAL local gate (CONFIRMED this session) — CI never runs on the private work (REVIEWS HIGH#6): -->
.githooks/pre-commit  -> currently (lines 4/8/23/56): set -euo pipefail ; `if ! bash bin/sync-claude.sh --check; then` (+autosync) ;
                         `if ! bash bin/gen-skills.sh --check; then` (+autoregen) ; `if ! bash bin/lint.sh --strict --staged --category provenance >&2; then`.
                         NOTE: the existing hook uses `if ! cmd; then ...` — that pattern is FINE for those steps (they don't need $? = a specific
                         distinct code), but for the freeze check we need the DISTINCT exit-3 skip code, so the freeze step MUST use
                         `if cmd; then fc_rc=0; else fc_rc=$?; fi` (REVIEWS HIGH#2). It has NO freeze/parity step today.

<!-- The Plan-05 runner + channel-comparison the LOCAL parity gate invokes (REVIEWS HIGH#6 + cycle-3 finding #2): -->
tests/run-all-suites.sh   -> WIKI_IMPL=bash|py per-test no-regression + --capture-channels DIR (IT_CAPTURE_DIR-fed) + --require-parity <bashch> <pych> CHANNEL byte-comparison (pid-independent pairing, cycle-6 fix #4)
                             + (cycle-6 fix #1/#3) the FROZEN runner supports a TEST-level exclusion knob `--exclude-test <basename>` / WIKI_PARITY_EXCLUDE_TESTS (added by Plan 05 BEFORE the freeze). The hook fallback passes
                             `--exclude-test test_precommit_hooks.sh --exclude-test test_staged_parity_index.sh` (ONLY the two recursive hook self-tests) so phase-24 STAYS in the run — every other phase-24 golden still executes — while the gate does not re-enter itself. This gate CONSUMES the knob; it does not (cannot) edit the frozen runner.
tests/ported.manifest     -> the per-port append (when a tool is ported, its parity lights up; EMPTY in P22 -> the negative test must SEED a temporary entry)
<!-- Map a staged bin/<tool>.sh or src/compendium/<tool>.py change to the suite(s) covering that tool; if mapping is hard,
     the safe default is to run the full enumerated run-all under both impls + --require-parity — BUT against the MATERIALIZED
     STAGED INDEX (STAGED_EXEC_ROOT, no .git) while the oracle git commands run against ORACLE_GIT_ROOT (real .git) — cycle-3 finding #4 + cycle-4 finding #4. -->

<!-- The seam's worktree-oracle git dependency (Plan 03 — the .git requirement that forces the STAGED_EXEC_ROOT/ORACLE_GIT_ROOT split, cycle-4 finding #4): -->
tests/lib/oracle-worktree.sh -> runs `git -C "$(_oracle_git_root)" worktree add --detach <wt> <ref>` + `git -C "$(_oracle_git_root)" rev-parse -q --verify ...^{commit}` where `_oracle_git_root` = `${WIKI_ORACLE_GIT_ROOT:-$REPO_ROOT}`
                                -> the git-root REQUIRES a REAL git repo (a .git). A materialized staged tree (git checkout-index) has NO .git. The FROZEN seam (Plan 03) now exposes TWO per-lane root knobs:
                                   WIKI_EXEC_ROOT (py-lane shim body/src/ported.manifest, via `_oracle_exec_root`) and WIKI_ORACLE_GIT_ROOT (the oracle's git worktree/rev-parse + freeze-baseline.sha, via `_oracle_git_root`), BOTH default $REPO_ROOT.
                                -> the gate SETS them as env vars: `WIKI_EXEC_ROOT=$STAGED_EXEC_ROOT` (staged py bodies) + `WIKI_ORACLE_GIT_ROOT=$ORACLE_GIT_ROOT` (real .git for the oracle). So BOTH legs work AND the gate never edits the frozen seam (cycle-6 fix #1/#2).

<!-- The phase-24 aggregator that auto-discovers test_*.sh (Plan 04) — the recursion source (cycle-3 finding #5 / cycle-4 finding #5): -->
tests/phase-24/run.sh  -> `for t in "$SCRIPT_DIR"/test_*.sh` — auto-discovers test_precommit_hooks.sh; the gate's full-suite
                          fallback re-runs phase-24 -> re-runs test_precommit_hooks.sh -> recursion unless EXCLUDED + guarded.

<!-- VERIFIED git facts (this session): -->
<!--  - `git rev-parse <annotated-tag>` returns the TAG OBJECT SHA, not the commit; `<tag>^{commit}` returns the commit. -->
<!--  - .planning/ and wiki-local/ ARE git-tracked; origin is the never-pushed public template (bin/release.sh orphan-branch). A push leaks both dirs. -->
<!--  - `git checkout-index -a --prefix=<dir>/` materializes the STAGED index into <dir> (no working-tree mutation, NO .git); `git archive --cached`/`git stash --keep-index` are alternatives. checkout-index is the safest for an LLM-executed hook (no working-tree mutation, no stash pop edge cases). -->

<!-- The EXPLICIT FROZEN surface (D-08) — INCLUDE: -->
src/compendium/common/**           (single-source-of-truth core — Plan 02)
pyproject.toml                     (entry-point declarations — Plan 01)
tests/lib/invoke_tool.sh           (the seam — Plan 03; INCLUDES the WIKI_EXEC_ROOT per-lane exec-root knob the staged gate consumes — cycle-6 fix #1/#2)
tests/lib/oracle-worktree.sh       (the worktree oracle resolver — Plan 03; INCLUDES the WIKI_ORACLE_GIT_ROOT git-root knob the staged gate consumes — cycle-6 fix #1/#2)
tests/lib/normalize.sh             (the normalizer — Plan 03)
tests/conftest.py                  (the pytest fixture contract — Plan 03)
tests/goldens/**                   (the frozen characterization footprints — Plan 04)
tests/SUITE_MANIFEST.txt           (the pinned per-test baseline — Plan 05)
tests/run-all-suites.sh            (the shared parity runner — Plan 05; INCLUDES the --exclude-test/WIKI_PARITY_EXCLUDE_TESTS knob + the pid-stripped --require-parity the hook fallback consumes — cycle-6 fix #1/#3/#4)
tests/lib/no-direct-bin-calls.sh   (the seam-routing gate — Plan 05)
<!-- EXCLUDE from the freeze (must stay editable / are controlled mutations): -->
tests/ported.manifest              (each Phase-23 port APPENDS its tool — controlled per-port mutation, D-09; ONE owner per append)
tests/lib/test_*.sh                (the seam SELF-TESTS — must stay editable; do NOT blanket-freeze)
tests/phase-24/test_*.sh           (the characterization TESTS — not the frozen footprints)
tests/impl-assertion-inventory.md  (grows as Phase-23 rewrites deferred tests — D-09 escape-hatch note)
tests/oracle-exempt.md             (the parity-exempt registry — grows as Phase-23 surfaces more exempt paths)
<!-- L-2 NOTE: tests/conftest.py + tests/SUITE_MANIFEST.txt are frozen, but Phase-23 TEST-06 growth (new conftest
     fixtures / new manifest rows) goes through the D-09 ownership-rebase escape hatch — document this one-liner. -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write check-common-freeze guard (explicit surface, ^{commit}, tag-vs-SHA equality N-4, no swallow, skip-not-pass) + committed pre-Plan-06 baseline SHA + self-test</name>
  <files>bin/check-common-freeze.sh, tests/freeze-baseline.sha, tests/phase-24/test_freeze_guard.sh</files>
  <read_first>
    - bin/sync-claude.sh (READ lines 1-35 — the --check drift-gate shape: compute, compare, exit 2 on drift; mirror this control flow)
    - bin/gen-skills.sh (READ lines 1-20 — the --check exit-1-on-drift shape)
    - bin/check-privacy.sh (READ the head — `set -euo pipefail` + exit-code convention + the bin/ script style)
    - tests/lib/oracle-worktree.sh (Plan 03 — confirm the guard's baseline source and the oracle's baseline source AGREE: phase-24-freeze^{commit} -> tests/freeze-baseline.sha -> HEAD; AND mirror Plan 03's N-4 tag-vs-SHA equality + loud-fail-on-ported+HEAD so both honor the same invariant)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-PATTERNS.md (the common-freeze guard section — the git diff form + baseline-pin recommendation + D-09 escape hatch)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (preserved cycle-1 HIGH#3/#6 [pin pre-Plan-06 HEAD], HIGH#7 [^{commit} deref], HIGH#12 [non-vacuous CI guard], MEDIUM [freeze-surface scope]; cycle-3 N-4 [tag-vs-SHA equality])
  </read_first>
  <action>
**`bin/check-common-freeze.sh`** — the freeze guard, modeled on `sync-claude.sh --check` / `gen-skills.sh --check`. Behavior (preserves the cycle-1 resolutions + folds N-4):
- `set -euo pipefail`; resolve `$REPO_ROOT`.
- Define the EXPLICIT frozen surface as a path list — INCLUDE: `src/compendium/common/ pyproject.toml tests/lib/invoke_tool.sh tests/lib/oracle-worktree.sh tests/lib/normalize.sh tests/conftest.py tests/goldens/ tests/SUITE_MANIFEST.txt tests/run-all-suites.sh tests/lib/no-direct-bin-calls.sh`. Do NOT freeze `tests/lib/test_*.sh` (seam self-tests), `tests/phase-24/test_*.sh`, `tests/impl-assertion-inventory.md`, `tests/oracle-exempt.md`, or `tests/ported.manifest` (the controlled per-port append). Document the include/exclude rationale in a header comment, including the L-2 one-liner: Phase-23 TEST-06 growth (new conftest fixtures / new SUITE_MANIFEST rows) goes through the D-09 ownership-rebase escape hatch.
- Resolve the baseline ref with `^{commit}` deref (preserves HIGH#7): read `git rev-parse -q --verify "phase-24-freeze^{commit}"` (TAG_SHA, if any) and the SHA in `tests/freeze-baseline.sha` (FILE_SHA, if reachable). **N-4 tag-vs-SHA equality (matches Plan 03's oracle):** if BOTH TAG_SHA and FILE_SHA exist and they DIFFER, print `FREEZE FATAL: phase-24-freeze^{commit} (<tag>) != tests/freeze-baseline.sha (<file>) — a stale tag must not override a bumped SHA` to stderr and exit 2 (a hard fail — the baseline is ambiguous). Prefer TAG_SHA, else FILE_SHA. Capture into `BASELINE`. Always use `^{commit}` when comparing the tag to a commit SHA.
- UNREACHABLE-BASELINE handling (preserves HIGH#12 — do NOT pass vacuously): before diffing, verify the baseline commit is REACHABLE: `git rev-parse -q --verify "${BASELINE}^{commit}"`. If NOT reachable (neither tag nor file resolved to a reachable commit), print `SKIP: freeze baseline unreachable in this checkout (NOT a pass)` to stderr and exit a DISTINCT skip code `3` — never `0`.
- Diff the frozen surface against the baseline, SURFACING stderr (never `2>/dev/null`):
```bash
CHANGED="$(git diff --name-only "${BASELINE}^{commit}..HEAD" -- \
    src/compendium/common/ pyproject.toml \
    tests/lib/invoke_tool.sh tests/lib/oracle-worktree.sh tests/lib/normalize.sh \
    tests/conftest.py tests/goldens/ \
    tests/SUITE_MANIFEST.txt tests/run-all-suites.sh tests/lib/no-direct-bin-calls.sh)"
```
- If `$CHANGED` is non-empty, print the offending paths to stderr and `exit 2`. If empty, print an OK line to stdout and `exit 0`.
- STAGED mode (`--staged`) for the pre-commit hook (Task 3): diff the STAGED changes against the baseline over the frozen paths (`git diff --cached --name-only "${BASELINE}^{commit}" -- <frozen paths>`), so a commit-in-progress touching the frozen surface is blocked BEFORE it lands.
- D-09 escape hatch: accept `FREEZE_ALLOW_REBASE=1` (or `--allow-rebase`) that exits 0 even on changes. Header comment: using it REQUIRES bumping `tests/freeze-baseline.sha` + `git tag -f phase-24-freeze` in the same plan, AND recording its use in the plan SUMMARY (N-7).
- `usage()` heredoc; make executable; header comment explains the role + the `^{commit}` + tag-vs-SHA-equality (N-4) + no-swallow + skip-not-pass invariants.

**`tests/freeze-baseline.sha`** — the committed baseline, pinned at PRE-PLAN-06 HEAD (NOT this plan's own commit). At execute time, BEFORE making any Plan-06 commit, capture the current HEAD (the merged end-of-wave-4 surface = Plans 01-05 final): `git rev-parse HEAD`. Write THAT 40-char SHA as a single line. Then commit Plan 06's files ON TOP — those do NOT touch the frozen surface, so the guard at post-Plan-06 HEAD diffs CLEAN against this pre-Plan-06 baseline. Document the captured SHA in the SUMMARY.

**`tests/phase-24/test_freeze_guard.sh`** — a self-test proving the guard fires:
1. Clean state: against the pinned baseline, `bash bin/check-common-freeze.sh` exits 0.
2. Drift detection: in a throwaway git branch/worktree, append a comment to a FROZEN file (e.g. `tests/lib/normalize.sh` or `src/compendium/common/__init__.py`), commit, assert exit 2. Clean up.
3. Non-frozen change passes: change a NON-frozen file (`tests/lib/test_normalize.sh` or `tests/ported.manifest`), commit, assert exit 0.
4. Escape hatch: with `FREEZE_ALLOW_REBASE=1`, the drift case from (2) exits 0.
5. Unreachable baseline SKIPs (exit 3), not passes: point the guard at a fabricated unreachable SHA and assert exit 3, NOT 0.
6. Annotated-tag deref: create a throwaway annotated tag at the baseline commit, assert the guard resolves it via `^{commit}` (still exits 0/clean). Delete the throwaway tag.
7. **N-4 tag-vs-SHA mismatch fails (exit 2):** create a throwaway `phase-24-freeze`-named tag at a DIFFERENT commit than the committed `tests/freeze-baseline.sha` (use a temp clone or a fabricated tag pointing elsewhere), assert the guard exits 2 with the FATAL mismatch message (a stale tag must not silently override). Clean up the throwaway tag. (If creating a real conflicting tag is impractical in-place, drive the equality branch via a tiny isolated git fixture repo or a function-level unit check of the comparison; the REQUIRED assertion is that unequal tag-vs-SHA fails, not how the fixture is built.)
Make executable; isolated git ops so it does not pollute the working tree.

Do NOT create the `phase-24-freeze` tag inside the guard (Task 3 creates it). The guard only READS the tag-or-SHA baseline.
  </action>
  <verify>
    <automated>chmod +x bin/check-common-freeze.sh tests/phase-24/test_freeze_guard.sh && test -f tests/freeze-baseline.sha && bash bin/check-common-freeze.sh; echo "freeze-guard clean exit=$?"; bash tests/phase-24/test_freeze_guard.sh; echo "guard selftest exit=$?"</automated>
  </verify>
  <acceptance_criteria>
    - `test -x bin/check-common-freeze.sh` exits 0 (executable)
    - `grep -q 'git diff --name-only' bin/check-common-freeze.sh` exits 0
    - `grep -q 'src/compendium/common' bin/check-common-freeze.sh && grep -q 'pyproject.toml' bin/check-common-freeze.sh && grep -q 'tests/lib/invoke_tool.sh' bin/check-common-freeze.sh && grep -q 'tests/lib/oracle-worktree.sh' bin/check-common-freeze.sh` exits 0 (core frozen surfaces incl. the worktree resolver watched)
    - `grep -q 'tests/conftest.py' bin/check-common-freeze.sh && grep -q 'tests/goldens' bin/check-common-freeze.sh && grep -q 'SUITE_MANIFEST' bin/check-common-freeze.sh` exits 0 (the EXPANDED frozen surface)
    - `grep -q 'ported.manifest' bin/check-common-freeze.sh` exits 0 (referenced as EXCLUDED/controlled-mutation)
    - `grep -qF '^{commit}' bin/check-common-freeze.sh` exits 0 (annotated-tag deref)
    - `grep -qiE 'TAG_SHA.*FILE_SHA|stale tag|must not.*override|tag.*!=.*freeze-baseline|FATAL' bin/check-common-freeze.sh` exits 0 (N-4: tag-vs-SHA equality required when both exist — matches Plan 03 oracle)
    - `! grep -qE 'git diff .*2>/dev/null' bin/check-common-freeze.sh` (the diff stderr is NOT swallowed)
    - `grep -qiE 'unreachable|SKIP' bin/check-common-freeze.sh && grep -qE 'exit 3' bin/check-common-freeze.sh` exits 0 (skip-not-pass on unreachable baseline)
    - `grep -qE 'exit 2' bin/check-common-freeze.sh` exits 0 (hard-fail on drift / tag-vs-SHA mismatch)
    - `grep -q -- '--staged' bin/check-common-freeze.sh` exits 0 (staged mode)
    - `grep -qE 'FREEZE_ALLOW_REBASE|allow-rebase' bin/check-common-freeze.sh` exits 0 (D-09 escape hatch)
    - `test -f tests/freeze-baseline.sha && grep -qE '^[0-9a-f]{40}$' tests/freeze-baseline.sha` exits 0 (a full SHA committed)
    - `bash bin/check-common-freeze.sh` exits 0 at the pinned baseline (clean — proves the pre-Plan-06 pin is non-circular)
    - `bash tests/phase-24/test_freeze_guard.sh` exits 0 (clean=0, drift=2, non-frozen=0, escape-hatch=0, unreachable=3, tag-deref-clean, AND tag-vs-SHA-mismatch=2 all verified — N-4)
  </acceptance_criteria>
  <done>bin/check-common-freeze.sh diffs the EXPLICIT frozen surface (incl. oracle-worktree.sh) vs a ^{commit}-resolved baseline, REQUIRES tag^{commit} == tests/freeze-baseline.sha when both exist (exit 2 on mismatch — N-4, matching Plan 03's oracle), exits 2 on drift, SKIPs with exit 3 (never 0) on an unreachable baseline without swallowing stderr, supports --staged + FREEZE_ALLOW_REBASE; tests/freeze-baseline.sha holds the PRE-PLAN-06 HEAD SHA (non-circular); the self-test proves clean/drift/non-frozen/escape-hatch/unreachable-skip/tag-deref/tag-vs-SHA-mismatch.</done>
</task>

<task type="auto">
  <name>Task 2: Write the LOCAL staged-parity gate testing the STAGED INDEX via STAGED_EXEC_ROOT vs ORACLE_GIT_ROOT (cycle-3 finding #4 + cycle-4 finding #4) + re-entrancy guard + phase-24-excluded fallback (cycle-3 finding #5 + cycle-4 finding #5) + hook-behavior + negative-staged (seeded manifest+broken module) + bounded-termination self-tests</name>
  <files>bin/check-staged-parity.sh, tests/phase-24/test_precommit_hooks.sh, tests/phase-24/test_staged_parity_index.sh</files>
  <read_first>
    - tests/run-all-suites.sh (Plan 05 — the runner the gate invokes: WIKI_IMPL=bash|py per-test no-regression + --capture-channels (IT_CAPTURE_DIR) + --require-parity <bashch> <pych> CHANNEL byte-comparison; the enumerated suite list incl. 22; CONFIRM/USE the TEST-level exclusion knob Plan 05 added to the FROZEN runner (`--exclude-test <basename>` / WIKI_PARITY_EXCLUDE_TESTS); the gate passes `--exclude-test test_precommit_hooks.sh --exclude-test test_staged_parity_index.sh` to drop ONLY the recursive hook self-tests, keeping phase-24 in the run — cycle-6 fix #3. ALSO confirm the seam's per-lane root knobs WIKI_EXEC_ROOT/WIKI_ORACLE_GIT_ROOT exist [Plan 03] so this gate CONSUMES them as env vars rather than editing the frozen seam — cycle-6 fix #1/#2)
    - tests/lib/oracle-worktree.sh (Plan 03 — CONFIRM the seam runs `git -C "$REPO_ROOT" worktree add` / `git -C "$REPO_ROOT" rev-parse ...^{commit}` — these REQUIRE a real .git, which a git-checkout-index materialized tree does NOT have; THIS is why the gate needs ORACLE_GIT_ROOT (real .git) distinct from STAGED_EXEC_ROOT (materialized index, no .git) — cycle-4 finding #4)
    - tests/phase-24/run.sh (Plan 04 — auto-discovers test_*.sh INCLUDING test_precommit_hooks.sh; THIS is the recursion source the exclusion + re-entrancy guard break — cycle-3 finding #5 / cycle-4 finding #5)
    - tests/ported.manifest (Plan 01/Plan 05 — EMPTY in P22 so the py leg never runs for any tool by default; the negative test must SEED a temporary entry so the Python parity leg genuinely runs under staging — cycle-4 finding #4)
    - bin/check-common-freeze.sh (Task 1 — reuse its bin/ script style + the corrected exit-capture idiom)
    - .githooks/pre-commit (READ FULLY — the staged-detection idiom `git diff --cached --name-only`; the existing defensive style)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (HIGH#6 [local parity gate on staged bin/ / src/compendium/ / ported.manifest changes — CI never runs on the private work], HIGH#2 [correct exit-capture idiom], cycle-3 finding #4 [test the STAGED INDEX, not the working tree], cycle-3 finding #5 [break the self-test recursion], cycle-4 finding #4 [STAGED_EXEC_ROOT vs ORACLE_GIT_ROOT split + seed a manifest entry for the negative test], cycle-4 finding #5 [exclude phase-24 from the hook fallback so the run-assertion is non-vacuous])
  </read_first>
  <action>
**`bin/check-staged-parity.sh` — the LOCAL parity gate testing the STAGED INDEX via the STAGED_EXEC_ROOT/ORACLE_GIT_ROOT split (REVIEWS HIGH#6 + cycle-3 findings #4, #5 + cycle-4 findings #4, #5).** CI parity runs ONLY in GitHub Actions, which NEVER runs on the never-pushed private Phase-23 branches. So a port can commit locally with NO parity check. This gate makes parity locally enforceable AND tests the staged content while keeping the oracle's git resolution working. Behavior:
- `set -euo pipefail`; resolve `$REPO_ROOT` (this is the REAL repo with `.git`).
- **RE-ENTRANCY GUARD (cycle-3 finding #5 — DO FIRST):** if `WIKI_PARITY_GATE_ACTIVE` is already `1`, print a one-line "parity gate re-entry detected — short-circuiting (nested invocation)" to stderr and `exit 0` IMMEDIATELY. Otherwise `export WIKI_PARITY_GATE_ACTIVE=1` before invoking `run-all-suites.sh`. Header comment: this guard is a belt-and-suspenders bound; the PRIMARY recursion break is excluding phase-24 from the hook fallback (below).
- Detect the migration-relevant staged set: `git diff --cached --name-only` filtered to `bin/`, `src/compendium/`, or `tests/ported.manifest`. If NONE of those are staged, print "no migration-relevant change staged — parity gate skipped" to stdout and `exit 0` (the common case for non-migration commits — keep the hot path fast).
- **THE STAGED_EXEC_ROOT vs ORACLE_GIT_ROOT SPLIT (cycle-4 finding #4 — the core fix):**
  - `ORACLE_GIT_ROOT="$REPO_ROOT"` — the REAL repo, `.git` intact. The seam's worktree oracle (`oracle-worktree.sh`) runs `git -C "$ORACLE_GIT_ROOT" worktree add` / `git -C "$ORACLE_GIT_ROOT" rev-parse ...^{commit}` against THIS, so the held-fixed bash baseline resolves correctly. (The seam reads `REPO_ROOT`; for the oracle leg, set/keep `REPO_ROOT=$ORACLE_GIT_ROOT`.)
  - `STAGED_EXEC_ROOT="$(mktemp -d)"; trap 'rm -rf "$STAGED_EXEC_ROOT"' EXIT` — materialize the STAGED index into this temp tree with NO working-tree mutation and NO `.git`: `git checkout-index -a -f --prefix="$STAGED_EXEC_ROOT/"`. (Acceptable alternative: `git archive --cached HEAD-or-index | tar -x -C "$STAGED_EXEC_ROOT"`; checkout-index is preferred for an LLM-executed hook — no stash pop edge cases, no working-tree mutation. Do NOT use `git stash --keep-index` as the primary mechanism.)
  - Run the parity leg so the STAGED tool bodies (`bin/<tool>.sh` / `src/compendium/<tool>.py`) under test come from `STAGED_EXEC_ROOT` while the bash-oracle git resolution runs against `ORACLE_GIT_ROOT` — **via the two per-lane root knobs Plan 03 added to the FROZEN seam (`WIKI_EXEC_ROOT` + `WIKI_ORACLE_GIT_ROOT`), which this gate merely SETS AS ENV VARS (it does NOT edit the seam — resolving the cycle-5 freeze/interface deadlock).** Concretely, EXPORT `WIKI_EXEC_ROOT="$STAGED_EXEC_ROOT"` (so `_oracle_exec_root` → the seam runs `bash "$STAGED_EXEC_ROOT/bin/<tool>.sh"` + `PYTHONPATH=$STAGED_EXEC_ROOT/src` + reads `$STAGED_EXEC_ROOT/tests/ported.manifest` for the py leg — the STAGED versions) AND `WIKI_ORACLE_GIT_ROOT="$ORACLE_GIT_ROOT"` (so `_oracle_git_root` → the seam's `oracle-worktree.sh` runs `git -C "$ORACLE_GIT_ROOT" worktree add`/`rev-parse` + reads `$ORACLE_GIT_ROOT/tests/freeze-baseline.sha` against the real .git). Document in a header comment WHY both roots are needed: the materialized staged tree has NO .git (so the oracle's `git worktree add`/`rev-parse` would fail there), and pointing everything at the real repo would run WORKING-tree (not staged) tool bodies — the two knobs are what make the staged py leg AND the oracle git resolution both succeed (cycle-4 finding #4 + cycle-6 fix #1/#2). This gate CONSUMES the frozen knobs; it never touches `tests/lib/invoke_tool.sh` or `tests/lib/oracle-worktree.sh`.
- Run the parity check on the affected tool(s) with the split roots:
  - Map each staged `bin/<tool>.sh` / `src/compendium/<tool>.py` to the suite(s) covering it where a clean mapping exists; otherwise the SAFE default is to run the enumerated `tests/run-all-suites.sh` under both impls — **EXCLUDING ONLY the two RECURSIVE HOOK SELF-TESTS from the hook fallback (cycle-6 fix #3 — NOT the whole phase-24 suite):** pass the TEST-level exclusion Plan 05's runner supports — `--exclude-test test_precommit_hooks.sh --exclude-test test_staged_parity_index.sh` (the only two phase-24 tests that re-invoke this gate). Phase-22 STAYS in the enumerated suite list, so EVERY other phase-24 golden (the richest 4-channel characterization suite — the only rich parity signal that runs on the never-pushed private migration branches) STILL executes on this local gate. Do NOT use a whole-suite `--exclude-suite 22` / `WIKI_PARITY_SUITES` drop (Codex cycle-4 finding: that removes the richest goldens from the only gate on private branches). Header comment: excluding ONLY the recursive hook self-tests is the PRIMARY recursion break that ALSO keeps the gate's parity path reachable AND keeps every non-recursive phase-24 golden in the gate (the `WIKI_PARITY_GATE_ACTIVE` guard remains as a secondary belt-and-suspenders bound).
  - Run the two capture legs with the per-lane root knobs set as ENV VARS (CONCRETE wiring — replaces the cycle-5 `<staged-tool-bodies-from-STAGED_EXEC_ROOT>` placeholder; the bash leg reads bodies from the real repo so both legs' EXEC roots differ, which is what makes the STAGED py vs FROZEN bash differential real), and the recursive hook self-tests excluded:
```bash
EXCL="--exclude-test test_precommit_hooks.sh --exclude-test test_staged_parity_index.sh"
# bash leg: exec-root = the real repo (frozen bash bodies via the worktree oracle); git-root = the real repo.
if WIKI_IMPL=bash WIKI_EXEC_ROOT="$ORACLE_GIT_ROOT" WIKI_ORACLE_GIT_ROOT="$ORACLE_GIT_ROOT" \
     bash "$ORACLE_GIT_ROOT/tests/run-all-suites.sh" --capture-channels "$BASHCH" $EXCL; then bl_rc=0; else bl_rc=$?; fi
# py leg: exec-root = the STAGED index (staged shim + src + ported.manifest); git-root = the real repo (.git for the oracle).
if WIKI_IMPL=py   WIKI_EXEC_ROOT="$STAGED_EXEC_ROOT" WIKI_ORACLE_GIT_ROOT="$ORACLE_GIT_ROOT" \
     bash "$ORACLE_GIT_ROOT/tests/run-all-suites.sh" --capture-channels "$PYCH" $EXCL; then py_rc=0; else py_rc=$?; fi
# channel comparison (pid-independent pairing — cycle-6 fix #4): FAILS on any channel byte-divergence OR unpaired key.
if bash "$ORACLE_GIT_ROOT/tests/run-all-suites.sh" --require-parity "$BASHCH" "$PYCH"; then rp_rc=0; else rp_rc=$?; fi
```
Run `run-all-suites.sh` FROM the real repo (`$ORACLE_GIT_ROOT`) so the runner + test_*.sh are the fixed ones; only the py leg's TOOL BODIES come from `$STAGED_EXEC_ROOT` via `WIKI_EXEC_ROOT` (the seam's `_oracle_exec_root`). Capture each leg's exit with the CORRECT `if cmd; then rc=0; else rc=$?; fi` idiom (REVIEWS HIGH#2). The `--require-parity` step (Plan 05) byte-compares the captured channels across impls, pairing by the pid-STRIPPED identity so the two runs' differing PIDs still pair (cycle-6 fix #4). If any of `bl_rc`/`py_rc`/`rp_rc` is nonzero, the gate blocks.
  - If any run or the parity comparison FAILS, print the failing tool/suite + a remediation note to stderr and `exit 2` (block the commit). On success print an OK line and `exit 0`.
- Honor an escape hatch `PARITY_GATE_SKIP=1` (documented) for the rare case a developer must commit WIP without parity — exits 0 with a loud stderr warning. Header comment (N-7): its use must be recorded in the plan SUMMARY. NOTE: in Phase 24 `ported.manifest` is empty so `WIKI_IMPL=py` falls through to bash and parity is trivially green — the gate is fully active but has nothing to diverge; it lights up real signal per Phase-23 port.
- `usage()` heredoc; make executable; header comment explains it is the LOCAL-only parity enforcement REVIEWS HIGH#6 requires (CI never runs on the private branches), tests the STAGED INDEX via STAGED_EXEC_ROOT while the oracle git runs against ORACLE_GIT_ROOT (finding #4), excludes phase-24 from the hook fallback (finding #5), and is re-entrancy-guarded (finding #5).

**`tests/phase-24/test_precommit_hooks.sh` — the BEHAVIOR-level hook self-test (REVIEWS HIGH#2 + HIGH#6), recursion-safe + NON-VACUOUS run-assertion (cycle-3 finding #5 + cycle-4 finding #5).** This proves the hook LOGIC is correct, not merely that strings are present. Drive the hook (or the gates the hook calls) in isolated git contexts and assert BEHAVIOR:
1. **Freeze skip-branch reached (REVIEWS HIGH#2):** drive the unreachable-baseline path THROUGH the freeze step as the hook invokes it. Set up a context where `bin/check-common-freeze.sh --staged` returns exit 3, run the EXACT capture+branch snippet the hook uses, and assert the SKIP message is emitted AND the commit is ALLOWED (the hook does NOT hard-block on exit 3). WHY PRE-FIX-FAILING: against the OLD `if ! cmd; then fc_rc=$?` idiom, `fc_rc` is always 0 on the negated branch → the skip path is dead → the hook hard-blocks. So this FAILS on the old idiom and PASSES only with `if cmd; then fc_rc=0; else fc_rc=$?; fi`. Assert the OBSERVABLE outcome (skip message + non-block), NOT the strings.
2. **Freeze hard-block on real drift:** stage a change to a FROZEN file, run the hook's freeze step, assert it BLOCKS (exit non-zero) with the frozen-surface message.
3. **Parity gate EXECUTES the parity path — NON-VACUOUS (REVIEWS HIGH#6 + cycle-4 finding #5):** stage a change under `src/compendium/` (or flip a `tests/ported.manifest` entry) in an isolated context, run `bin/check-staged-parity.sh` with `WIKI_PARITY_GATE_ACTIVE` UNSET on first entry, and assert it REACHES the materialize+compare parity path — i.e. assert it MATERIALIZES STAGED_EXEC_ROOT (e.g. it `git checkout-index`'d a temp tree) AND invokes `run-all-suites.sh`/produces channel-capture output — NOT the WIKI_PARITY_GATE_ACTIVE skip branch and NOT the "no migration-relevant change" fast-skip. Because the gate EXCLUDES ONLY the recursive hook self-tests from its fallback (via `--exclude-test test_precommit_hooks.sh --exclude-test test_staged_parity_index.sh` — NOT the whole phase-24 suite; cycle-6 fix #3), running this self-test does NOT re-enter the gate → the parity path runs ONCE and the assertion is GENUINE (not vacuous), while every other phase-24 golden still runs. WHY PRE-FIX-FAILING: against the cycle-3 design where the gate's fallback re-ran phase-24, the nested `test_precommit_hooks.sh` inherited `WIKI_PARITY_GATE_ACTIVE=1` and short-circuited → the "parity path RUNS" assertion was vacuous-or-failing. With phase-24 excluded, the assertion is non-vacuous: assert a parity-path marker (materialize occurred + run-all invoked) is present AND the skip-branch marker is ABSENT.
4. **Parity gate skips a non-migration commit:** stage a change to a non-`bin`/non-`src/compendium`/non-`ported.manifest` file, assert the gate takes the fast skip path (exit 0, "skipped" message).
Make executable; isolated git ops so the self-test does not pollute the working tree. It is AUTO-DISCOVERED by `tests/phase-24/run.sh`'s `test_*.sh` glob (Plan 04's aggregator) with NO run.sh edit.

**`tests/phase-24/test_staged_parity_index.sh` — the NEGATIVE staged-blob test with a SEEDED manifest entry (cycle-3 finding #4 + cycle-4 finding #4) + the BOUNDED-TERMINATION + parity-path-executes test (cycle-3 finding #5 + cycle-4 finding #5).** In isolated git fixture repos (do NOT pollute the real tree):
1. **Staged-broken + working-good is BLOCKED, with the Python leg GENUINELY exercised (cycle-3 finding #4 + cycle-4 finding #4 — the core proof):** in an isolated fixture repo wired with the gate, (a) SEED a temporary `tests/ported.manifest` entry for a test tool (e.g. `faketool`) so `WIKI_IMPL=py` actually runs the Python/shim leg for it (an EMPTY manifest → the py leg falls through to bash → no divergence → the block never triggers → vacuous); (b) create the migration-relevant file (`bin/faketool.sh` shim + `src/compendium/faketool.py`) in a state that DIVERGES under py vs the bash oracle, `git add` it (STAGE the broken/divergent version); (c) OVERWRITE the working-tree copy with a PASSING (parity-matching) version, leave it UNSTAGED. Run `bin/check-staged-parity.sh` and assert it BLOCKS the commit (exit non-zero) — proving (i) it tested the STAGED blob (divergent), NOT the passing working tree (STAGED_EXEC_ROOT split — finding #4), and (ii) the Python leg genuinely ran (the seeded manifest entry made py != bash — finding #4). WHY PRE-FIX-FAILING: against the cycle-3 gate, EITHER it tested the working tree (the passing copy → exit 0 → block assertion FAILS) OR the empty manifest meant the py leg never ran (no divergence → exit 0 → block assertion FAILS). It PASSES only once the gate materializes STAGED_EXEC_ROOT, resolves the oracle against ORACLE_GIT_ROOT, AND the seeded manifest entry makes the Python leg run.
2. **Staged-good passes (the inverse):** stage a PARITY-MATCHING version (with the same seeded manifest entry), run the gate, assert it does NOT block (exit 0) — confirming the materialized-index gate is not over-blocking.
3. **Bounded termination (cycle-3 finding #5 — the recursion proof):** run `timeout 120 bash tests/phase-24/test_precommit_hooks.sh` and assert it EXITS 0 within the bound (does NOT hit the timeout / does NOT recurse). WHY PRE-FIX-FAILING: against the cycle-3 design (phase-24 NOT excluded from the fallback), the path recurses (gate fallback re-runs phase-24 → re-runs test_precommit_hooks.sh) and either hits the timeout or relies on the guard to short-circuit (making the run-assertion vacuous) — so the bounded-termination + non-vacuous-run-assertion both FAIL pre-fix. It PASSES once phase-24 is EXCLUDED from the fallback (the parity path runs once, non-vacuously, and terminates). Assert the timeout did NOT fire: `timeout` returns 124 on timeout — assert the captured rc is 0, not 124.
4. **Parity path executes (cycle-4 finding #5 — the non-vacuous proof, paired with #3):** additionally assert (here or by relying on test_precommit_hooks.sh step 3) that the gate REACHED the materialize+compare path (NOT the WIKI_PARITY_GATE_ACTIVE skip branch) on the first entry — e.g. grep the gate's stderr/stdout for a materialize marker and assert the re-entry-skip marker is ABSENT. Both halves (path-executes AND recursion-terminates) must hold simultaneously.
Make executable; auto-discovered by `tests/phase-24/run.sh`'s glob.
  </action>
  <verify>
    <automated>chmod +x bin/check-staged-parity.sh tests/phase-24/test_precommit_hooks.sh tests/phase-24/test_staged_parity_index.sh && bash bin/check-staged-parity.sh; echo "staged-parity (no staged change) exit=$?"; bash tests/phase-24/test_precommit_hooks.sh; echo "hook-behavior selftest exit=$?"; bash tests/phase-24/test_staged_parity_index.sh; echo "staged-index+bounded selftest exit=$?"</automated>
  </verify>
  <acceptance_criteria>
    - `test -x bin/check-staged-parity.sh` exits 0 (the local parity gate exists — REVIEWS HIGH#6)
    - `grep -q 'git diff --cached --name-only' bin/check-staged-parity.sh && grep -qE 'bin/|src/compendium|ported.manifest' bin/check-staged-parity.sh` exits 0 (it triggers on migration-relevant staged paths)
    - `grep -qE 'git checkout-index|git archive --cached' bin/check-staged-parity.sh && grep -q 'trap' bin/check-staged-parity.sh` exits 0 (cycle-3 finding #4: materializes the STAGED INDEX into a temp tree with trap cleanup — NOT the working tree)
    - `grep -q 'STAGED_EXEC_ROOT' bin/check-staged-parity.sh && grep -q 'ORACLE_GIT_ROOT' bin/check-staged-parity.sh` exits 0 (cycle-4 finding #4: the EXPLICIT split — staged-exec tree [no .git] vs the real repo [.git] for the oracle git commands)
    - `grep -q 'WIKI_EXEC_ROOT="$STAGED_EXEC_ROOT"' bin/check-staged-parity.sh && grep -q 'WIKI_ORACLE_GIT_ROOT="$ORACLE_GIT_ROOT"' bin/check-staged-parity.sh` exits 0 (CYCLE-6 fix #2: the gate CONSUMES Plan 03's frozen per-lane root knobs as env vars — py leg exec-root=STAGED, oracle git-root=real repo — no `<staged-tool-bodies-from-STAGED_EXEC_ROOT>` placeholder remains)
    - `! grep -qE 'staged-tool-bodies-from-STAGED_EXEC_ROOT|<staged-tool-bodies' bin/check-staged-parity.sh` (the cycle-5 UNBUILDABLE placeholder is GONE — replaced with concrete WIKI_EXEC_ROOT/WIKI_ORACLE_GIT_ROOT wiring — cycle-6 fix #2)
    - `! grep -qE 'tests/lib/invoke_tool.sh|tests/lib/oracle-worktree.sh' bin/check-staged-parity.sh || grep -qiE 'CONSUME|frozen|do not edit|never edit' bin/check-staged-parity.sh` (the gate CONSUMES the frozen seam via env vars, it does not edit it — cycle-6 fix #1)
    - `grep -qiE 'no .git|materialized.*no.*git|oracle.*real repo|real .git|git worktree.*ORACLE_GIT_ROOT|ORACLE_GIT_ROOT.*git' bin/check-staged-parity.sh` exits 0 (the header documents WHY the split is needed — the materialized tree has no .git the oracle requires — cycle-4 finding #4)
    - `! grep -qE 'git stash --keep-index' bin/check-staged-parity.sh` (the stash mechanism is NOT used as the primary — checkout-index is safer for an LLM-executed hook — cycle-3 finding #4)
    - `grep -q 'WIKI_PARITY_GATE_ACTIVE' bin/check-staged-parity.sh` exits 0 (cycle-3 finding #5: re-entrancy guard env var set/checked — belt-and-suspenders)
    - `grep -q -- '--exclude-test test_precommit_hooks.sh' bin/check-staged-parity.sh && grep -q -- '--exclude-test test_staged_parity_index.sh' bin/check-staged-parity.sh` exits 0 (CYCLE-6 fix #3: the gate excludes ONLY the two recursive hook self-tests via the TEST-level knob — phase-24 stays in the run so its richest goldens still execute)
    - `! grep -qE '\-\-exclude-suite|WIKI_PARITY_SUITES' bin/check-staged-parity.sh` (the whole-phase-24-suite drop is GONE — Codex cycle-4 finding: dropping the whole suite removes the richest goldens from the only private-branch gate — cycle-6 fix #3)
    - `grep -q 'run-all-suites.sh' bin/check-staged-parity.sh && grep -q 'require-parity' bin/check-staged-parity.sh` exits 0 (it runs the affected tool's parity + the channel comparison)
    - `grep -qE 'if .*; then [a-z_]*rc=0; else [a-z_]*rc=\$\?; fi' bin/check-staged-parity.sh` exits 0 (the CORRECT exit-capture idiom — REVIEWS HIGH#2)
    - `grep -qE 'PARITY_GATE_SKIP' bin/check-staged-parity.sh` exits 0 (documented escape hatch)
    - `bash bin/check-staged-parity.sh` exits 0 with nothing migration-relevant staged (the fast skip path)
    - `test -x tests/phase-24/test_precommit_hooks.sh` exits 0
    - `bash tests/phase-24/test_precommit_hooks.sh` exits 0 (PRE-FIX-FAILING: the skip branch is reached on an unreachable baseline [HIGH#2 hook leg] AND the parity gate EXECUTES the parity path [reaches materialize+compare, NOT the skip branch] on a staged src/compendium change without GitHub Actions [HIGH#6 + cycle-4 finding #5 — non-vacuous] — both asserted by BEHAVIOR, not string-grep)
    - `grep -qiE 'materializ|STAGED_EXEC_ROOT|reached.*parity|parity path.*run|NOT.*skip|skip.*branch.*absent' tests/phase-24/test_precommit_hooks.sh` exits 0 (the self-test asserts the parity path EXECUTED, not the re-entry skip branch — cycle-4 finding #5)
    - `grep -qiE 'behavior|outcome|assert.*skip|assert.*block' tests/phase-24/test_precommit_hooks.sh` exits 0 (the self-test asserts behavior, not merely string presence — REVIEWS HIGH#2)
    - `test -x tests/phase-24/test_staged_parity_index.sh` exits 0
    - `grep -q 'git add' tests/phase-24/test_staged_parity_index.sh && grep -qiE 'staged.*broken|broken.*staged|working.*good|unstaged|diverge' tests/phase-24/test_staged_parity_index.sh` exits 0 (the negative test stages broken/divergent + leaves a passing unstaged version — cycle-3 finding #4)
    - `grep -qiE 'ported.manifest|faketool|seed.*manifest|manifest.*entry' tests/phase-24/test_staged_parity_index.sh` exits 0 (the negative test SEEDS a temporary ported.manifest entry so the Python leg genuinely runs — cycle-4 finding #4; an empty manifest would make the test vacuous)
    - `grep -qE 'timeout [0-9]+ bash tests/phase-24/test_precommit_hooks.sh' tests/phase-24/test_staged_parity_index.sh && grep -qE '!= 124|== 0|-eq 0' tests/phase-24/test_staged_parity_index.sh` exits 0 (the bounded-termination test runs the recursion-prone path under timeout and asserts it exits 0 within the bound — cycle-3 finding #5)
    - `bash tests/phase-24/test_staged_parity_index.sh` exits 0 (PRE-FIX-FAILING: staged-broken+working-good with a SEEDED manifest entry is BLOCKED by a genuine Python-leg divergence [finding #4] AND the hook self-test terminates within the timeout while its parity-path run-assertion is non-vacuous [finding #5] — both asserted by behavior)
  </acceptance_criteria>
  <done>bin/check-staged-parity.sh MATERIALIZES the STAGED INDEX into STAGED_EXEC_ROOT (git checkout-index, no .git, trap cleanup) where the staged tool bodies execute, while the seam's worktree-oracle git commands run against ORACLE_GIT_ROOT (the real repo, .git intact) — so the staged py leg AND the oracle git resolution both work (cycle-4 finding #4); it runs the affected tool's parity suites + the --require-parity channel comparison, EXCLUDING ONLY the two recursive hook self-tests from the hook fallback via `--exclude-test` (cycle-6 fix #3 — phase-24 stays in the run, keeping its richest goldens) so the self-test's run-assertion is non-vacuous, is RE-ENTRANCY-GUARDED via WIKI_PARITY_GATE_ACTIVE as a secondary bound, and uses the CORRECT `if cmd; then rc=0; else rc=$?; fi` idiom (REVIEWS HIGH#2 + HIGH#6 + cycle-3 findings #4, #5 + cycle-4 findings #4, #5); the hook-behavior self-test proves the freeze skip-branch is reached + the parity gate EXECUTES the parity path (not the skip branch); the staged-index test proves a staged-broken/working-good commit is BLOCKED with a SEEDED manifest entry + broken module so the Python leg genuinely runs (finding #4) and the hook self-test terminates within a timeout bound with a non-vacuous run-assertion (finding #5) — all asserted by behavior, not string-grep.</done>
</task>

<task type="auto">
  <name>Task 3: Wire freeze + parity into .githooks/pre-commit (correct exit-capture) + the common-freeze CI job + create the phase-24-freeze tag</name>
  <files>.githooks/pre-commit, .github/workflows/parity.yml</files>
  <read_first>
    - .githooks/pre-commit (READ FULLY — the real local gate: the sync-claude/gen-skills/lint --staged chain + the WR-05 "do not swallow stderr" + WR-03 convergence comments; the freeze + parity checks are ADDED to this chain)
    - bin/check-common-freeze.sh (Task 1 — the guard the hook + CI run; the --staged flag for the hook + the exit-3 skip code)
    - bin/check-staged-parity.sh (Task 2 — the local parity gate the hook runs; testing the staged index via STAGED_EXEC_ROOT/ORACLE_GIT_ROOT + re-entrancy guard + phase-24-excluded fallback)
    - tests/freeze-baseline.sha (Task 1 — the committed baseline)
    - .github/workflows/parity.yml (from Plan 05 — the parity-suites + parity-equivalence jobs; add the common-freeze job alongside)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (HIGH#2 [correct exit-capture idiom in the hook], HIGH#6 [parity must run on the real work = pre-commit], HIGH#7 [^{commit} for the tag], HIGH#12 [non-vacuous CI guard])
  </read_first>
  <action>
**Wire the freeze check into `.githooks/pre-commit` with the CORRECT exit-capture idiom (REVIEWS HIGH#2 — the hook-leg fix).** The pre-commit hook is the ONLY gate that runs on the real, never-pushed Phase-23 work. Add a freeze step to the existing hook chain (AFTER sync-claude/gen-skills, BEFORE or alongside the lint --staged step), in the hook's defensive style. The step runs the STAGED-mode guard. Use the CORRECT idiom — capture status WITHOUT `!` so the exit-3 SKIP code is preserved:
```bash
# Phase 24 / D-07: freeze guard over STAGED changes (REVIEWS HIGH#2 + HIGH#12 — the real local gate; CI never
# runs on the private Phase-23 branches). Blocks a commit that touches the frozen common/ surface unless the
# ownership-rebase escape hatch (FREEZE_ALLOW_REBASE=1) is set. Do NOT swallow stderr (WR-05 style).
# CORRECT exit capture (REVIEWS HIGH#2): `if cmd; then fc_rc=0; else fc_rc=$?; fi` — NOT `if ! cmd; then fc_rc=$?`
# (under `!`, $? in the then-branch is the status of the negation = always 0, so the exit-3 skip path goes DEAD).
if bash bin/check-common-freeze.sh --staged; then
    fc_rc=0
else
    fc_rc=$?
fi
if [ "$fc_rc" = "3" ]; then
    echo "freeze guard skipped (baseline unreachable) — proceeding." >&2     # neutral SKIP, not a block
elif [ "$fc_rc" != "0" ]; then
    echo "" >&2
    echo "Frozen surface touched (src/compendium/common, pyproject.toml, the parity seam/oracle/goldens)." >&2
    echo "Phase-22 froze this surface. If this is the sanctioned ownership-rebase addition, re-commit with" >&2
    echo "FREEZE_ALLOW_REBASE=1 and bump tests/freeze-baseline.sha + 'git tag -f phase-24-freeze' in the SAME commit." >&2
    exit 1
fi
```
(`set -euo pipefail` is already on; the `if cmd; then ...; else fc_rc=$?; fi` form is set -e-safe AND preserves the distinct exit-3 code — this is the exact bug REVIEWS HIGH#2 flagged in the old `if ! cmd; then fc_rc=$?` form.)

**Wire the LOCAL parity gate into `.githooks/pre-commit` (REVIEWS HIGH#6).** AFTER the freeze step, add the parity gate with the SAME correct exit-capture idiom:
```bash
# Phase 24 / REVIEWS HIGH#6: LOCAL parity gate. CI parity runs ONLY in GitHub Actions, which never runs on the
# never-pushed private Phase-23 branches — so a port could commit locally with no parity check. This runs the
# affected tool's parity suites against the MATERIALIZED STAGED INDEX (STAGED_EXEC_ROOT, cycle-4 finding #4) while
# the oracle git resolution runs against ORACLE_GIT_ROOT (the real .git), when bin/ / src/compendium/ /
# tests/ported.manifest is staged. Excludes ONLY the recursive hook self-tests from its fallback (--exclude-test) + re-entrancy-guarded (cycle-6 fix #3).
# Skip via PARITY_GATE_SKIP=1.
if bash bin/check-staged-parity.sh; then
    pg_rc=0
else
    pg_rc=$?
fi
if [ "$pg_rc" != "0" ]; then
    echo "" >&2
    echo "Parity gate failed for a staged migration change (bin/ / src/compendium/ / ported.manifest)." >&2
    echo "The Python impl diverges from the held-fixed bash oracle. Fix parity or commit with PARITY_GATE_SKIP=1 (WIP only)." >&2
    exit 1
fi
```
Keep the rest of the hook unchanged. Order: sync-claude → gen-skills → freeze → parity → lint --staged (freeze before parity so a frozen-surface violation is caught first; both before lint). Note in a comment this is the enforcement REVIEWS HIGH#2 + HIGH#6 require on the real work.

**Wire the `common-freeze` job into `.github/workflows/parity.yml`** (a NEW job + NEW name — not one of the 6 required names; Pitfall 4):
- `actions/checkout@v6` with `fetch-depth: 0` (the guard needs history back to the baseline SHA; the committed `tests/freeze-baseline.sha` is the resolvable base since the local-only tag is not pushed).
- Step: `run: bash bin/check-common-freeze.sh` — resolves the baseline via `^{commit}` (HIGH#7), surfaces stderr, exits 2 on drift / 3 (SKIP) on unreachable. In the CI step, treat exit 3 as a NEUTRAL logged skip (e.g. `if bash bin/check-common-freeze.sh; then :; else rc=$?; [ "$rc" = 3 ] && echo 'freeze baseline unreachable on this branch — skipping (not a pass)' && exit 0 || exit $rc; fi`) — using the SAME non-`!` idiom so the exit-3 code is preserved. (On the private repo this never runs; this keeps the public template honest.)
- Trigger on `pull_request`.
Model on the existing `parity-suites` job. Confirm the file parses with `yaml.safe_load`. Do NOT rename `parity-suites`/`parity-equivalence` or any required check.

**Create the `phase-24-freeze` annotated git tag (the final pinning action).** As the LAST step of this plan (and of Phase 24), create the local-only annotated tag at the PRE-PLAN-06 baseline commit (the SHA in `tests/freeze-baseline.sha`):
```bash
BASE="$(cat tests/freeze-baseline.sha)"
git tag -a phase-24-freeze "$BASE" -m "Phase 24 frozen-foundation baseline: common/ + pyproject.toml + the parity seam/oracle/goldens/manifest (v1.5 migration parity oracle)"
```
This tag is LOCAL-ONLY — do NOT push it to origin (origin is the public template; pushing leaks `.planning/`+`wiki-local/`). Confirm `git rev-parse phase-24-freeze^{commit}` equals `cat tests/freeze-baseline.sha` (the N-4 tag-vs-SHA equality the guard + oracle enforce — create the tag AT the committed SHA so they agree). Document the final SHA in the SUMMARY. NOTE: once this tag exists, Plan 03's worktree oracle resolves it (via `^{commit}`) and checks out the FROZEN bin/ — so `WIKI_IMPL=bash` runs the frozen bash even after Phase 25 flips shims.
  </action>
  <verify>
    <automated>bash -n .githooks/pre-commit && grep -q 'check-common-freeze' .githooks/pre-commit && grep -q 'check-staged-parity' .githooks/pre-commit && python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/parity.yml')); assert 'common-freeze' in d['jobs'], d['jobs'].keys(); print('common-freeze job present')" && git rev-parse -q --verify "phase-24-freeze^{commit}" && diff <(git rev-parse "phase-24-freeze^{commit}") <(cat tests/freeze-baseline.sha) && echo "tag^{commit} == committed SHA"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q 'check-common-freeze' .githooks/pre-commit` exits 0 (the freeze guard is in the REAL local gate)
    - `grep -q 'check-staged-parity' .githooks/pre-commit` exits 0 (the LOCAL parity gate is in the real gate — REVIEWS HIGH#6)
    - `grep -q -- '--staged' .githooks/pre-commit` exits 0 (the hook runs the staged-mode freeze guard)
    - `grep -qE 'if bash bin/check-common-freeze.sh --staged; then[[:space:]]*$' .githooks/pre-commit || grep -qE 'if bash bin/check-common-freeze.sh --staged; then fc_rc=0' .githooks/pre-commit` exits 0 (CORRECT non-`!` capture form — REVIEWS HIGH#2)
    - `! grep -qE 'if ! bash bin/check-common-freeze.sh' .githooks/pre-commit` (the BUGGY `if ! cmd; then fc_rc=$?` form is NOT used for the freeze step — REVIEWS HIGH#2)
    - `grep -qE 'fc_rc=0' .githooks/pre-commit && grep -qE 'fc_rc=\$\?' .githooks/pre-commit && grep -qE '\[ "\$fc_rc" = "3" \]' .githooks/pre-commit` exits 0 (the exit-3 skip branch is reachable, set from the else branch)
    - `grep -q 'FREEZE_ALLOW_REBASE' .githooks/pre-commit` exits 0 (the escape-hatch path documented in the hook message)
    - `bash -n .githooks/pre-commit` exits 0 (the hook still parses)
    - `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/parity.yml')); assert 'common-freeze' in d['jobs']"` exits 0 (CI job wired)
    - `grep -q 'check-common-freeze.sh' .github/workflows/parity.yml && grep -q 'fetch-depth: 0' .github/workflows/parity.yml` exits 0 (CI runs the guard with full history)
    - `python3 -c "import yaml; d=yaml.safe_load(open('.github/workflows/parity.yml')); req={'lint','privacy-leak','strict','skills-check','neutrality','setup-parity'}; assert not (req & set(d['jobs'].keys())), 'a required name leaked into parity.yml'"` exits 0
    - `git rev-parse -q --verify "phase-24-freeze^{commit}"` exits 0 (the local-only tag exists, deref via ^{commit})
    - `diff <(git rev-parse "phase-24-freeze^{commit}") <(cat tests/freeze-baseline.sha)` shows no differences (tag^{commit} SHA == committed SHA — the N-4 equality the guard + oracle enforce)
    - `bash bin/check-common-freeze.sh` exits 0 (guard runs clean at the freeze baseline at post-Plan-06 HEAD — incl. the tag==SHA equality branch)
  </acceptance_criteria>
  <done>the freeze guard + the LOCAL parity gate (staged-index via STAGED_EXEC_ROOT/ORACLE_GIT_ROOT, phase-24-excluded fallback, re-entrancy-guarded) are both wired into .githooks/pre-commit (REVIEWS HIGH#6 + cycle-3 findings #4/#5 + cycle-4 findings #4/#5) using the CORRECT `if cmd; then fc_rc=0; else fc_rc=$?; fi` exit-capture idiom so the exit-3 skip branch is live (REVIEWS HIGH#2 — the buggy `if ! cmd; then fc_rc=$?` form is gone); the common-freeze CI job is added to parity.yml (fetch-depth 0, ^{commit} resolve, exit-3 skip neutral) without touching any required-check name; the local-only phase-24-freeze annotated tag is created at the PRE-PLAN-06 baseline and agrees with tests/freeze-baseline.sha under ^{commit} (N-4 equality); the frozen-foundation baseline is pinned LAST and supplies the ref Plan 03's worktree oracle reads.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| frozen surface ↔ Phase-23 plan branches | The guard is the enforcement boundary that keeps parallel ports off the shared surface |
| pre-commit hook ↔ the real work | CI never runs on the private repo; the hook is the only gate that does (REVIEWS HIGH#6) |
| hook exit-capture ↔ skip vs block | A wrong `$?` capture makes the unreachable-baseline skip path dead, mis-handling a skip as a block (REVIEWS HIGH#2) |
| staged index ↔ working tree | The gate must test the STAGED CONTENT; testing the working tree lets an unstaged fix mask a broken staged commit (cycle-3 finding #4) |
| STAGED_EXEC_ROOT (no .git) ↔ ORACLE_GIT_ROOT (real .git) | The materialized staged tree has no .git the oracle's git worktree/rev-parse require; the split runs staged tool bodies from STAGED_EXEC_ROOT while the oracle git resolves against ORACLE_GIT_ROOT (cycle-4 finding #4) |
| empty ported.manifest ↔ the Python leg | With an empty manifest the py leg never runs (falls through to bash) → the negative test is vacuous; it must SEED a manifest entry (cycle-4 finding #4) |
| parity gate ↔ phase-24 self-test | The gate's fallback re-runs phase-24, which re-runs the gate's own self-test — unbounded recursion AND a vacuous run-assertion unless phase-24 is excluded from the fallback (cycle-3 finding #5 + cycle-4 finding #5) |
| local-only tag ↔ CI baseline resolution | Origin is the public template; the tag is never pushed, so CI resolves from the committed SHA (via ^{commit}); tag and SHA must be equal (N-4) |
| escape hatch ↔ uncontrolled frozen edits | FREEZE_ALLOW_REBASE / PARITY_GATE_SKIP must be deliberate, single-plan-owned, SUMMARY-recorded actions (N-7) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-22-21 | Tampering | a Phase-23 plan silently edits the frozen surface | mitigate | `check-common-freeze.sh` diffs the EXPLICIT frozen surface (common/ + pyproject + seam + oracle-worktree + conftest + goldens + manifest + runner) vs the baseline and exits 2. Wired into BOTH the pre-commit hook and CI. |
| T-22-41 | Repudiation | hook mis-handles the exit-3 skip as a hard block (wrong $? capture) | mitigate | The hook uses `if cmd; then fc_rc=0; else fc_rc=$?; fi` (REVIEWS HIGH#2); the buggy `if ! cmd; then fc_rc=$?` form is gone. `test_precommit_hooks.sh` drives the unreachable path through the hook and asserts the skip BEHAVIOR. |
| T-22-42 | Spoofing | a Phase-23 port commits locally with NO parity check (CI-only) | mitigate | `check-staged-parity.sh` runs the affected tool's parity suites + the channel comparison when bin//src/compendium//ported.manifest is staged, wired into pre-commit (REVIEWS HIGH#6); `test_precommit_hooks.sh` proves it EXECUTES the parity path on a staged src/compendium change without GitHub Actions (non-vacuous). |
| T-22-52 | Spoofing | an unstaged fix masks a broken staged commit (gate tests working tree) | mitigate | The gate MATERIALIZES the staged index into STAGED_EXEC_ROOT (git checkout-index, trap cleanup) and runs the staged tool bodies THERE (cycle-3 finding #4); `test_staged_parity_index.sh` stages a broken file + leaves a passing unstaged copy and asserts the commit is BLOCKED. |
| T-22-61 | Denial of Service | the oracle's git worktree/rev-parse fail because the staged tree has no .git | mitigate | The gate CONSUMES Plan 03's frozen per-lane root knobs as env vars — WIKI_EXEC_ROOT=$STAGED_EXEC_ROOT (materialized index, no .git, py bodies) + WIKI_ORACLE_GIT_ROOT=$ORACLE_GIT_ROOT (real repo, .git, oracle git) — so both legs work WITHOUT editing the frozen seam (cycle-4 finding #4 + cycle-6 fix #2). Acceptance asserts both env-var assignments + the placeholder's removal. |
| T-22-64 | Tampering | the freeze/interface deadlock makes the staged gate unbuildable (fix vs freeze mutually exclusive) | mitigate | The two seam knobs (Plan 03, wave 2) + the runner knobs (Plan 05, wave 4) are added UPSTREAM of the freeze; the baseline pins at PRE-PLAN-06 HEAD so the snapshot INCLUDES them; this gate CONSUMES them, never edits a frozen file, so check-common-freeze never trips (cycle-6 fix #1). |
| T-22-65 | Denial of Service | excluding the whole phase-24 suite removes the richest goldens from the only private-branch gate | mitigate | The gate excludes ONLY test_precommit_hooks.sh + test_staged_parity_index.sh via the TEST-level --exclude-test knob; phase-24 stays in the run so every other 4-channel golden still executes on the local gate (cycle-6 fix #3). Acceptance asserts the two --exclude-test flags + the absence of --exclude-suite. |
| T-22-62 | Spoofing | the negative staged test is vacuous (empty manifest → py leg never runs) | mitigate | The negative test SEEDS a temporary ported.manifest entry + a broken staged module so the Python parity leg genuinely runs; the block triggers on a REAL py-vs-bash divergence (cycle-4 finding #4). Acceptance asserts the manifest seed. |
| T-22-53 | Denial of Service | the parity self-test recurses infinitely (gate fallback re-runs phase-24) | mitigate | The gate EXCLUDES phase-24 from its hook fallback (primary break) + sets WIKI_PARITY_GATE_ACTIVE on entry (secondary bound); `test_staged_parity_index.sh` runs the recursion-prone path under `timeout` and asserts it exits 0 within the bound (not 124) (cycle-3 finding #5). |
| T-22-63 | Repudiation | the "parity path runs" self-assertion is vacuous (guard short-circuits the nested call) | mitigate | Excluding phase-24 from the fallback means the gate's parity path runs ONCE on first entry WITHOUT re-entering via phase-24, so `test_precommit_hooks.sh` asserts the materialize+compare path EXECUTED (not the skip branch) non-vacuously (cycle-4 finding #5). |
| T-22-22 | Repudiation | CI/guard cannot resolve the baseline → guard silently passes (vacuous) | mitigate | The guard resolves via `^{commit}`, never swallows the diff stderr, and exits a DISTINCT skip code 3 (never 0) on an unreachable baseline. The CI step treats exit 3 as a logged neutral skip, not a pass. |
| T-22-54 | Tampering | a stale tag silently overrides a bumped committed SHA | mitigate | check-common-freeze.sh REQUIRES tag^{commit} == tests/freeze-baseline.sha when both exist (exit 2 on mismatch — N-4), matching Plan 03's oracle; Task 3 creates the tag AT the committed SHA; the self-test proves the mismatch case fails. |
| T-22-33 | Tampering | the committed baseline SHA is circular / unsatisfiable | mitigate | The baseline is pinned at PRE-PLAN-06 HEAD: the committed SHA is the wave-4 surface commit, and Plan-06's own files are outside the frozen surface. The self-test proves clean=0 at the real pinned baseline. |
| T-22-23 | Elevation of Privilege | an escape hatch becomes a routine bypass | mitigate | `FREEZE_ALLOW_REBASE` requires a baseline bump in the SAME plan; `PARITY_GATE_SKIP` is WIP-only with a loud warning; both must be recorded in the plan SUMMARY (N-7). Owned by exactly one Phase-23 plan (D-09). |
| T-22-24 | Information Disclosure | pushing the freeze tag to origin leaks .planning/ + wiki-local/ | mitigate | The tag is explicitly LOCAL-ONLY and never pushed; the CI baseline is the committed SHA. |
</threat_model>

<verification>
- `bash bin/check-common-freeze.sh` exits 0 at the freeze baseline (clean — non-circular pre-Plan-06 pin; tag==SHA equality holds).
- `bash tests/phase-24/test_freeze_guard.sh` exits 0 (clean=0 / drift=2 / non-frozen=0 / escape-hatch=0 / unreachable=3 / tag-deref-clean / tag-vs-SHA-mismatch=2 — N-4).
- `bash tests/phase-24/test_precommit_hooks.sh` exits 0 (skip-branch reached on unreachable baseline [HIGH#2]; parity gate EXECUTES the parity path on a staged src/compendium change locally [HIGH#6 + cycle-4 finding #5 — non-vacuous] — asserted by behavior; recursion-safe).
- `bash tests/phase-24/test_staged_parity_index.sh` exits 0 (staged-broken+working-good with a SEEDED manifest entry is BLOCKED by a genuine py-leg divergence [finding #4]; the hook self-test terminates within a timeout bound with a non-vacuous run-assertion [finding #5]).
- `grep -q 'check-common-freeze' .githooks/pre-commit && grep -q 'check-staged-parity' .githooks/pre-commit` (both gates in the real local gate).
- `! grep -qE 'if ! bash bin/check-common-freeze.sh' .githooks/pre-commit` (the buggy capture form is gone — REVIEWS HIGH#2).
- `grep -qE 'git checkout-index' bin/check-staged-parity.sh && grep -q 'WIKI_EXEC_ROOT="$STAGED_EXEC_ROOT"' bin/check-staged-parity.sh && grep -q 'WIKI_ORACLE_GIT_ROOT="$ORACLE_GIT_ROOT"' bin/check-staged-parity.sh && grep -q 'WIKI_PARITY_GATE_ACTIVE' bin/check-staged-parity.sh && grep -q -- '--exclude-test test_precommit_hooks.sh' bin/check-staged-parity.sh` (staged-index materialization + the seam per-lane root knobs consumed as env vars [cycle-6 fix #2] + re-entrancy guard + ONLY-the-recursive-hook-self-tests excluded [cycle-6 fix #3] — cycle-3 findings #4/#5 + cycle-4 findings #4/#5).
- `parity.yml` parses and contains a `common-freeze` job with `fetch-depth: 0`; no required-check name leaked in.
- `git rev-parse phase-24-freeze^{commit}` == `cat tests/freeze-baseline.sha`.
</verification>

<success_criteria>
- D-07/D-08: the `check-common-freeze` guard fails fast (exit 2) on any change to the EXPLICIT frozen surface, wired into BOTH the pre-commit hook and CI; tag^{commit} == committed SHA enforced (N-4).
- REVIEWS HIGH#2 (hook leg): the pre-commit freeze step uses `if cmd; then fc_rc=0; else fc_rc=$?; fi` so the exit-3 skip branch is live; a behavior-level self-test proves it.
- REVIEWS HIGH#6: a LOCAL `check-staged-parity` gate runs the affected tool's parity suites + channel comparison on staged migration changes, wired into pre-commit (runs without GitHub Actions); a behavior-level self-test proves it EXECUTES the parity path.
- REVIEWS cycle-3 finding #4 + cycle-4 finding #4: the staged-parity gate tests the MATERIALIZED STAGED INDEX (STAGED_EXEC_ROOT, no .git, git checkout-index, trap cleanup) while the oracle git resolution runs against ORACLE_GIT_ROOT (the real .git) — so both legs work; the negative test SEEDS a temporary ported.manifest entry + a broken module so the Python leg genuinely runs and a staged-broken/working-good commit is BLOCKED by a real py-vs-bash divergence.
- REVIEWS cycle-3 finding #5 + cycle-4 finding #5 + CYCLE-6 fix #3: the local parity self-test does NOT recurse (ONLY the two recursive hook self-tests are excluded from the hook fallback via `--exclude-test` — phase-24 stays in the run so every other golden executes — as the primary break + WIKI_PARITY_GATE_ACTIVE as a secondary bound); a bounded-termination test proves it exits 0 under `timeout`; AND the self-test's parity-path run-assertion is NON-VACUOUS (it asserts the gate REACHED the materialize+compare path, not the re-entry skip branch). The acceptance asserts FUNCTIONING runner behavior (bounded termination + parity-path-executes), not exclusion-related text.
- The baseline is pinned at PRE-PLAN-06 HEAD (non-circular) as a local-only `phase-24-freeze` annotated tag + a committed fallback SHA, compared via `^{commit}`, with tag==SHA equality (N-4); the CI guard does not pass vacuously on an unreachable baseline.
- D-09: the ownership-rebase + PARITY_GATE_SKIP escape hatches are implemented + documented; their use is recorded in the SUMMARY (N-7); `tests/ported.manifest` excluded as a controlled per-port append; the L-2 conftest/manifest-growth-via-escape-hatch note is recorded.
- Freeze pinned LAST; supplies the ref Plan 03's worktree oracle reads.
- REVIEWS HIGH#2 (hook leg) + HIGH#6 (local parity gate) + cycle-3 finding #4 (staged-index) + finding #5 (recursion) + cycle-4 finding #4 (STAGED_EXEC_ROOT/ORACLE_GIT_ROOT split + seeded-manifest negative test) + cycle-4 finding #5 (phase-24-excluded fallback → non-vacuous run-assertion) resolved; N-4 (tag/SHA equality), N-7 (escape-hatch SUMMARY note) folded; cycle-1 HIGH#3/#6/#7/#12-design + MEDIUM (freeze-surface scope) preserved.
</success_criteria>

<output>
After completion, create `.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-06-SUMMARY.md`
</output>
</content>
