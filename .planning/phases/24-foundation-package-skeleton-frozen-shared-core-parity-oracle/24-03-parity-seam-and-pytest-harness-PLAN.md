---
phase: 22-foundation-package-skeleton-frozen-shared-core-parity-oracle
plan: 03
type: execute
wave: 2
depends_on: [01]
files_modified:
  - tests/lib/invoke_tool.sh
  - tests/lib/oracle-worktree.sh
  - tests/lib/normalize.sh
  - tests/lib/test_invoke_tool_selfparity.sh
  - tests/lib/test_invoke_tool_seterm.sh
  - tests/lib/test_oracle_scriptrelative.sh
  - tests/lib/test_capture_dir.sh
  - tests/lib/test_shim_smoke.sh
  - tests/lib/test_normalize.sh
  - tests/conftest.py
  - tests/test_conftest_fixtures.py
autonomous: true
requirements: [TEST-01, TEST-05]
user_setup: []

must_haves:
  decisions:
    - "D-11: WIKI_IMPL seam is a footprint-capturing invoke_tool (stdout+stderr+exit+file-tree)"
    - "D-12: invoke_tool includes a normalization layer for strict byte-comparison signal"
    - "D-13: minimal harness change — add the shared seam, leave per-phase make_*_repo helpers untouched"
  truths:
    - "invoke_tool BRANCHES on WIKI_IMPL: WIKI_IMPL=bash runs the held-fixed bash oracle FROM A git-worktree checked out at the pinned baseline ref (so each script's $0/${BASH_SOURCE[0]}-relative lib/REPO_ROOT resolution still finds the real bin/lib + schema/); WIKI_IMPL=py runs the python lane THROUGH THE bin/<tool>.sh SHIM for tools in tests/ported.manifest, else falls through to the bash oracle (addresses REVIEWS HIGH#1 + cycle-3 HIGH finding #3)"
    - "the held-fixed bash oracle is the FULL bin/-relative tree at the pinned ref (a git worktree at $(cat tests/freeze-baseline.sha) if it holds a reachable SHA, else HEAD) — NOT a cp of a single .sh into a flat dir; so audit-claims.sh (unconditional AUDIT_LIB_DIR=$(dirname BASH_SOURCE)/lib), brownfield.sh ($(dirname $0)/..), and gen-skills.sh ($SCRIPT_DIR/..) all resolve their libs and DO NOT abort under set -euo pipefail (addresses REVIEWS HIGH#1 keystone)"
    - "the py lane runs `bash <worktree-or-REPO_ROOT>/bin/<tool>.sh` (the ACTUAL shim, which itself execs python3 -m compendium.<tool>) for ported tools — NOT `python3 -m compendium.<tool>` directly — so a broken shim (bad PYTHONPATH / quoting / module name / exec) is CAUGHT on the parity path; the seam still exports PYTHONPATH=$(_oracle_exec_root)/src (= $REPO_ROOT/src by default; the exec-root knob only differs in Plan 06's staged gate) + LC_ALL=C + TZ=UTC ON THE NORMAL LANE so the shim inherits the cycle-1 hermeticity; the DEDICATED shim-smoke test is the ONLY place that clears the seam PYTHONPATH (to prove the shim OWNS its bootstrap) (addresses REVIEWS cycle-3 HIGH finding #3 + cycle-4 finding #3 residual)"
    - "the shim-smoke test runs with the seam's PYTHONPATH (and any other seam env that could mask the bootstrap) UNSET, so a shim MISSING its own checkout-hermetic PYTHONPATH bootstrap FAILS (ModuleNotFoundError) while the canonical shim (with its own bootstrap) SUCCEEDS — the seam's PYTHONPATH preload would otherwise MASK a bootstrap-free shim (addresses REVIEWS cycle-4 finding #3 / Codex new-HIGH #2)"
    - "a script-relative self-parity test runs audit-claims AND brownfield THROUGH a SUBCOMMAND THAT ACTUALLY REACHES lib/REPO_ROOT resolution (audit-claims a read-only --since/--format invocation past line 123; brownfield `scan --root <fixture>` past line 730 — NOT --help, which exits during arg-parse before the broken line) — this FAILS against the old cp-into-flat-dir mechanism (script aborts resolving tests/lib/oracle/lib) and PASSES only with the worktree mechanism (addresses REVIEWS HIGH#1 + cycle-3 finding #1 test-quality refinement)"
    - "invoke_tool returns 0 ALWAYS and exposes the real status ONLY via IT_EXIT, so the call-site form `invoke_tool X ARGS; rc=$IT_EXIT` does NOT abort a set -euo pipefail caller before rc is read (preserves REVIEWS HIGH#2)"
    - "when IT_CAPTURE_DIR is set, EVERY invoke_tool call self-records its normalized stdout/stderr/exit + a tree snapshot of the test's cwd into a COLLISION-PROOF keyed sub-dir whose key includes the tool name AND a per-subprocess discriminator (the calling test-file basename + the process PID) AND a per-call counter — so two DIFFERENT test_*.sh files in one suite that both invoke the same tool's first call produce DISTINCT keys (e.g. <suite>/<testbasename>-<pid>/lint-001) and NEVER overwrite a shared <suite>/lint-001; a black-box child test process (run-all-suites.sh) can collect per-call routed channels with NO <repo> arg from run-all (addresses REVIEWS cycle-3 HIGH finding #2 + cycle-4 finding #1 / Codex new-HIGH #1)"
    - "CYCLE-6 fix #1/#2 (per-lane root knobs): the seam exposes WIKI_EXEC_ROOT (py-lane shim body/src/ported.manifest) and WIKI_ORACLE_GIT_ROOT (the bash-oracle git worktree/rev-parse + freeze-baseline.sha), BOTH defaulting to $REPO_ROOT so the normal lane is unchanged; oracle-worktree.sh runs its git commands against $(_oracle_git_root), never a bare $REPO_ROOT — so Plan 06's staged gate can point the py leg at a materialized index (no .git) while the oracle git resolves against the real repo. These two knobs are part of the FROZEN contract surface (D-08) — Plan 06 CONSUMES them, never edits the seam (resolves the cycle-5 freeze/interface deadlock)"
    - "CYCLE-6 fix #4 (footprint root): the per-call tree snapshot uses _it_footprint_root (honors IT_FOOTPRINT_ROOT, else scans args for --root <dir>/--root=<dir>, else $PWD) instead of a bare capture_footprint \"$PWD\" — so the 86 --root-without-cd parity invocations capture the REAL fixture tree, not the test's own cwd"
    - "CYCLE-6 fix #4 (cross-run pairing): invoke_tool exposes it_pairing_key which strips the trailing -<pid> from a keyed segment; the <testbasename>-<pid> capture segment stays within-run collision-proof, and Plan 05's --require-parity pairs bash-run vs py-run captures by the pid-stripped <suite>/<testbasename>/<tool>-<NN> identity (else the two runs' differing PIDs never pair -> vacuous green)"
    - "CYCLE-6 fix #5 (manifest-driven shim enforcement): test_shim_smoke.sh adds a loop over tests/ported.manifest that asserts EACH real bin/<tool>.sh shim owns its own PYTHONPATH bootstrap (seam PYTHONPATH cleared); empty in Phase 24, it lights up per real ported shim in Phase 25 — the property is bound to the shipped population, not only the synthetic faketool exemplar; the loop mechanism is proven now via a WIKI_EXEC_ROOT-pointed scaffold with a seeded manifest entry"
    - "the normalizer redacts ONLY time-bearing timestamps (T..:..:.. now-values) — NOT contractual dates/IDs/hashes — and a self-test proves a WRONG contractual date/ID/hash is NOT masked (preserves cycle-1 HIGH#2 resolution)"
    - "the file-tree manifest records executable bits, symlink targets, and empty dirs (not just regular-file content+paths) (preserves cycle-1 MEDIUM resolution)"
    - "the oracle worktree path is PER-REPO/PER-BASELINE keyed (a hash of $REPO_ROOT + the baseline ref), NOT a single shared /tmp/wiki-oracle-worktree, so Phase-23 parallel clusters do not collide on one path (addresses REVIEWS cycle-3 N-5)"
    - "the oracle LOUDLY FAILS (not a silent HEAD fallback) when tests/ported.manifest is NON-EMPTY and baseline resolution would fall through to HEAD — a silent HEAD fallback while a tool is ported runs the python shim at HEAD on BOTH legs → false-green (the cycle-2 HIGH#1 collapse) (addresses REVIEWS cycle-3 N-4)"
    - "the golden on-disk layout is <case>/{stdout,stderr,exit,tree} — capture writes it and assertions read it, consistently"
    - "conftest.py git_repo/fixture_repo fixtures are behaviorally identical to make_bare_repo/make_fixture_repo (same identity, gpgsign=false, README exclusion, fresh tmp_path per call via tmp_path_factory, SEED_MSG single source of truth)"
  artifacts:
    - path: "tests/lib/invoke_tool.sh"
      provides: "The WIKI_IMPL seam (branches on impl + worktree-backed held-fixed oracle + ported manifest, py lane THROUGH the shim) + capture_footprint + assert_parity + IT_CAPTURE_DIR per-call self-record with a COLLISION-PROOF key (testbasename+pid+counter) + return-0/IT_EXIT-only set -e-safe exit capture"
      contains: "WIKI_IMPL"
    - path: "tests/lib/oracle-worktree.sh"
      provides: "Resolves/creates a PER-REPO-keyed git worktree at the pinned baseline ref (REVIEWS HIGH#1 keystone; N-5 per-repo path; N-4 loud-fail on ported+HEAD-fallthrough)"
      contains: "git worktree"
    - path: "tests/lib/normalize.sh"
      provides: "Time-bearing-only redaction filter (D-12)"
      contains: "normalize"
    - path: "tests/conftest.py"
      provides: "git_repo + fixture_repo fixtures (fresh tmp_path) + assert_golden_tree + skipif markers (TEST-05)"
      contains: "def git_repo"
    - path: "tests/lib/test_oracle_scriptrelative.sh"
      provides: "Pre-fix-failing self-parity test: audit-claims (real --since/--format) + brownfield (scan --root) run THROUGH the oracle past their lib/REPO_ROOT-resolution lines without aborting (REVIEWS HIGH#1 + finding #1 refinement)"
      contains: "invoke_tool audit-claims"
    - path: "tests/lib/test_invoke_tool_seterm.sh"
      provides: "set -e exit-capture self-test: `invoke_tool <nonzero-tool>; rc=$IT_EXIT; echo after` reaches the after line + rc is the real nonzero code (REVIEWS HIGH#2)"
    - path: "tests/lib/test_capture_dir.sh"
      provides: "Pre-fix-failing behavioral test for IT_CAPTURE_DIR per-call self-record + COLLISION-PROOF keying: two DIFFERENT simulated test-file subprocesses invoking the same tool's first call produce DISTINCT keyed dirs (no overwrite), AND an injected one-byte stdout divergence between two capture dirs is CAUGHT (REVIEWS cycle-3 HIGH finding #2 + cycle-4 finding #1)"
      contains: "IT_CAPTURE_DIR"
    - path: "tests/lib/test_shim_smoke.sh"
      provides: "Pre-fix-failing behavioral test for finding #3 + cycle-4 residual: run WITH THE SEAM PYTHONPATH UNSET — a bootstrap-free shim for a fake ported tool FAILS (module not found) while the canonical shim (own PYTHONPATH bootstrap) PASSES; AND a deliberately-broken shim is CAUGHT on the py lane — proving the py lane runs THROUGH the shim and the shim OWNS its bootstrap"
      contains: "WIKI_IMPL=py"
  key_links:
    - from: "tests/lib/invoke_tool.sh"
      to: "tests/lib/oracle-worktree.sh -> <worktree>/bin/<tool>.sh (bash) OR bash $REPO_ROOT/bin/<tool>.sh (py-via-shim, if ported)"
      via: "branch on WIKI_IMPL + lookup in tests/ported.manifest + worktree-backed oracle resolution; py lane runs the shim"
      pattern: "WIKI_IMPL"
    - from: "tests/lib/invoke_tool.sh"
      to: "$IT_CAPTURE_DIR/<testbasename>-<pid>/<tool>-<counter>/{stdout,stderr,exit,tree}"
      via: "per-call self-record when IT_CAPTURE_DIR is set, keyed by testbasename+pid+counter so cross-test-file collisions are impossible (run-all collects routed channels from black-box child processes — finding #2 + cycle-4 finding #1)"
      pattern: "IT_CAPTURE_DIR"
    - from: "tests/conftest.py git_repo"
      to: "make_bare_repo behavior"
      via: "git init -b main + fixture identity + gpgsign=false --allow-empty seed"
      pattern: "commit.gpgsign=false"
---

<objective>
Stand up the two parity-measurement systems with the seam ACTUALLY functioning as a bash-vs-py oracle for ALL tools — including the script-relative-path long poles (`audit-claims`, `brownfield`, `gen-skills`) AND the `.sh` shim contract itself:

(1) the `WIKI_IMPL=bash|py` `invoke_tool` seam in `tests/lib/` that BRANCHES on the variable — `bash` runs a held-fixed bash oracle FROM A GIT WORKTREE checked out at the pinned baseline ref (so each script's `$0`/`${BASH_SOURCE[0]}`-relative `bin/lib`/REPO_ROOT resolution still reaches the real `bin/lib` + `schema/`), `py` runs the python lane THROUGH THE `bin/<tool>.sh` SHIM for ported tools (else the oracle) — with a `return 0` + `IT_EXIT`-only set-e-safe exit capture, an `IT_CAPTURE_DIR` per-call self-record WITH A COLLISION-PROOF KEY (testbasename + pid + counter) so black-box child test processes can collect routed channels with NO cross-test-file overwrite, a time-bearing-only normalizer, and a 4-channel footprint capture that records exec bits/symlinks/empty dirs (TEST-01); and

(2) the pytest harness `conftest.py` mirroring `make_bare_repo`/`make_fixture_repo` with `assert_golden_tree` and Ollama/network `skipif` markers, with fresh per-call tmp dirs (TEST-05).

Each ships with self-tests, including a `set -e` exit-capture self-test, a script-relative oracle self-parity test (`audit-claims`/`brownfield` through the oracle via subcommands that REACH lib resolution), an `IT_CAPTURE_DIR` per-call-record + cross-test-file-collision behavioral test, a shim-smoke test (broken-shim-caught AND bootstrap-free-shim-caught-with-seam-PYTHONPATH-cleared), and a normalizer "wrong-value-not-masked" self-test.

Purpose: The seam is the entire parity oracle. CYCLE-2 REVIEWS HIGH#1 (keystone): the prior fix held the oracle as `cp bin/<tool>.sh tests/lib/oracle/<tool>.sh`, which BREAKS every script that resolves its libs relative to its own location — VERIFIED in source: `audit-claims.sh:123` `export AUDIT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"` (UNCONDITIONAL, no env override), `brownfield.sh:122/730/1365/1733` all `$(dirname "$0")/..`, `gen-skills.sh:30-31` `SCRIPT_DIR/..`. From a flat oracle dir these resolve `tests/lib/oracle/lib` (nonexistent) → `cd && pwd` fails under `set -euo pipefail` → abort. CYCLE-2 REVIEWS HIGH#2 (`set -e` capture): the prior seam ended with `return "$IT_EXIT"`, so `invoke_tool X; rc=$IT_EXIT` aborts a `set -euo pipefail` caller before `rc=$IT_EXIT` runs.

CYCLE-3 REVIEWS adds three seam-level fixes this plan owns:
- HIGH finding #2 (routed channel capture): `run-all-suites.sh` runs each `test_*.sh` as a black-box subprocess with NO handle to the child's shell-local `IT_STDOUT/IT_STDERR/IT_EXIT` or its `make_*_repo` fixture dir. This plan adds an `IT_CAPTURE_DIR` env-var contract: when set, EVERY `invoke_tool` call self-records its normalized channels + a tree snapshot of the test's cwd into a keyed sub-dir, so run-all can collect per-call routed channels with no `<repo>` arg. A behavioral test injects a routed byte divergence and proves it is captured.
- HIGH finding #3 (py lane bypasses the shim): the prior seam ran `python3 -m compendium.<tool>` DIRECTLY for ported tools, so a broken `bin/<tool>.sh` shim (bad PYTHONPATH/quoting/module-name/exec) PASSED all parity tests though the shim is part of the PKG-03 contract. This plan routes the py lane THROUGH the actual shim (`bash $REPO_ROOT/bin/<tool>.sh`), still exporting the cycle-1 hermetic `PYTHONPATH=$REPO_ROOT/src`+`LC_ALL=C`+`TZ=UTC`, and adds a shim-smoke test proving a broken shim is caught.
- HIGH finding #1 test-quality refinement: the script-relative self-parity test must use audit-claims/brownfield SUBCOMMANDS THAT REACH lib resolution (audit-claims `--help` exits at line 83 BEFORE `AUDIT_LIB_DIR` at line 123; brownfield `--help` at line 65 BEFORE `SG_REPO_ROOT` at line 730 — both make the long-pole verification VACUOUS). gen-skills `--check` already reaches lib resolution; keep it.
- N-4 / N-5 cheap hardening (both fold into oracle-worktree.sh).

CYCLE-4 REVIEWS adds two RESIDUAL mechanism fixes this plan owns (each a single localized internal defect in an otherwise-correct cycle-3 fix):
- CYCLE-4 finding #1 / Codex new-HIGH #1 (routed-suite capture-key collision): SOURCE-VERIFIED — the cycle-3 seam keyed the capture sub-dir by `tool + a per-PROCESS counter _IT_CALL_N`, BUT `_IT_CALL_N` resets to 0 in EVERY `test_*.sh` subprocess while the WHOLE suite shares ONE `IT_CAPTURE_DIR` (run-all exports `IT_CAPTURE_DIR=<out>/<suite>` per suite — Plan 05). So two DIFFERENT test files in one suite that both record the first `lint` invocation BOTH write `<suite>/lint-001` → silent overwrite → dropped coverage. This plan makes the key COLLISION-PROOF: the keyed sub-dir is `$IT_CAPTURE_DIR/<testbasename>-<pid>/<tool>-<counter>` — the `<testbasename>-<pid>` segment is unique per calling test-file subprocess (basename of `$0` of the running test + the process PID `$$`), so distinct test files sharing one `IT_CAPTURE_DIR` NEVER collide; the per-call counter still disambiguates multiple calls within one test. A behavioral test proves two simulated distinct test-file subprocesses invoking the same tool's first call produce DISTINCT keys (no overwrite).
- CYCLE-4 finding #3 / Codex new-HIGH #2 (seam PYTHONPATH masks a bootstrap-free shim): SOURCE-VERIFIED — the cycle-3 seam PRELOADS `PYTHONPATH=$REPO_ROOT/src` before running the shim, so the shim-smoke test's "correct" shim (`exec python3 -m compendium.faketool "$@"`) PASSES even WITHOUT its own checkout-hermetic PYTHONPATH bootstrap — the seam masked the missing bootstrap. The shim's OWN bootstrap is part of PKG-03 (Plan 01 doc) but was untested. This plan runs the shim-smoke test with the seam's `PYTHONPATH` (and any other seam env that could mask the bootstrap) UNSET, and asserts: a CANONICAL shim (with its own `_REPO_ROOT`/`export PYTHONPATH=...src` bootstrap) SUCCEEDS, while a BOOTSTRAP-FREE shim FAILS (ModuleNotFoundError / nonzero IT_EXIT). It does NOT remove the seam's PYTHONPATH export on the NORMAL lane (the normal lane stays hermetic — must_not_regress); only the dedicated smoke test clears it.

CYCLE-6 REVIEWS adds four localized fixes this plan owns (each unblocks a cycle-5 residual; NO re-architecture — the worktree oracle, set -e-safe seam, and 4-channel capture are endorsed keystones):
- CYCLE-6 fix #1 + #2 (the freeze/interface deadlock + the staged-index split): the seam gains TWO per-lane root knobs — `WIKI_EXEC_ROOT` (py-lane shim body / `src/` / `ported.manifest`) and `WIKI_ORACLE_GIT_ROOT` (the bash-oracle's `git worktree add`/`rev-parse` + `tests/freeze-baseline.sha`) — BOTH defaulting to `$REPO_ROOT` so the normal lane is byte-identical. `oracle-worktree.sh` runs its git commands against `$(_oracle_git_root)`, never a bare `$REPO_ROOT`. This is added HERE (wave 2), BEFORE the Plan-06 freeze snapshot (pinned at end-of-wave-4), so the two knobs are part of the FROZEN contract surface and Plan 06's staged-parity gate CONSUMES them (`WIKI_EXEC_ROOT=<materialized index, no .git>` + `WIKI_ORACLE_GIT_ROOT=<real repo>`) rather than editing the frozen seam — resolving the cycle-5 NEW-HIGH deadlock (the revision had frozen the very surface the fix needed to change).
- CYCLE-6 fix #4 (routed-capture footprint + cross-run pairing): (a) the per-call tree snapshot uses `_it_footprint_root "$@"` (honors `IT_FOOTPRINT_ROOT`, else scans args for `--root <dir>`, else `$PWD`) — SOURCE-VERIFIED the cycle-5 seam recorded `capture_footprint "$PWD"`, wrong for the 86 `--root`-without-cd invocations. (b) `invoke_tool` exposes `it_pairing_key` which strips the trailing `-<pid>`; the `<testbasename>-<pid>` segment stays within-run collision-proof but is paired cross-run by the pid-stripped identity (Plan 05's `--require-parity` consumes this) — the cycle-5 `$$`-in-key fixed the within-run overwrite but broke the cross-run pairing (bash and py runs have different PIDs → vacuous green).
- CYCLE-6 fix #5 (shim bootstrap bound to real shims): `test_shim_smoke.sh` adds a MANIFEST-DRIVEN loop iterating `tests/ported.manifest` and asserting EACH real `bin/<tool>.sh` shim owns its bootstrap (seam PYTHONPATH cleared) — the enforcement Phase 25 inherits as it appends tools; the loop mechanism is proven now via a `WIKI_EXEC_ROOT`-pointed scaffold with a seeded manifest entry, so the property is bound to the shipped shim population, not only the synthetic `faketool` exemplar.

This plan fixes all: the bash leg runs the script from a git WORKTREE (full `bin/`-relative layout preserved), the py lane runs the script's shim FROM THE EXEC ROOT, `invoke_tool` `return 0`s with status only via `IT_EXIT`, IT_CAPTURE_DIR enables routed channel collection with a collision-proof key snapshotting the REAL fixture root and a pid-stripped cross-run pairing key, and the shim-smoke test (seam PYTHONPATH cleared) proves the shim owns its bootstrap via a manifest-driven per-shim loop. Both `tests/lib/*` files are FROZEN shared surface (D-08) INCLUDING the two new per-lane root knobs.

Output: `tests/lib/invoke_tool.sh`, `tests/lib/oracle-worktree.sh`, `tests/lib/normalize.sh`, the six self-tests (`test_invoke_tool_selfparity.sh`, `test_invoke_tool_seterm.sh`, `test_oracle_scriptrelative.sh`, `test_capture_dir.sh`, `test_shim_smoke.sh`, `test_normalize.sh`), `tests/conftest.py`, and `tests/test_conftest_fixtures.py`.

CRITICAL: This plan does NOT re-point the existing 12 phase suites through the seam (that is Plan 05) and does NOT touch the 12 `make_bare_repo`/`make_fixture_repo` helpers (D-13). The `WIKI_IMPL=bash` path MUST stay byte-identical to today.

ORACLE↔FREEZE ORDER (acyclic, unambiguous — REVIEWS HIGH#1 reconciliation): This plan builds the oracle MECHANISM (a worktree resolver that reads ONE baseline ref). The ref is resolved as: (a) `phase-24-freeze^{commit}` if the tag exists AND is reachable; else (b) the SHA in `tests/freeze-baseline.sha` if that file exists AND the SHA is reachable; else (c) HEAD — BUT if `tests/ported.manifest` is NON-EMPTY, the HEAD fallback is a LOUD FAILURE, not a silent fallthrough (N-4). In Phase 24 neither the tag nor the baseline file exist yet (Plan 06 creates BOTH) AND ported.manifest is empty, so the oracle resolves to HEAD — and HEAD is all-bash in Phase 24, so the oracle works immediately. Plan 06 LATER pins `phase-24-freeze`/`tests/freeze-baseline.sha` at the pre-Plan-06 baseline; from then on the worktree checks out that exact frozen ref, so `WIKI_IMPL=bash` keeps running the FROZEN bash even after Phase 25 flips a shim to python. The dependency direction is: Plan 03 BUILDS the mechanism (depends only on Plan 01); Plan 06 SUPPLIES the pinned ref the mechanism reads (depends on 01-05). No cycle: the mechanism's fallback-to-HEAD (Phase 24, ported.manifest empty) means it never requires Plan 06 to function.

This plan depends on Plan 01 (wave 1): it reads `tests/ported.manifest` (created by Plan 01) and verifies via `pip install -e .` against Plan 01's `pyproject.toml`. It also aligns with Plan 01's `docs/reference/python-shim-contract.md`, which is updated (in Plan 01) to describe the worktree oracle for bash AND the shim-on-the-parity-path for py AND the shim-owns-bootstrap / seam-PYTHONPATH-cleared shim-smoke clause (finding #3 + cycle-4 finding #3 doc alignment).
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
<!-- The seam intercepts exactly this existing call shape (dominant form: 193 sites `bash "$REPO_ROOT/bin/<tool>.sh"`, plus `"$REPO_ROOT/bin/..."` and `bash $REPO_ROOT/bin/...` variants — the call sites live in the test_*.sh files, NOT in lib.sh; routing them is Plan 05's gate): -->
<!--   bash "$REPO_ROOT/bin/<tool>.sh" args... >out 2>err; rc=$? -->

<!-- SOURCE-VERIFIED script-relative path resolution that the cp-into-flat-dir oracle broke (REVIEWS HIGH#1): -->
bin/audit-claims.sh:83   -> case "$1" in --help|-h) usage; exit 0 ;;  (EARLY EXIT — exits BEFORE line 123; so `audit-claims --help` through the oracle is VACUOUS for HIGH#1 verification — finding #1 refinement)
bin/audit-claims.sh:123  -> export AUDIT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/lib" && pwd)"  (UNCONDITIONAL — no env knob; from a flat oracle dir resolves <oracle>/lib → abort. REACHED only by a non-help/version/error invocation, e.g. `--since <date> --format json`.)
bin/brownfield.sh:65     -> --help|-h) usage; exit 0 ;;  (EARLY EXIT — exits BEFORE line 730; so `brownfield --help`/`scan --help` is VACUOUS for HIGH#1 — finding #1 refinement)
bin/brownfield.sh:122    -> BROWNFIELD_LIB_DIR="$(cd "$(dirname "$0")/lib" && pwd)"  (inside the bootstrap subcommand)
bin/brownfield.sh:730    -> SG_REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"  (inside the `scan`/`suggest` subcommand; REACHED by `brownfield scan --root <fixture>`; also 1365, 1733 — all script-relative)
bin/gen-skills.sh:30-31  -> SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; then `cd "$REPO_ROOT"` and checks schema/workflows/ingest.md — `--check` REACHES this resolution (reads the WRONG tree from a flat oracle dir). KEEP gen-skills --check in the self-parity test.
bin/check-sources-cloud-safe.sh:47 -> ROOT="${PWD}"  (cwd-based — survives a flat copy, unlike the others; proves the breakage is INCONSISTENT across tools, so the worktree is the only uniform fix)
<!-- The worktree fix: run <worktree>/bin/<tool>.sh, where <worktree> is a full checkout at the pinned ref.
     Then $(dirname "$0")=<worktree>/bin, $(dirname "$0")/lib=<worktree>/bin/lib (REAL), $(dirname "$0")/..=<worktree> (REAL repo root). -->

<!-- The per-tool ported manifest the seam reads (created by Plan 01): -->
tests/ported.manifest  -> one bare tool name per non-comment line = "WIKI_IMPL=py runs the python lane THROUGH the shim for this tool"; absent = fall through to the bash oracle. EMPTY in Phase 24.

<!-- The shim-contract doc (Plan 01) locking the WIKI_IMPL mechanism this plan implements (UPDATED in Plan 01 for finding #3 + cycle-4 finding #3 doc alignment): -->
docs/reference/python-shim-contract.md  -> WIKI_IMPL=bash => held-fixed bash oracle (WORKTREE); WIKI_IMPL=py => the bin/<tool>.sh SHIM IF in ported.manifest else the oracle. The SHIM OWNS its own PYTHONPATH bootstrap; the shim-smoke test runs with the seam PYTHONPATH CLEARED to prove it. (No "COMMITTED COPY under tests/oracle/" language — that is the removed flat-cp mechanism.)

<!-- The canonical Phase-23 shim form (Plan 01 doc) — the shim OWNS its bootstrap; the smoke test's CANONICAL shim mirrors it: -->
#!/usr/bin/env bash
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.<tool> "$@"
<!-- The BOOTSTRAP-FREE shim the smoke test proves FAILS (with seam PYTHONPATH unset): -->
#!/usr/bin/env bash
exec python3 -m compendium.<tool> "$@"   # NO PYTHONPATH bootstrap -> ModuleNotFoundError when seam PYTHONPATH is unset

<!-- Baseline-ref resolution (the oracle reads this; Plan 06 LATER pins it — see ORACLE↔FREEZE ORDER):
     phase-24-freeze^{commit} (tag, if reachable) -> tests/freeze-baseline.sha (committed SHA, if reachable) -> HEAD.
     N-4: if ported.manifest is NON-EMPTY and resolution would fall through to HEAD, FAIL loudly (not silent).
     N-4: if BOTH the tag and the committed SHA exist, REQUIRE they are equal (a stale tag must not override a bumped SHA). -->

<!-- Existing fixture helpers the pytest port mirrors (DO NOT modify them — D-13): -->
make_bare_repo()    @ tests/phase-13/lib.sh:21-29   -> git_repo fixture (READ its EXACT commit message)
make_fixture_repo() @ tests/phase-10/lib.sh:20-36   -> fixture_repo fixture (excludes per-fixture README.md)
assert_byte_equal() @ tests/phase-10/lib.sh:41-54   -> assert_golden_tree helper
<!-- git identity to preserve byte-for-byte: user.email=fixture@example.com, user.name=Fixture,
     git init -q -b main, git -c commit.gpgsign=false commit -q --allow-empty -m "<exact seed msg>" -->

<!-- Contract the normalizer must NOT perturb: lint --ci --format json is a flat array;
     json-to-annotations.py sorts by severity but PRESERVES within-severity order.
     -> the normalizer must never sort lint JSON output. -->

<!-- VERIFIED git facts (this session): `git rev-parse <annotated-tag>` returns the TAG OBJECT, not the commit;
     `<tag>^{commit}` is required. `git worktree` works in this repo (single worktree today, no nested .git under tests/). -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Build the worktree-backed held-fixed oracle (per-repo path + loud-fail on ported+HEAD) + BRANCHING invoke_tool seam (return 0 / IT_EXIT-only, py-via-shim, IT_CAPTURE_DIR per-call record with a COLLISION-PROOF key) + time-bearing normalizer + exec-bit-aware tree capture, with six self-tests</name>
  <files>tests/lib/oracle-worktree.sh, tests/lib/invoke_tool.sh, tests/lib/normalize.sh, tests/lib/test_invoke_tool_selfparity.sh, tests/lib/test_invoke_tool_seterm.sh, tests/lib/test_oracle_scriptrelative.sh, tests/lib/test_capture_dir.sh, tests/lib/test_shim_smoke.sh, tests/lib/test_normalize.sh</files>
  <read_first>
    - bin/audit-claims.sh (READ lines 79-126 — confirm `--help|-h) usage; exit 0` at :83 EXITS BEFORE `export AUDIT_LIB_DIR=...` at :123; identify a SAFE READ-ONLY invocation that REACHES :123, e.g. `--since 1970-01-01 --format json` against a tiny seeded wiki — finding #1 refinement)
    - bin/brownfield.sh (READ lines 60-100, 700-745 — confirm `--help|-h) usage; exit 0` at :65 EXITS BEFORE `SG_REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` at :730; confirm `scan --root <dir>` reaches :730; use `brownfield scan --root <tiny-fixture>` in the self-parity test — finding #1 refinement)
    - bin/gen-skills.sh (READ lines 28-40 — confirm `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"; cd "$REPO_ROOT"` and that `--check` reaches this; gen-skills reads the WRONG tree from a flat oracle dir — KEEP gen-skills --check in the self-parity test)
    - bin/check-sources-cloud-safe.sh (READ lines 47, 66-75 — `ROOT="${PWD}"` cwd-based, survives a flat copy — the inconsistency the worktree eliminates)
    - bin/pdf-extract.sh (READ lines 1-6 — the canonical thin-shim head shape the py lane runs: `#!/usr/bin/env bash` + `set -euo pipefail`; the py lane must run THIS kind of shim, not python3 -m directly — finding #3)
    - docs/reference/python-shim-contract.md (from Plan 01 — READ §1 + §1a: the canonical shim form OWNS its own PYTHONPATH bootstrap, and the shim-smoke test runs with the seam PYTHONPATH UNSET — the smoke test's CANONICAL vs BOOTSTRAP-FREE shims must mirror this; cycle-4 finding #3)
    - tests/phase-09/test_lint_ci_mode.sh (read the invocation form ~40-52 — `bash "$REPO_ROOT/bin/lint.sh" ... >out 2>err` — the shape the seam intercepts; these run UNDER `set -e` in some suites, which is why the seam must NOT abort the caller)
    - tests/phase-10/lib.sh (read `assert_byte_equal` ~41-54 and the `$REPO_ROOT` resolution + `export -f` discipline the seam reuses)
    - tests/ported.manifest (from Plan 01 — the per-tool switch the seam reads; EMPTY in P22)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md (§Code Examples → invoke_tool/capture_footprint/assert_parity/normalize; Pitfall 3 [cwd/argv/exit drift], Pitfall 5 [4-channel], the normalizer caution about lint JSON order)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (HIGH#1 [worktree oracle, NOT cp-into-flat-dir], HIGH#2 [return 0 + IT_EXIT only], cycle-3 finding #2 [IT_CAPTURE_DIR per-call record], finding #3 [py lane via shim], finding #1 refinement [reach-lib subcommands], N-4 [loud-fail on ported+HEAD], N-5 [per-repo worktree path]; cycle-4 finding #1 [capture-key collision: per-test-file+pid discriminator], cycle-4 finding #3 [shim-smoke with seam PYTHONPATH unset]; CYCLE-6 Disposition fixes #1/#2 [add WIKI_EXEC_ROOT + WIKI_ORACLE_GIT_ROOT per-lane root knobs BEFORE the freeze so Plan 06 consumes them], #4 [_it_footprint_root snapshots the --root fixture not $PWD; it_pairing_key strips the pid for cross-run pairing], #5 [manifest-driven per-shim bootstrap loop bound to the real ported population])
    - .github/scripts/json-to-annotations.py (confirm it sorts by severity but preserves within-severity order — so the normalizer must NOT sort lint JSON)
  </read_first>
  <action>
**FINDING #1 (keystone) + N-4 + N-5 [DO FIRST] — the worktree-backed held-fixed bash oracle (REVIEWS HIGH#1; per-repo path N-5; loud-fail on ported+HEAD N-4).** Replace the broken `cp bin/<tool>.sh tests/lib/oracle/<tool>.sh` mechanism entirely. The bash leg runs the script from a git WORKTREE checked out at the pinned baseline ref, preserving the FULL `bin/`-relative layout so `$0`/`${BASH_SOURCE[0]}` resolution finds the real `bin/lib`, `schema/`, etc.

Create `tests/lib/oracle-worktree.sh` — resolves/creates a cached worktree and prints the path to the oracle script for a tool:
```bash
# tests/lib/oracle-worktree.sh — FROZEN shared seam (D-08).
# REVIEWS HIGH#1 KEYSTONE: the bash oracle runs <worktree>/bin/<tool>.sh, where <worktree> is a FULL
# checkout at the pinned baseline ref. This preserves the bin/-relative layout, so audit-claims.sh
# (unconditional AUDIT_LIB_DIR=$(dirname BASH_SOURCE)/lib), brownfield.sh ($(dirname $0)/..),
# and gen-skills.sh ($SCRIPT_DIR/..) resolve their REAL libs/REPO_ROOT and do NOT abort under set -e.
# A flat `cp bin/x.sh tests/lib/oracle/x.sh` would resolve tests/lib/oracle/lib (nonexistent) -> abort.

# PER-LANE ROOT KNOBS (REVIEWS cycle-6 fix #1 + #2 — the freeze/interface deadlock + the staged-index split).
# The seam previously bound a SINGLE $REPO_ROOT to BOTH the py-lane shim body/src AND the oracle's git commands.
# Plan 06's staged-parity gate needs the py leg to read the MATERIALIZED STAGED tree (no .git) while the oracle's
# `git worktree add`/`rev-parse` run against the REAL repo (.git intact). So there are now TWO independently-set roots:
#   WIKI_EXEC_ROOT       = where the py-lane shim body / src / ported.manifest are read (the EXEC root).
#   WIKI_ORACLE_GIT_ROOT = where the bash-oracle git commands + tests/freeze-baseline.sha resolve (the GIT root; MUST have .git).
# BOTH default to $REPO_ROOT, so the normal single-repo lane is byte-identical to before. The staged gate sets
# WIKI_EXEC_ROOT=<staged index, no .git> and WIKI_ORACLE_GIT_ROOT=<real repo>. These knobs are part of the FROZEN
# contract surface (D-08) — Plan 06 CONSUMES them (sets the env vars), it never edits this seam.
_oracle_exec_root() { printf '%s\n' "${WIKI_EXEC_ROOT:-$REPO_ROOT}"; }
_oracle_git_root()  { printf '%s\n' "${WIKI_ORACLE_GIT_ROOT:-$REPO_ROOT}"; }

# Is tests/ported.manifest non-empty (any non-comment, non-blank line)?  (N-4 silent-HEAD-fallback guard)
_oracle_manifest_nonempty() {
    local mf="$(_oracle_exec_root)/tests/ported.manifest"
    [ -f "$mf" ] || return 1
    grep -qvE '^[[:space:]]*#|^[[:space:]]*$' "$mf"
}

# Resolve the baseline ref the oracle checks out (see ORACLE↔FREEZE ORDER in the plan objective):
#   phase-24-freeze^{commit} (tag, if reachable) -> tests/freeze-baseline.sha (committed SHA, if reachable) -> HEAD.
# N-4: if BOTH the tag and the committed SHA exist, REQUIRE they are equal (a stale tag must not silently
#      override a bumped committed SHA) — fail loudly on mismatch.
# N-4: if resolution would fall through to HEAD WHILE ported.manifest is non-empty, FAIL loudly — a silent
#      HEAD fallback while a tool is ported runs the python shim at HEAD on BOTH legs -> false-green collapse.
_oracle_baseline_ref() {
    local tag_sha="" file_sha=""
    local gr; gr="$(_oracle_git_root)"
    if tag_sha="$(git -C "$gr" rev-parse -q --verify 'phase-24-freeze^{commit}' 2>/dev/null)"; then :; else tag_sha=""; fi
    if [ -f "$gr/tests/freeze-baseline.sha" ]; then
        file_sha="$(tr -d '[:space:]' < "$gr/tests/freeze-baseline.sha")"
        if [ -n "$file_sha" ] && git -C "$gr" rev-parse -q --verify "${file_sha}^{commit}" >/dev/null 2>&1; then :; else file_sha=""; fi
    fi
    # N-4 tag-vs-SHA equality: if both resolve, they MUST be equal.
    if [ -n "$tag_sha" ] && [ -n "$file_sha" ] && [ "$tag_sha" != "$file_sha" ]; then
        echo "ORACLE FATAL: phase-24-freeze^{commit} ($tag_sha) != tests/freeze-baseline.sha ($file_sha)." >&2
        echo "  A stale tag must not override a bumped committed SHA. Re-tag with 'git tag -f phase-24-freeze' or fix the file." >&2
        return 1
    fi
    if [ -n "$tag_sha" ]; then printf '%s\n' "$tag_sha"; return 0; fi
    if [ -n "$file_sha" ]; then printf '%s\n' "$file_sha"; return 0; fi
    # N-4 loud HEAD-fallthrough guard: HEAD is only safe when nothing is ported.
    if _oracle_manifest_nonempty; then
        echo "ORACLE FATAL: no reachable freeze baseline (tag/tests/freeze-baseline.sha) but tests/ported.manifest" >&2
        echo "  is NON-EMPTY. Falling back to HEAD would run the python shim on the WIKI_IMPL=bash leg too" >&2
        echo "  (both legs python) -> false-green. Pin the freeze baseline (Plan 06) before porting." >&2
        return 1
    fi
    git -C "$gr" rev-parse -q --verify 'HEAD^{commit}'   # Phase-22 fallback: HEAD is all-bash, manifest empty
}

# Path of the cached oracle worktree (N-5: PER-REPO + PER-BASELINE keyed so Phase-23 parallel clusters in
# separate clones/worktrees do not collide on one shared /tmp path). Derive the key from a hash of
# $REPO_ROOT + the baseline ref; honor an explicit WIKI_ORACLE_WORKTREE override.
_oracle_worktree_dir() {
    if [ -n "${WIKI_ORACLE_WORKTREE:-}" ]; then printf '%s\n' "$WIKI_ORACLE_WORKTREE"; return 0; fi
    local ref key
    ref="$(_oracle_baseline_ref)" || return 1
    key="$(printf '%s\n%s\n' "$(_oracle_git_root)" "$ref" | sha256sum | cut -c1-16)"
    printf '%s\n' "${TMPDIR:-/tmp}/wiki-oracle-worktree-${key}"
}

# Ensure the cached worktree exists at the resolved ref (idempotent; re-points if the ref changed).
ensure_oracle_worktree() {
    local wt ref cur
    ref="$(_oracle_baseline_ref)" || return 1
    wt="$(_oracle_worktree_dir)" || return 1
    if [ -d "$wt/.git" ] || [ -f "$wt/.git" ]; then
        cur="$(git -C "$wt" rev-parse -q --verify HEAD 2>/dev/null || echo none)"
        [ "$cur" = "$ref" ] && { printf '%s\n' "$wt"; return 0; }
        git -C "$(_oracle_git_root)" worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"
    fi
    git -C "$(_oracle_git_root)" worktree add --quiet --detach "$wt" "$ref" >/dev/null 2>&1
    printf '%s\n' "$wt"
}

# Path to the held-fixed bash body for <tool> (inside the worktree -> $0-relative resolution is REAL).
oracle_tool_path() {
    local tool="$1" wt; wt="$(ensure_oracle_worktree)" || return 1
    printf '%s\n' "$wt/bin/${tool}.sh"
}
export -f _oracle_manifest_nonempty _oracle_baseline_ref _oracle_worktree_dir ensure_oracle_worktree oracle_tool_path _oracle_exec_root _oracle_git_root
```
NOTES: (a) The worktree dir is OUTSIDE the repo tree (under `$TMPDIR`/`/tmp`) AND per-repo/per-baseline keyed (N-5) so its `.git` pointer never conflicts and parallel clusters never collide on one path. (b) In Phase 24 the ref resolves to HEAD (no tag/baseline file yet, ported.manifest empty) — so the oracle is functional immediately, no Plan-06 dependency. (c) When the worktree is checked out at the FROZEN ref post-Plan-06, the script's `cd "$REPO_ROOT"` (gen-skills) lands in the frozen worktree, reading the FROZEN `schema/`/`.claude/` — correct held-fixed behavior. (d) If `git worktree add` is genuinely unavailable, the acceptable fallback (REVIEWS option b) is `git archive <ref> | tar -x` into a per-repo-keyed temp dir so `$(dirname $0)/..` still reaches a full tree — but worktree is the primary mechanism; document any fallback in the SUMMARY. (e) N-4 makes the oracle FAIL LOUDLY rather than silently fall to HEAD whenever a tool is ported with no pinned baseline — this is the cycle-2 HIGH#1-collapse guard.

**FINDING #2 + FINDING #3 + HIGH#2 + CYCLE-4 finding #1 [DO FIRST] — `invoke_tool`: returns 0, status only via IT_EXIT (HIGH#2); py lane THROUGH the shim (finding #3); IT_CAPTURE_DIR per-call record with a COLLISION-PROOF key (finding #2 + cycle-4 finding #1).** `tests/lib/invoke_tool.sh` — the seam that BRANCHES on `WIKI_IMPL`, captures stdout/stderr to SEPARATE files, pins locale + TZ (D-12), captures the exit in a set-e-safe way, optionally self-records each call into `IT_CAPTURE_DIR` under a COLLISION-PROOF key, and `return 0`. Copy verbatim:
```bash
# tests/lib/invoke_tool.sh — FROZEN shared seam (D-08).
# Usage:  invoke_tool <tool> [args...]   # <tool> = bare name, e.g. "lint"
# Sets:   IT_STDOUT IT_STDERR (paths) and IT_EXIT (value).  ALWAYS returns 0 (REVIEWS HIGH#2).
# Call-site idiom (set -e-safe):  invoke_tool X ARGS ; rc=$IT_EXIT     # rc is reached even if the tool exits nonzero
# BRANCHES on WIKI_IMPL:
#   WIKI_IMPL=bash -> the held-fixed bash oracle: <worktree>/bin/<tool>.sh (oracle_tool_path, full bin/-relative tree) (HIGH#1)
#   WIKI_IMPL=py   -> the bin/<tool>.sh SHIM (which itself execs python3 -m compendium.<tool>) ONLY IF <tool> is in
#                     tests/ported.manifest; else the bash oracle. Running the SHIM (not `python3 -m` directly) puts a
#                     broken shim (bad PYTHONPATH/quoting/module/exec) ON the parity path (cycle-3 HIGH finding #3).
# In Phase 24 ported.manifest is EMPTY, so py falls through to the bash oracle for every tool.
# IT_CAPTURE_DIR (cycle-3 HIGH finding #2 + cycle-4 finding #1): if set, EACH call self-records its normalized
#   channels + a tree snapshot of the CURRENT cwd (the test's fixture working dir) into a COLLISION-PROOF keyed
#   sub-dir $IT_CAPTURE_DIR/<testbasename>-<pid>/<tool>-<NN>/{stdout,stderr,exit,tree}. The <testbasename>-<pid>
#   segment is UNIQUE per calling test-file subprocess (basename of $0 of the running test + this process's PID),
#   so two DIFFERENT test_*.sh files in ONE suite that share ONE IT_CAPTURE_DIR (run-all exports it per suite —
#   Plan 05) and both record their first <tool> call do NOT overwrite a shared <tool>-001 (cycle-4 finding #1 /
#   Codex new-HIGH #1: a bare per-PROCESS counter resets to 0 in each subprocess -> silent overwrite). The per-call
#   counter still disambiguates multiple calls within one test file. This lets a black-box child test process
#   collect per-call routed channels with NO <repo> arg from run-all.
_IT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$_IT_DIR/oracle-worktree.sh"
. "$_IT_DIR/normalize.sh"

_it_is_ported() {                         # is <tool> listed (non-comment, non-blank) in ported.manifest?
    local tool="$1" mf="$(_oracle_exec_root)/tests/ported.manifest"
    [ -f "$mf" ] || return 1
    grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$mf" | grep -qx "$tool"
}

# COLLISION-PROOF per-subprocess discriminator (cycle-4 finding #1): basename of the running test file's $0 +
# this process's PID. Honor IT_CAPTURE_KEY override (run-all / a test may set an explicit key).
_it_capture_key() {
    if [ -n "${IT_CAPTURE_KEY:-}" ]; then printf '%s\n' "$IT_CAPTURE_KEY"; return 0; fi
    local base; base="$(basename "${0:-shell}" .sh)"
    printf '%s-%s\n' "$base" "$$"
}
_IT_CALL_N=0                              # per-process call counter (disambiguates calls WITHIN one test file)
invoke_tool() {
    local tool="$1"; shift
    local impl="${WIKI_IMPL:-bash}"
    IT_STDOUT="$(mktemp)"; IT_STDERR="$(mktemp)"
    local cmd
    if [ "$impl" = "py" ] && _it_is_ported "$tool"; then
        # FINDING #3: run the ACTUAL shim, NOT python3 -m directly, so a broken shim is caught on the parity path.
        cmd=(bash "$(_oracle_exec_root)/bin/${tool}.sh")
    else
        cmd=(bash "$(oracle_tool_path "$tool")")             # bash leg / unported fallthrough: WORKTREE oracle
    fi
    # set -e-SAFE exit capture: capture into IT_EXIT via if/then/else (protects the child), THEN return 0
    # (REVIEWS HIGH#2 — a `return "$IT_EXIT"` would abort `invoke_tool X; rc=$IT_EXIT` before rc is read).
    # PYTHONPATH/LC_ALL/TZ pinned on the NORMAL lane so the py-via-shim lane inherits the cycle-1 hermeticity
    # (finding #3). NOTE: the dedicated shim-smoke test (cycle-4 finding #3) clears the seam PYTHONPATH to prove
    # the shim owns its OWN bootstrap; the normal lane below KEEPS the export (must_not_regress).
    if LC_ALL=C TZ=UTC PYTHONPATH="$(_oracle_exec_root)/src${PYTHONPATH:+:$PYTHONPATH}" \
         "${cmd[@]}" "$@" >"$IT_STDOUT" 2>"$IT_STDERR"; then
        IT_EXIT=0
    else
        IT_EXIT=$?
    fi
    # FINDING #2 + CYCLE-4 finding #1: per-call self-record into IT_CAPTURE_DIR under a COLLISION-PROOF key, if requested.
    if [ -n "${IT_CAPTURE_DIR:-}" ]; then
        _IT_CALL_N=$((_IT_CALL_N + 1))
        local key; key="$(_it_capture_key)"
        local cdir="$IT_CAPTURE_DIR/${key}/${tool}-$(printf '%03d' "$_IT_CALL_N")"
        # CYCLE-6 fix #4: snapshot the REAL fixture root, not $PWD. 86 parity invocations pass their fixture via
        # `--root <tmp>` WITHOUT cd-ing, so $PWD is the test's own dir, NOT the tree the tool mutated.
        capture_footprint "$(_it_footprint_root "$@")" "$cdir"
    fi
    return 0    # ALWAYS 0 — status is exposed ONLY via $IT_EXIT (REVIEWS HIGH#2)
}
# CYCLE-6 fix #4 — the tree-channel snapshot root. Honor an explicit IT_FOOTPRINT_ROOT override; else scan the
# invocation args for `--root <dir>` / `--root=<dir>` (the dominant fixture-passing flag — 86 sites) and snapshot
# THAT tree; else fall back to $PWD (the cd-into-fixture minority). This makes the resulting-file-tree channel
# capture the actual fixture the tool wrote, so a py-vs-bash tree divergence under `--root` is no longer missed.
_it_footprint_root() {
    if [ -n "${IT_FOOTPRINT_ROOT:-}" ]; then printf '%s\n' "$IT_FOOTPRINT_ROOT"; return 0; fi
    local a prev=""
    for a in "$@"; do
        case "$a" in --root=*) printf '%s\n' "${a#--root=}"; return 0 ;; esac
        if [ "$prev" = "--root" ] && [ -d "$a" ]; then printf '%s\n' "$a"; return 0; fi
        prev="$a"
    done
    printf '%s\n' "$PWD"
}
# CYCLE-6 fix #4 — the CROSS-RUN pairing key. The on-disk capture segment is <testbasename>-<pid>; the -<pid>
# suffix disambiguates WITHIN one run but DIFFERS across the separate bash and py --capture-channels runs. Plan 05's
# --require-parity pairs captures by STRIPPING the trailing -<pid> so <suite>/<testbasename>/<tool>-<NN> is the
# stable pid-INDEPENDENT cross-run identity (else the two runs' PIDs never match -> vacuous green). This helper
# strips the -<pid> from a keyed segment; --require-parity uses it (or an equivalent inline strip) to build pairs.
it_pairing_key() { printf '%s\n' "$1" | sed -E 's/-[0-9]+$//'; }
export -f invoke_tool _it_is_ported _it_capture_key _it_footprint_root it_pairing_key
```
(The py lane runs `bash "$REPO_ROOT/bin/${tool}.sh"` — the real shim — and the shim itself does `exec python3 -m compendium.<tool>`; the seam's `PYTHONPATH` export on the NORMAL lane mirrors the Plan-01 shim hermeticity so the module resolves from `src/` even on a bare checkout. The `capture_footprint` call records the REAL fixture root — `_it_footprint_root "$@"` scans the invocation args for `--root <dir>` (the dominant fixture-passing flag, used WITHOUT cd-ing at 86 sites) and snapshots THAT tree, falling back to `$PWD` only for the cd-into-fixture minority (cycle-6 fix #4 — `capture_footprint "$PWD"` would have snapshotted the wrong tree for the `--root`-without-cd suites). The `<testbasename>-<pid>` capture-key segment makes the keyed dir unique per test-file subprocess so the shared-IT_CAPTURE_DIR overwrite of cycle-4 finding #1 is impossible; the `-<pid>` suffix is STRIPPED by Plan 05's `--require-parity` (`it_pairing_key`) to pair the bash-run and py-run captures whose PIDs necessarily differ — cycle-6 fix #4.)

Add the 4-channel footprint capture + parity helpers in the same file (DEFINED ABOVE its use by invoke_tool, OR keep invoke_tool below them — ensure capture_footprint is defined before invoke_tool calls it). The tree manifest MUST record file TYPE + MODE + symlink target + empty dirs (generated-script executability is observable behavior), and the golden layout MUST be `<case>/{stdout,stderr,exit,tree}` (a directory per case):
```bash
# capture_footprint <repo-dir> <case-dir> — 4-channel snapshot into a CASE DIRECTORY (D-11).
# Writes <case-dir>/{stdout,stderr,exit,tree}.
capture_footprint() {
    local repo="$1" casedir="$2"
    mkdir -p "$casedir"
    normalize < "$IT_STDOUT" > "$casedir/stdout"
    normalize < "$IT_STDERR" > "$casedir/stderr"
    printf '%s\n' "$IT_EXIT" > "$casedir/exit"
    ( cd "$repo" && find . -path './.git' -prune -o -print 2>/dev/null \
        | sort \
        | while IFS= read -r e; do
              [ "$e" = "." ] && continue
              if [ -L "$e" ]; then
                  printf 'L %s -> %s\n' "$e" "$(readlink "$e")"
              elif [ -d "$e" ]; then
                  printf 'D %s %s\n' "$(stat -c '%a' "$e")" "$e"   # empty dirs recorded too
              elif [ -f "$e" ]; then
                  printf 'F %s %s  %s\n' "$(stat -c '%a' "$e")" \
                      "$(sha256sum "$e" | cut -d' ' -f1)" "$e"      # MODE captures exec bit
              fi
          done ) > "$casedir/tree"
}
# assert_parity <bash-case-dir> <py-case-dir> — all 4 channels.
assert_parity() { for ch in stdout stderr exit tree; do
    cmp -s "$1/$ch" "$2/$ch" || { echo "PARITY DIFF ($ch)"; diff "$1/$ch" "$2/$ch"; return 1; }
done; }
export -f capture_footprint assert_parity
```
(Note: `stat -c`/`sha256sum` are GNU forms — acceptable per the pinned Linux execute environment; record the GNU dependency in the SUMMARY as a known LOW portability item.)
Seam invariants (Pitfall 3/5): run in the test's cwd (no `cd` inside `invoke_tool`), pass `"$@"` untouched, keep stdout/stderr in SEPARATE files, capture the exact exit via the `if/then/else` idiom, self-record into IT_CAPTURE_DIR (under the collision-proof key) when set, and `return 0`.

**`tests/lib/normalize.sh`** — time-bearing timestamps only (preserves the cycle-1 HIGH#2 resolution). Redact ONLY the time-bearing "now" timestamps (those carrying a `T..:..:..` time component) + `/tmp` paths + fixture dirs. Do NOT redact bare `YYYY-MM-DD` dates, do NOT blanket-redact hex tokens, do NOT sort. Copy verbatim:
```bash
# tests/lib/normalize.sh — FROZEN shared seam (D-08). Reads stdin, writes normalized stdout.
# Redact ONLY time-bearing (T..:..:..) wall-clock timestamps + tmp/fixture paths.
# Contractual values (frontmatter created/updated bare dates, log dates, staleness dates, IDs, hashes)
# are DETERMINISTIC and must NOT be masked — masking them would hide a wrong Python value (false parity).
normalize() {
    sed -E \
      -e 's#/tmp/[A-Za-z0-9._-]+#<TMP>#g' \
      -e 's#phase[0-9]+(\.[0-9]+)?-fixture-[A-Za-z0-9]+#<FIXTURE>#g' \
      -e 's#[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:?[0-9]{2})?#<TS>#g'
    # DELIBERATELY ABSENT: bare-date redaction, SHA1/short-hex redaction.
    # CAUTION: do NOT sort — lint --ci --format json within-severity order is the locked
    # json-to-annotations.py contract.
}
export -f normalize
```
Document in a header comment that a tool emitting a genuinely non-deterministic bare date/hash on a happy path is handled by that tool's characterization test (Plan 04) with a CASE-SPECIFIC normalizer extension or a frozen `now` — never by widening the shared normalizer.

**`tests/lib/test_oracle_scriptrelative.sh`** — the PRE-FIX-FAILING keystone self-test (REVIEWS HIGH#1 + cycle-3 finding #1 refinement). Source `invoke_tool.sh` + a phase `lib.sh` for `$REPO_ROOT`, set `set -euo pipefail`, and run THROUGH the oracle path the long-pole, `bin/lib`/REPO_ROOT-importing, script-relative tools — using SUBCOMMANDS THAT ACTUALLY REACH lib/REPO_ROOT resolution (NOT --help, which exits during arg-parse before the broken line):
1. **audit-claims via a real read-only invocation that reaches line 123** — seed a tiny wiki-cloud/ fixture (an index.md + a page or two with a `[prov:...]` marker), `cd` into it (so AUDIT_REPO_ROOT defaults to PWD), and run `invoke_tool audit-claims --since 1970-01-01 --format json` (or another invocation that passes arg-parse and reaches `export AUDIT_LIB_DIR=...` at :123 → imports privacy_resolve from `<worktree>/bin/lib`). Assert `IT_EXIT` is a real audit exit (NOT a `set -e` abort from `cd <oracle>/lib && pwd` failing) and the output is the real audit JSON/report, not an abort trace. WHY NOT --help: `audit-claims.sh:83 --help exits BEFORE :123`, so `--help` never exercises the broken lib resolution — it is VACUOUS for HIGH#1 (finding #1 refinement).
2. **brownfield via `scan --root <fixture>`** — seed a tiny vault dir, run `invoke_tool brownfield scan --root <fixture>` (reaches `SG_REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` at :730 + the `schema/brownfield/migrations` existence check under the worktree). Assert `IT_EXIT` is a real scan exit and output is stable (not an abort). WHY NOT --help: `brownfield.sh:65 --help exits BEFORE :730` — VACUOUS (finding #1 refinement).
3. `invoke_tool gen-skills --check` — assert `IT_EXIT` is the REAL gen-skills `--check` code (0 if skills are in sync in the frozen worktree, else its drift code), NOT a `set -e` abort from a wrong-tree resolution. gen-skills `--check` reaches the lib/REPO_ROOT resolution; keep it.
WHY THIS IS PRE-FIX-FAILING: against the OLD `cp bin/<tool>.sh tests/lib/oracle/<tool>.sh` mechanism, the audit-claims real invocation aborts (resolves `tests/lib/oracle/lib` → `cd && pwd` fails under `set -e`), the brownfield scan aborts (`$(dirname $0)/..` resolves a nonexistent tree), and gen-skills cd's into the wrong tree. So this test FAILS on the pre-fix plan and PASSES only once the worktree oracle lands. AND because the test now uses reach-lib subcommands (not --help), it FAILS on a flat-cp oracle EVEN IF someone tried to claim the help paths "pass" — the verification is no longer vacuous. Exit non-zero if any tool aborts or returns an obviously-wrong code.

**`tests/lib/test_invoke_tool_selfparity.sh`** — Pitfall-3 guard. Source `invoke_tool.sh` + a phase `lib.sh` for `$REPO_ROOT`. For a SAMPLE of safe read-only invocations (e.g. `invoke_tool lint --help`, `invoke_tool validate-op` with no args → usage path), assert the seam's captured `IT_STDOUT`/`IT_STDERR`/`IT_EXIT` are `cmp`-equal to a DIRECT `bash "$(oracle_tool_path <tool>)" <args>` call (un-normalized — self-parity is about the seam not altering bytes). Exit non-zero if any channel differs.

**`tests/lib/test_invoke_tool_seterm.sh`** — the `set -e` exit-capture self-test (REVIEWS HIGH#2). The test MUST exercise the EXACT call-site form Plan 05 uses. In a `set -euo pipefail` context, source `invoke_tool.sh`, then:
```bash
set -euo pipefail
invoke_tool validate-op           # no args -> usage/error exit (a known-nonzero invocation)
rc=$IT_EXIT
echo "after rc=$rc"               # this line MUST be reached (caller NOT aborted by set -e)
```
Assert: (a) the `after rc=...` line WAS printed (the caller survived — proving `return 0`); and (b) `rc` holds the real nonzero exit code (the exit was captured, not lost). Use a marker file or captured stdout to prove the `after` line ran. WHY THIS IS PRE-FIX-FAILING: against the OLD seam ending in `return "$IT_EXIT"`, the `invoke_tool validate-op` simple command returns nonzero, so `set -e` aborts BEFORE `rc=$IT_EXIT`/`echo` run — the `after` line is never reached. So this test FAILS on the pre-fix plan and PASSES only once `invoke_tool` returns 0. Exit non-zero if either assertion fails.

**`tests/lib/test_capture_dir.sh`** — the PRE-FIX-FAILING IT_CAPTURE_DIR behavioral test (REVIEWS cycle-3 HIGH finding #2 + CYCLE-4 finding #1 / Codex new-HIGH #1). Source `invoke_tool.sh` + a phase `lib.sh` for `$REPO_ROOT`. Prove (a) the per-call self-record works, (b) two DIFFERENT test-file subprocesses sharing ONE IT_CAPTURE_DIR do NOT overwrite each other's first-call key (the cycle-4 collision fix), and (c) an injected byte divergence between two capture dirs is CAUGHT by the channel comparison:
1. **Per-call keying within one test file:** in a fixture cwd, `export IT_CAPTURE_DIR="$(mktemp -d)"`, then run TWO `invoke_tool` calls in the SAME process (e.g. `invoke_tool lint --help` then `invoke_tool validate-op`). Assert each call self-recorded under the SAME `<testbasename>-<pid>` key but DISTINCT `<tool>-NNN` counters (`lint-001`, `validate-op-002`; the point is no within-process collision), and each holds `{stdout,stderr,exit,tree}`.
2. **CROSS-TEST-FILE collision-proofing (cycle-4 finding #1 — the core proof):** simulate TWO DIFFERENT test files sharing ONE `IT_CAPTURE_DIR` by invoking the seam from TWO SEPARATE child bash subprocesses with DISTINCT `IT_CAPTURE_KEY` (or distinct `$0`) but the SAME `IT_CAPTURE_DIR` and the SAME tool's FIRST call. Concretely (the seam must already be sourceable): `export IT_CAPTURE_DIR="$(mktemp -d)"`, then run `IT_CAPTURE_KEY=fileA bash -c '. "$REPO_ROOT/tests/lib/invoke_tool.sh"; invoke_tool lint --help'` and `IT_CAPTURE_KEY=fileB bash -c '. "$REPO_ROOT/tests/lib/invoke_tool.sh"; invoke_tool lint --help'` (or author two real throwaway `test_a.sh`/`test_b.sh` files that each `invoke_tool lint --help` once). Assert TWO DISTINCT keyed dirs exist — `test -d "$IT_CAPTURE_DIR/fileA/lint-001"` AND `test -d "$IT_CAPTURE_DIR/fileB/lint-001"` — i.e. the first `lint` call from file A and from file B did NOT collide on one `lint-001`. WHY THIS CATCHES THE CYCLE-4 DEFECT: against the cycle-3 bare per-process counter (`$IT_CAPTURE_DIR/lint-001`), both subprocesses' first call write the SAME path → only ONE survives → the two-distinct-dirs assertion FAILS. It PASSES only once the key includes the `<testbasename>-<pid>` (or `IT_CAPTURE_KEY`) discriminator.
3. **Divergence-caught:** build two channel dirs (`A` and `B`) each holding a `stdout` file; make them byte-identical, assert `assert_parity A/case B/case` (or `cmp`/`diff` over the channel files the way run-all will) returns 0; then flip ONE byte in `B/case/stdout`, assert the comparison now returns NON-ZERO (catches it). This is the kernel of run-all's `--require-parity` (Plan 05) — it proves the channel comparison actually catches a byte divergence, not just that strings exist.
4. **Footprint root follows `--root`, not `$PWD` (CYCLE-6 fix #4):** in a test whose cwd is NOT the fixture, invoke a tool with `--root <fixture-dir>` (a seeded dir with a known file) WITHOUT cd-ing into it, with `IT_CAPTURE_DIR` set. Assert the recorded `<case>/tree` channel reflects `<fixture-dir>`'s contents (contains the known file's path), NOT the empty/wrong `$PWD` tree. WHY PRE-FIX-FAILING: against `capture_footprint "$PWD"`, the tree snapshots the test's own cwd (missing the fixture) → the known-file assertion FAILS; it PASSES only once `_it_footprint_root` snapshots the `--root` dir.
5. **Cross-run pid-independent pairing (CYCLE-6 fix #4):** simulate two SEPARATE runs (different PIDs) of the same test file by producing two keyed captures with DISTINCT `<testbasename>-<pid>` top segments but the SAME testbasename (e.g. `IT_CAPTURE_KEY=lint_suite-111` and `IT_CAPTURE_KEY=lint_suite-222`, each recording `lint-001`). Assert `it_pairing_key lint_suite-111` == `it_pairing_key lint_suite-222` (both strip to `lint_suite`), so the two runs' captures PAIR on `lint_suite/lint-001`. WHY PRE-FIX-FAILING: against the raw `<testbasename>-<pid>` key with no pid-strip, the two runs never share a top-level key → --require-parity finds no pairs → vacuous green; it PASSES only once `it_pairing_key` strips the pid.
WHY THIS IS PRE-FIX-FAILING: against the prior seam (no IT_CAPTURE_DIR contract — `invoke_tool` does NOT self-record), step 1 produces ZERO keyed sub-dirs → the assertion fails; against the cycle-3 bare per-process key, step 2's two-subprocess collision overwrites one dir → the two-distinct-dirs assertion fails; against `capture_footprint "$PWD"`, step 4's `--root` tree assertion fails; and against the un-stripped key, step 5's cross-run pairing is vacuous. It PASSES only once invoke_tool honors IT_CAPTURE_DIR, keys by testbasename+pid (or IT_CAPTURE_KEY), snapshots the `--root` fixture, and exposes a pid-stripping pairing key. Exit non-zero on any failure.

**`tests/lib/test_shim_smoke.sh`** — the PRE-FIX-FAILING shim-on-the-parity-path test, RUN WITH THE SEAM PYTHONPATH UNSET (REVIEWS cycle-3 HIGH finding #3 + CYCLE-4 finding #3 / Codex new-HIGH #2). Prove (a) the py lane runs THROUGH the shim (a broken shim is caught, not bypassed), AND (b) the shim OWNS its own PYTHONPATH bootstrap (a bootstrap-free shim FAILS when the seam's PYTHONPATH is cleared, while the canonical shim with its own bootstrap PASSES). In an isolated temp scaffold (do NOT mutate the real repo):
1. Create a throwaway `REPO_ROOT`-like scaffold with a fake "ported" tool: a tiny `bin/faketool.sh` shim and a `src/compendium/faketool.py` module (the module prints a known token to stdout and exits 0 when imported/run), plus a `tests/ported.manifest` listing `faketool`. Point the seam at this scaffold (`REPO_ROOT=<scaffold>`).
2. **CLEAR THE SEAM-INJECTED PYTHONPATH FOR THE SMOKE RUNS (cycle-4 finding #3 — the core fix).** The seam exports `PYTHONPATH=$REPO_ROOT/src` on the normal lane, which would MASK a shim missing its own bootstrap. So for THIS test, run each `invoke_tool faketool` with the seam env that could mask the bootstrap UNSET — e.g. `env -u PYTHONPATH WIKI_IMPL=py invoke_tool faketool ...` OR `( unset PYTHONPATH; WIKI_IMPL=py invoke_tool faketool ...; rc=$IT_EXIT )`. (Document that this is the ONLY place the seam PYTHONPATH is cleared; the normal lane keeps it — must_not_regress.) NOTE: if `invoke_tool`'s inline `PYTHONPATH="$REPO_ROOT/src..."` assignment cannot be cleared from the call site because it is set on the command line inside the seam, set `WIKI_NO_SEAM_PYTHONPATH=1` for the smoke test and have `invoke_tool` honor it by NOT exporting PYTHONPATH on this run — OR (simpler, preferred) run the shim DIRECTLY in the smoke test the same way the seam does but WITHOUT the PYTHONPATH assignment, i.e. `( cd <scaffold-cwd>; unset PYTHONPATH; LC_ALL=C TZ=UTC bash "$REPO_ROOT/bin/faketool.sh"; rc=$? )`, mirroring the seam's py-lane command MINUS the masking PYTHONPATH. Choose one mechanism and document it; the REQUIRED property is that the shim runs with NO seam-provided PYTHONPATH so its own bootstrap is the only thing that can make the import resolve.
3. **Canonical shim (own bootstrap) PASSES with seam PYTHONPATH cleared:** `bin/faketool.sh` = the canonical Plan-01 form (`#!/usr/bin/env bash` + `_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"; exec python3 -m compendium.faketool "$@"`). With the seam PYTHONPATH cleared, run the shim and assert it reaches the module and exits 0 (prints the known token). This PASSES because the shim set PYTHONPATH itself.
4. **Bootstrap-free shim FAILS with seam PYTHONPATH cleared (cycle-4 finding #3 — the pre-fix-failing assertion):** replace `bin/faketool.sh` with a BOOTSTRAP-FREE shim (`#!/usr/bin/env bash` + `exec python3 -m compendium.faketool "$@"` — NO `_REPO_ROOT`/`export PYTHONPATH` lines). With the seam PYTHONPATH cleared, run the shim and assert it FAILS with a NONZERO exit (ModuleNotFoundError — `compendium` is not importable because neither the seam nor the shim set the path). WHY THIS IS PRE-FIX-FAILING: against the cycle-3 seam (which PRELOADS `PYTHONPATH=$REPO_ROOT/src`), the bootstrap-free shim wrongly PASSES (the seam set the path) → the "bootstrap-free shim fails" assertion FAILS. It PASSES only once the smoke test clears the seam PYTHONPATH, exposing the missing bootstrap.
5. **Broken shim caught (finding #3, preserved):** replace `bin/faketool.sh` with a DELIBERATELY-BROKEN shim (e.g. `exec python3 -m compendium.WRONGNAME "$@"` — wrong module name, WITH its own PYTHONPATH bootstrap so this is purely a wrong-module test), run `WIKI_IMPL=py invoke_tool faketool ...; rc=$IT_EXIT`, and assert `IT_EXIT` is NONZERO (the broken shim's failure surfaces) — i.e. the parity path CATCHES the broken shim (proving the py lane runs `bash $(_oracle_exec_root)/bin/faketool.sh`, not `python3 -m` directly).
6. **MANIFEST-DRIVEN per-shim enforcement — bind the bootstrap property to EVERY REAL ported shim (CYCLE-6 fix #5 / Codex #3).** The steps above prove the property on a synthetic `faketool` EXEMPLAR. Add a loop that, for EACH tool listed in `tests/ported.manifest` (read via the seam's exec root — `_oracle_exec_root`), drives the REAL `<exec-root>/bin/<tool>.sh` shim with the seam PYTHONPATH cleared and asserts it OWNS its bootstrap (imports `compendium` and does NOT fail with ModuleNotFoundError). In Phase 24 `tests/ported.manifest` is EMPTY, so against the real repo this loop body runs ZERO times — but it is the enforcement Phase 25 INHERITS: as each Phase-23 cluster port APPENDS its tool to `ported.manifest` + flips `bin/<tool>.sh`, this test AUTOMATICALLY begins asserting the bootstrap property on that real shim, per shim, with no test edit. To PROVE the loop mechanism actually enforces (not vacuously passes on the empty real manifest), exercise it against the synthetic scaffold via the new `WIKI_EXEC_ROOT` knob: point `WIKI_EXEC_ROOT` at the scaffold whose `tests/ported.manifest` lists `faketool` and (a) with the scaffold's `bin/faketool.sh` BOOTSTRAP-FREE, assert the manifest-driven loop FLAGS faketool (nonzero); (b) with the CANONICAL scaffold shim, assert the loop PASSES. This is the "manifest-driven test that iterates every ported shim and asserts the property per shim" the disposition requires — it binds the bootstrap contract to the real shipped population, not only the exemplar.
WHY THE WHOLE TEST IS PRE-FIX-FAILING: step 5 fails on the OLD `python3 -m compendium.<tool>` direct lane (the broken shim is never executed → rc 0 → not caught); step 4 fails on the cycle-3 seam-PYTHONPATH-preloaded lane (the bootstrap-free shim wrongly passes); and step 6 fails on the cycle-5 exemplar-only design (there was NO manifest-driven per-shim loop, so a real ported shim missing its bootstrap was never checked). It PASSES only once the py lane runs the shim, the smoke test clears the seam PYTHONPATH, AND the manifest-driven loop enforces the property per real ported shim. Exit non-zero if the broken/bootstrap-free shims are NOT caught, the canonical shim does not pass, or the manifest-driven loop does not flag a bootstrap-free scaffold shim.

**`tests/lib/test_normalize.sh`** — pin the redaction set AND prove a WRONG contractual value is NOT masked. Feed a KNOWN input through `normalize` and assert:
1. A `T..:..:..` timestamp IS replaced with `<TS>`, and a `/tmp/xyz` path with `<TMP>`.
2. A bare contractual date (`created: 2024-03-15`) is PRESERVED — and a WRONG date (`2024-03-16`) survives normalization and DIFFs from the right one: `normalize` of the wrong value != `normalize` of the right value.
3. A contractual ID/hash token (`sha256:abcdef...` or `dr-2024-03-15-slug`) is PRESERVED, and a wrong one differs after normalization.
4. A lint-style JSON array of two findings is NOT reordered by `normalize`.
Exit non-zero on any mismatch.

Make all script files executable (`chmod +x tests/lib/*.sh`). Do NOT edit any existing `tests/phase-*/` file. Do NOT route existing suites through the seam (that is Plan 05). Do NOT create `tests/lib/oracle/` (the old flat dir is REMOVED in favor of the worktree).
  </action>
  <verify>
    <automated>chmod +x tests/lib/*.sh 2>/dev/null; bash tests/lib/test_normalize.sh && bash tests/lib/test_invoke_tool_seterm.sh && bash tests/lib/test_oracle_scriptrelative.sh && bash tests/lib/test_capture_dir.sh && bash tests/lib/test_shim_smoke.sh && bash tests/lib/test_invoke_tool_selfparity.sh && echo SEAM_SELFTESTS_PASS</automated>
  </verify>
  <acceptance_criteria>
    - `test -f tests/lib/invoke_tool.sh && test -f tests/lib/oracle-worktree.sh && test -f tests/lib/normalize.sh` exits 0
    - `grep -q 'git worktree add' tests/lib/oracle-worktree.sh && grep -q 'oracle_tool_path' tests/lib/oracle-worktree.sh` exits 0 (the oracle is a WORKTREE, not a flat cp — REVIEWS HIGH#1 keystone)
    - `grep -q 'phase-24-freeze' tests/lib/oracle-worktree.sh && grep -qF '^{commit}' tests/lib/oracle-worktree.sh && grep -q 'freeze-baseline.sha' tests/lib/oracle-worktree.sh && grep -q 'HEAD' tests/lib/oracle-worktree.sh` exits 0 (baseline ref resolution: tag^{commit} -> committed SHA -> HEAD fallback, acyclic with Plan 06)
    - `grep -qiE 'NON-EMPTY|ported.manifest' tests/lib/oracle-worktree.sh && grep -qiE 'false-green|FATAL|loud' tests/lib/oracle-worktree.sh` exits 0 (N-4: loud-fail on ported+HEAD-fallthrough — no silent HEAD fallback while a tool is ported)
    - `grep -qiE 'tag_sha.*file_sha|stale tag|must not.*override' tests/lib/oracle-worktree.sh` exits 0 (N-4: tag-vs-SHA equality required when both exist)
    - `grep -qE 'sha256sum|WIKI_ORACLE_WORKTREE' tests/lib/oracle-worktree.sh && grep -qE 'REPO_ROOT.*ref|ref.*REPO_ROOT|key=' tests/lib/oracle-worktree.sh` exits 0 (N-5: per-repo/per-baseline keyed worktree path, not a single shared /tmp path)
    - `! test -d tests/lib/oracle` OR `! ls tests/lib/oracle/*.sh >/dev/null 2>&1` (the OLD flat cp-into-oracle dir is GONE — REVIEWS HIGH#1; the worktree replaces it)
    - `grep -q 'return 0' tests/lib/invoke_tool.sh && ! grep -qE 'return +"?\$IT_EXIT' tests/lib/invoke_tool.sh` exits 0 (invoke_tool returns 0, NOT `return $IT_EXIT` — REVIEWS HIGH#2)
    - `grep -q 'IT_EXIT=\$?' tests/lib/invoke_tool.sh && grep -q 'IT_EXIT=0' tests/lib/invoke_tool.sh` exits 0 (set -e-safe if/then/else exit capture)
    - `grep -qE 'if \[ "\$impl" = "py" \]' tests/lib/invoke_tool.sh && grep -q '_it_is_ported' tests/lib/invoke_tool.sh && grep -q 'ported.manifest' tests/lib/invoke_tool.sh` exits 0 (the seam BRANCHES; py leg gated by the manifest — REVIEWS HIGH#1)
    - `grep -qE 'bash "\$\(_oracle_exec_root\)/bin/\$\{?tool\}?.sh"' tests/lib/invoke_tool.sh && ! grep -qE 'cmd=\(python3 -m' tests/lib/invoke_tool.sh` exits 0 (FINDING #3: the py lane runs the SHIM from the EXEC root `bash $(_oracle_exec_root)/bin/<tool>.sh`, NOT `python3 -m compendium.<tool>` directly)
    - `grep -qE '_oracle_exec_root\(\)' tests/lib/oracle-worktree.sh && grep -qE '_oracle_git_root\(\)' tests/lib/oracle-worktree.sh && grep -q 'WIKI_EXEC_ROOT' tests/lib/oracle-worktree.sh && grep -q 'WIKI_ORACLE_GIT_ROOT' tests/lib/oracle-worktree.sh` exits 0 (CYCLE-6 fix #1/#2: the seam exposes TWO per-lane root knobs [exec-root vs git-root], both defaulting to $REPO_ROOT — the frozen interface Plan 06's staged gate consumes)
    - `grep -q '_oracle_git_root' tests/lib/oracle-worktree.sh && ! grep -qE 'git -C "\$REPO_ROOT" (worktree|rev-parse)' tests/lib/oracle-worktree.sh` exits 0 (CYCLE-6 fix #2: the oracle's git worktree/rev-parse commands run against the GIT root [$(_oracle_git_root) = WIKI_ORACLE_GIT_ROOT], never a bare $REPO_ROOT — so a staged exec-root with no .git does not break git resolution)
    - `grep -q 'oracle_tool_path' tests/lib/invoke_tool.sh` exits 0 (bash leg uses the worktree oracle path)
    - `grep -q '2>"\$IT_STDERR"' tests/lib/invoke_tool.sh` exits 0 (stderr captured SEPARATELY)
    - `grep -q 'IT_CAPTURE_DIR' tests/lib/invoke_tool.sh && grep -q 'capture_footprint' tests/lib/invoke_tool.sh` exits 0 (FINDING #2: per-call self-record into IT_CAPTURE_DIR)
    - `grep -qE '_it_capture_key|IT_CAPTURE_KEY' tests/lib/invoke_tool.sh && grep -qE 'basename.*\$\{?0|\$\$' tests/lib/invoke_tool.sh && grep -qE '\$\{key\}/\$\{?tool|key.*tool' tests/lib/invoke_tool.sh` exits 0 (CYCLE-4 finding #1: the capture key is COLLISION-PROOF — keyed by testbasename+pid, not a bare per-process counter; the keyed dir nests the discriminator ABOVE the tool-counter)
    - `! grep -qE 'cd="\$IT_CAPTURE_DIR/\$\{?tool\}?-' tests/lib/invoke_tool.sh` (the cycle-3 BARE `$IT_CAPTURE_DIR/<tool>-NNN` key — which collides across test files — is GONE; the key now nests under the per-subprocess discriminator — CYCLE-4 finding #1)
    - `grep -q 'PYTHONPATH="\$(_oracle_exec_root)/src' tests/lib/invoke_tool.sh && grep -q 'LC_ALL=C' tests/lib/invoke_tool.sh && grep -q 'TZ=UTC' tests/lib/invoke_tool.sh` exits 0 (cycle-1 hermeticity preserved ON THE NORMAL LANE — PYTHONPATH resolves from the EXEC root [= $REPO_ROOT by default], inherited by the py-via-shim lane — finding #3; NOT removed — must_not_regress)
    - `grep -q '_it_footprint_root' tests/lib/invoke_tool.sh && grep -qE 'capture_footprint "\$\(_it_footprint_root' tests/lib/invoke_tool.sh && ! grep -qE 'capture_footprint "\$PWD"' tests/lib/invoke_tool.sh` exits 0 (CYCLE-6 fix #4: the tree channel snapshots the REAL fixture root via `--root`/IT_FOOTPRINT_ROOT, NOT a bare `$PWD` — so the 86 `--root`-without-cd invocations capture the right tree)
    - `grep -q 'it_pairing_key' tests/lib/invoke_tool.sh && grep -qE "sed -E 's/-\[0-9\]\+\\\$//'" tests/lib/invoke_tool.sh` exits 0 (CYCLE-6 fix #4: the pid-stripping cross-run pairing helper exists so --require-parity can pair bash-run vs py-run captures whose PIDs differ)
    - `grep -qE "stat -c '%a'" tests/lib/invoke_tool.sh && grep -q 'readlink' tests/lib/invoke_tool.sh && grep -qE "printf 'D " tests/lib/invoke_tool.sh` exits 0 (tree records mode/exec-bit + symlink target + empty dirs)
    - `grep -q 'casedir' tests/lib/invoke_tool.sh && grep -q '\$casedir/stdout' tests/lib/invoke_tool.sh` exits 0 (golden layout is <case-dir>/{stdout,...})
    - `! grep -qE "s#\[0-9\]\{4\}-\[0-9\]\{2\}-\[0-9\]\{2\}#" tests/lib/normalize.sh` (the bare-date blanket redaction stays GONE)
    - `! grep -qE "0-9a-f.\{40\}|0-9a-f.\{7,12\}" tests/lib/normalize.sh` (the blanket hex/SHA redaction stays GONE)
    - `! grep -qE '\bsort\b' tests/lib/normalize.sh` (normalize() body contains no sort call)
    - `bash tests/lib/test_oracle_scriptrelative.sh` exits 0 (PRE-FIX-FAILING: audit-claims [real --since/--format past :123] + brownfield [scan --root past :730] + gen-skills --check run THROUGH the oracle without aborting — FAILS on the old cp mechanism, PASSES with the worktree, and is NON-VACUOUS because it uses reach-lib subcommands not --help — REVIEWS HIGH#1 + finding #1 refinement)
    - `grep -q 'invoke_tool audit-claims' tests/lib/test_oracle_scriptrelative.sh && grep -q 'invoke_tool brownfield' tests/lib/test_oracle_scriptrelative.sh && ! grep -qE 'invoke_tool audit-claims --help|invoke_tool brownfield (--help|scan --help)' tests/lib/test_oracle_scriptrelative.sh` exits 0 (the long-pole tools are exercised via REACH-LIB subcommands, NOT the vacuous --help paths — finding #1 refinement)
    - `bash tests/lib/test_invoke_tool_seterm.sh` exits 0 (PRE-FIX-FAILING: `invoke_tool <nonzero>; rc=$IT_EXIT; echo after` reaches the after line + rc is the real nonzero code — FAILS while the seam `return $IT_EXIT`s, PASSES once it `return 0`s — REVIEWS HIGH#2)
    - `grep -qE 'rc=\$IT_EXIT' tests/lib/test_invoke_tool_seterm.sh && grep -qi 'after' tests/lib/test_invoke_tool_seterm.sh` exits 0 (the test uses the EXACT call-site form and asserts the after-line is reached)
    - `bash tests/lib/test_capture_dir.sh` exits 0 (PRE-FIX-FAILING: per-call self-record + TWO distinct-test-file subprocesses' first call land in DISTINCT keyed dirs [no overwrite — cycle-4 finding #1] + an injected one-byte stdout divergence is CAUGHT — FAILS without the IT_CAPTURE_DIR contract AND against the cycle-3 bare-counter key — REVIEWS cycle-3 HIGH finding #2 + cycle-4 finding #1)
    - `grep -q 'IT_CAPTURE_DIR' tests/lib/test_capture_dir.sh && grep -qE 'IT_CAPTURE_KEY|fileA|fileB|distinct' tests/lib/test_capture_dir.sh && grep -qE 'flip|divergen|differ|one byte|1 byte' tests/lib/test_capture_dir.sh` exits 0 (the test proves cross-test-file key distinctness AND injects a byte divergence that is caught — cycle-4 finding #1 + finding #2)
    - `grep -qE '\-\-root|IT_FOOTPRINT_ROOT' tests/lib/test_capture_dir.sh && grep -q 'it_pairing_key' tests/lib/test_capture_dir.sh` exits 0 (CYCLE-6 fix #4: the test asserts the tree channel follows the `--root` fixture [not $PWD] AND that the pid-stripped pairing key pairs two different-pid runs)
    - `bash tests/lib/test_shim_smoke.sh` exits 0 (PRE-FIX-FAILING: with the seam PYTHONPATH CLEARED, a bootstrap-free shim FAILS while the canonical shim [own bootstrap] PASSES [cycle-4 finding #3], AND a broken shim is CAUGHT on the py lane [finding #3] — FAILS on the cycle-3 seam-PYTHONPATH-preloaded lane where the bootstrap-free shim wrongly passes)
    - `grep -q 'WIKI_IMPL=py' tests/lib/test_shim_smoke.sh && grep -qE 'faketool|broken' tests/lib/test_shim_smoke.sh && grep -qiE 'unset PYTHONPATH|env -u PYTHONPATH|WIKI_NO_SEAM_PYTHONPATH|seam.*PYTHONPATH.*cleared|PYTHONPATH.*unset' tests/lib/test_shim_smoke.sh` exits 0 (CYCLE-4 finding #3: the shim-smoke test clears the seam PYTHONPATH so a bootstrap-free shim is caught, not masked)
    - `grep -qiE 'bootstrap-free|no.*bootstrap|missing.*bootstrap|own.*bootstrap|canonical shim' tests/lib/test_shim_smoke.sh` exits 0 (the test distinguishes the canonical-with-bootstrap shim from the bootstrap-free shim — cycle-4 finding #3)
    - `grep -q 'ported.manifest' tests/lib/test_shim_smoke.sh && grep -q 'WIKI_EXEC_ROOT' tests/lib/test_shim_smoke.sh && grep -qiE 'for .*(tool|shim)|iterate|per-shim|manifest-driven' tests/lib/test_shim_smoke.sh` exits 0 (CYCLE-6 fix #5: a MANIFEST-DRIVEN loop iterates every ported shim and asserts the bootstrap property per real shim — bound to the shipped population via WIKI_EXEC_ROOT, not only the synthetic exemplar)
    - `bash tests/lib/test_normalize.sh` exits 0 (redaction pinned + WRONG contractual date/ID/hash NOT masked + JSON order preserved)
    - `bash tests/lib/test_invoke_tool_selfparity.sh` exits 0 (seam byte-identical to direct call under WIKI_IMPL=bash)
    - `git diff --name-only HEAD -- tests/phase-09 tests/phase-10 tests/phase-13 | wc -l` returns `0` (existing suites + make_*_repo helpers untouched)
  </acceptance_criteria>
  <done>invoke_tool BRANCHES on WIKI_IMPL (bash=worktree-backed held-fixed oracle, py=the bin/<tool>.sh SHIM-if-ported-else-oracle via tests/ported.manifest — finding #3), returns 0 with status only via IT_EXIT (REVIEWS HIGH#2), self-records each call into a COLLISION-PROOF keyed IT_CAPTURE_DIR sub-dir (testbasename+pid+counter — finding #2 + cycle-4 finding #1) when set, and resolves the oracle from a PER-REPO-keyed git worktree (N-5) at the pinned baseline ref (tag^{commit} -> committed SHA -> HEAD with a LOUD fail on ported+HEAD-fallthrough N-4 and tag-vs-SHA equality N-4) so script-relative tools resolve their real libs (REVIEWS HIGH#1); the script-relative self-test runs audit-claims/brownfield through REACH-LIB subcommands (not the vacuous --help) + gen-skills --check through the oracle without aborting (pre-fix-failing, non-vacuous — finding #1 refinement); the seterm self-test proves the set -e caller survives + IT_EXIT holds the real code (pre-fix-failing); the capture-dir test proves per-call keyed self-record + CROSS-TEST-FILE key distinctness + injected-divergence-caught (pre-fix-failing, finding #2 + cycle-4 finding #1); the shim-smoke test (seam PYTHONPATH CLEARED) proves a bootstrap-free shim FAILS while the canonical shim PASSES + a broken shim is caught on the py lane (pre-fix-failing, finding #3 + cycle-4 finding #3); the normalizer redacts only time-bearing timestamps and a self-test proves a wrong contractual value is NOT masked; the tree manifest records exec bits/symlinks/empty dirs in a <case>/ layout; the old flat oracle dir is gone; existing suites untouched.</done>
</task>

<task type="auto">
  <name>Task 2: Stand up the pytest harness conftest.py (fresh tmp_path per call, unified SEED_MSG) + fixture self-test</name>
  <files>tests/conftest.py, tests/test_conftest_fixtures.py</files>
  <read_first>
    - tests/phase-13/lib.sh (read make_bare_repo ~21-29 — git identity, gpgsign=false, --allow-empty seed, AND the exact commit message it uses)
    - tests/phase-10/lib.sh (read make_fixture_repo ~20-36 — copies a fixtures/<name>/ tree EXCLUDING per-fixture README.md into a seeded repo; assert_byte_equal ~41-54; note its commit message — REVIEWS MEDIUM: make_bare_repo "seed" vs make_fixture_repo "fixture seed" — unify both fixtures on ONE SEED_MSG)
    - tests/phase-20/test_pdf_extract_markers.sh (read the Ollama curl-probe SKIP idiom ~line 53 — mirrored as pytest.mark.skipif)
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-RESEARCH.md (§Code Examples → conftest.py — the exact _git/git_repo/fixture_repo/assert_golden_tree/skipif code; Don't-Hand-Roll [tmp_path, capsys/capfd])
    - .planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-REVIEWS.md (MEDIUM "Pytest fixtures not behaviorally identical" — fixture_repo tmp_path reuse + commit message; "make_bare_repo seed vs make_fixture_repo fixture seed" — fold the cheap SEED_MSG unification)
  </read_first>
  <action>
Create `tests/conftest.py` mirroring the bash fixtures behaviorally (RESEARCH §Code Examples → conftest). Use `tmp_path` + `subprocess.run(["git", ...])`. Keep the SAME git identity (`fixture@example.com` / `Fixture`), `git init -q -b main`, and `git -c commit.gpgsign=false commit -q --allow-empty`. REVIEWS MEDIUM (SEED_MSG unification — cheap fold-in): the bash `make_bare_repo` uses `seed` and `make_fixture_repo` uses `fixture seed`; unify BOTH conftest fixtures on ONE `SEED_MSG` constant set to make_bare_repo's exact message (read it — do not invent). REVIEWS MEDIUM (fresh-per-call): the `fixture_repo` factory must NOT reuse one `tmp_path` across factory calls — each call builds into a FRESH isolated directory via `tmp_path_factory.mktemp(...)`.

```python
import subprocess, shutil, os
from pathlib import Path
import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
FIXTURES  = REPO_ROOT / "tests"
SEED_MSG  = "<EXACT message read from make_bare_repo — e.g. 'seed'>"   # ONE source of truth (REVIEWS MEDIUM)

def _git(cwd, *args):
    subprocess.run(["git", *args], cwd=cwd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def _seed(repo: Path):
    _git(repo, "init", "-q", "-b", "main")
    _git(repo, "config", "user.email", "fixture@example.com")
    _git(repo, "config", "user.name", "Fixture")

@pytest.fixture
def git_repo(tmp_path):
    """Fresh seeded git repo (mirrors make_bare_repo)."""
    _seed(tmp_path)
    _git(tmp_path, "-c", "commit.gpgsign=false", "commit", "-q",
         "--allow-empty", "-m", SEED_MSG)
    return tmp_path

@pytest.fixture
def fixture_repo(tmp_path_factory):
    """Copy tests/phase-NN/fixtures/<name>/ into a FRESH seeded repo per call
    (mirrors make_fixture_repo; excludes per-fixture README.md). REVIEWS MEDIUM:
    a fresh tmp dir PER call — no state accumulation across factory invocations."""
    def _make(phase, name):
        repo = tmp_path_factory.mktemp(f"fixture-{phase}-{name}")
        src = FIXTURES / f"phase-{phase}" / "fixtures" / name
        for f in src.rglob("*"):
            if f.is_file() and f.name != "README.md":
                dst = repo / f.relative_to(src)
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(f, dst)
        _seed(repo)
        _git(repo, "add", "-A")
        _git(repo, "-c", "commit.gpgsign=false", "commit", "-q",
             "--allow-empty", "-m", SEED_MSG)
        return repo
    return _make

def assert_golden_tree(actual_dir: Path, golden_dir: Path):
    """Byte-exact directory comparison helper (TEST-05)."""
    a = {p.relative_to(actual_dir): p for p in actual_dir.rglob("*") if p.is_file()}
    g = {p.relative_to(golden_dir): p for p in golden_dir.rglob("*") if p.is_file()}
    assert set(a) == set(g), f"tree mismatch: {set(a) ^ set(g)}"
    for rel in g:
        assert a[rel].read_bytes() == g[rel].read_bytes(), f"byte diff: {rel}"

def _ollama_up():
    import urllib.request
    try:
        urllib.request.urlopen("http://localhost:11434/api/tags", timeout=2); return True
    except Exception:
        return False

requires_ollama  = pytest.mark.skipif(not _ollama_up(), reason="Ollama unreachable")
requires_network = pytest.mark.skipif(os.environ.get("NO_NETWORK") == "1",
                                      reason="network disabled")
```
(Replace `SEED_MSG` with the EXACT message the bash `make_bare_repo` uses — read it first.)

Create `tests/test_conftest_fixtures.py`:
1. `test_git_repo_is_seeded(git_repo)` — assert `(git_repo/'.git').is_dir()`, branch is `main`, `git log --oneline` has exactly one seed commit.
2. `test_git_identity(git_repo)` — assert `git config user.email` == `fixture@example.com` and `user.name` == `Fixture`.
3. `test_seed_msg_matches_make_bare_repo()` — REVIEWS MEDIUM: assert conftest `SEED_MSG` equals the message in `tests/phase-13/lib.sh make_bare_repo` (grep the source) so the unification is enforced, not assumed.
4. `test_assert_golden_tree_roundtrip(tmp_path)` — build two identical dir trees, assert pass; mutate one byte, assert `AssertionError`.
5. `test_fixture_repo_fresh_per_call(fixture_repo, tmp_path)` — REVIEWS MEDIUM: build a tiny self-contained source tree (a `README.md` + a real file), call the README-exclusion logic twice, and assert (a) `README.md` is absent in each result, and (b) the two results are in DISTINCT directories (no shared/accumulated state). Use a self-contained tmp source so this does not depend on a specific phase fixture.

Import `assert_golden_tree` from conftest (`from conftest import assert_golden_tree`, adding `tests/` to `sys.path` if needed). Do NOT modify any existing `tests/phase-*/lib.sh` (D-13).
  </action>
  <verify>
    <automated>python3 -m venv /tmp/p22v3 && /tmp/p22v3/bin/pip -q install pytest -e . && /tmp/p22v3/bin/python -m pytest tests/test_conftest_fixtures.py -q</automated>
  </verify>
  <acceptance_criteria>
    - `test -f tests/conftest.py` exits 0
    - `grep -q 'def git_repo' tests/conftest.py && grep -q 'def fixture_repo' tests/conftest.py` exits 0
    - `grep -q 'fixture@example.com' tests/conftest.py && grep -q 'commit.gpgsign=false' tests/conftest.py` exits 0 (git identity preserved)
    - `grep -q 'init.*-b.*main' tests/conftest.py` exits 0 (branch main)
    - `grep -q 'tmp_path_factory' tests/conftest.py` exits 0 (fresh tmp dir per fixture_repo call — REVIEWS MEDIUM)
    - `grep -q 'SEED_MSG' tests/conftest.py && grep -c 'SEED_MSG' tests/conftest.py | grep -qE '[2-9]|[0-9][0-9]'` exits 0 (ONE SEED_MSG used by BOTH fixtures — REVIEWS MEDIUM SEED_MSG unification)
    - `grep -q 'def assert_golden_tree' tests/conftest.py` exits 0
    - `grep -q 'README.md' tests/conftest.py` exits 0 (README exclusion mirrored)
    - `grep -qE 'requires_ollama|skipif' tests/conftest.py` exits 0 (Ollama/network markers)
    - `grep -q 'fresh_per_call' tests/test_conftest_fixtures.py && grep -q 'seed_msg_matches' tests/test_conftest_fixtures.py` exits 0 (the no-state-accumulation + SEED_MSG-unification tests exist — REVIEWS MEDIUM)
    - `git diff --name-only HEAD -- tests/phase-10/lib.sh tests/phase-13/lib.sh | wc -l` returns `0` (bash helpers untouched)
    - `pytest tests/test_conftest_fixtures.py` passes in the venv (seeded repo + identity + golden-tree + fresh-per-call README exclusion + SEED_MSG match)
  </acceptance_criteria>
  <done>conftest.py provides git_repo/fixture_repo behaviorally identical to make_bare_repo/make_fixture_repo (same identity, ONE unified SEED_MSG matching make_bare_repo, gpgsign=false, README exclusion, FRESH tmp dir per call), assert_golden_tree, and Ollama/network skipif markers; fixture self-test (incl. fresh-per-call + SEED_MSG match) passes; bash helpers untouched.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| seam ↔ tool process | The seam wraps every invocation; a buggy seam could mask divergence (false parity) or corrupt the baseline |
| WIKI_IMPL branch ↔ worktree oracle | If the bash leg ever runs the (eventually-python) shim, the oracle is no longer held-fixed and the differential vanishes |
| oracle worktree ↔ script-relative lib resolution | If the oracle does not preserve the bin/-relative layout, script-relative tools abort under set -e (the cycle-2 keystone failure) |
| py lane ↔ the .sh shim | If the py lane runs `python3 -m` directly, a broken shim (part of the PKG-03 contract) is never exercised on the parity path (cycle-3 finding #3) |
| seam PYTHONPATH preload ↔ shim's own bootstrap | The seam's PYTHONPATH export can MASK a shim missing its own bootstrap; the shim-smoke test must clear the seam env to expose it (cycle-4 finding #3) |
| run-all child process ↔ per-call channels | A black-box child test process has no handle to its IT_* / fixture dir; without IT_CAPTURE_DIR, routed channels cannot be collected (cycle-3 finding #2) |
| capture key ↔ shared IT_CAPTURE_DIR | A per-process-only counter collides across distinct test files sharing one IT_CAPTURE_DIR — silent overwrite drops coverage (cycle-4 finding #1) |
| baseline resolution ↔ ported manifest | A silent HEAD fallback while a tool is ported collapses the differential to python-vs-python (N-4) |
| oracle worktree path ↔ parallel clusters | A single shared /tmp path races under Phase-23 parallelism (N-5) |
| normalizer ↔ contractual output | Over-aggressive redaction masks a real divergence; under-redaction yields noise |
| pytest fixture ↔ git | Fixtures shell out to git in tmp dirs; no network/egress surface |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-22-09 | Spoofing | seam produces false parity (inert WIKI_IMPL) | mitigate | The seam BRANCHES on WIKI_IMPL and the bash leg runs a worktree-backed held-fixed oracle independent of the shim (REVIEWS HIGH#1). After Phase 25 flips a shim to python, `WIKI_IMPL=bash` still runs the frozen bash, yielding a real differential. Acceptance asserts the branch + the worktree + the manifest gate. |
| T-22-35 | Denial of Service | script-relative tool aborts in the oracle (cp-into-flat-dir) | mitigate | The oracle runs <worktree>/bin/<tool>.sh, preserving bin/lib + schema/ so audit-claims/brownfield/gen-skills resolve their real libs (REVIEWS HIGH#1). `test_oracle_scriptrelative.sh` runs all three through the oracle via REACH-LIB subcommands (not the vacuous --help) and asserts no abort — pre-fix-failing, non-vacuous (cycle-3 finding #1 refinement). |
| T-22-43 | Spoofing | a broken .sh shim passes parity (py lane bypasses it) | mitigate | The py lane runs `bash $REPO_ROOT/bin/<tool>.sh` (the actual shim), so a broken PYTHONPATH/quoting/module/exec is caught on the parity path. `test_shim_smoke.sh` drives a deliberately-broken shim and asserts it is caught (cycle-3 HIGH finding #3, pre-fix-failing). |
| T-22-55 | Spoofing | a bootstrap-free shim passes parity (seam PYTHONPATH masks the missing bootstrap) | mitigate | `test_shim_smoke.sh` runs with the seam's PYTHONPATH CLEARED, so a shim missing its own checkout-hermetic bootstrap FAILS (ModuleNotFoundError) while the canonical shim PASSES (cycle-4 finding #3, pre-fix-failing). The normal lane keeps the seam PYTHONPATH (must_not_regress). |
| T-22-44 | Tampering | routed-suite per-test channels uncollectable from a black-box child | mitigate | `invoke_tool` honors IT_CAPTURE_DIR and self-records each call's channels into a keyed sub-dir, so run-all collects routed channels with no <repo> arg. `test_capture_dir.sh` proves per-call keying + injected-divergence-caught (cycle-3 HIGH finding #2, pre-fix-failing). |
| T-22-56 | Tampering | capture-key collision across test files drops routed coverage | mitigate | The capture key nests `<testbasename>-<pid>` ABOVE `<tool>-<counter>`, so distinct test files sharing one IT_CAPTURE_DIR never overwrite each other's first call. `test_capture_dir.sh` proves two distinct test-file subprocesses' first call land in DISTINCT dirs (cycle-4 finding #1, pre-fix-failing). |
| T-22-64 | Tampering | staged-parity gate cannot run (single REPO_ROOT bound to both the py body and the oracle git) | mitigate | The seam exposes WIKI_EXEC_ROOT (py-lane body/src/manifest) + WIKI_ORACLE_GIT_ROOT (oracle git + freeze-baseline.sha), both defaulting to $REPO_ROOT and part of the FROZEN surface; oracle-worktree.sh runs git against $(_oracle_git_root). Plan 06 sets them to the staged index + real repo. Resolves the cycle-5 freeze/interface deadlock (cycle-6 fix #1/#2). |
| T-22-65 | Tampering | tree channel misses a `--root`-fixture divergence (snapshots $PWD) | mitigate | `_it_footprint_root` snapshots the `--root <dir>` fixture (or IT_FOOTPRINT_ROOT), not `$PWD`, so the 86 `--root`-without-cd invocations capture the real mutated tree. `test_capture_dir.sh` asserts the tree reflects the `--root` dir (cycle-6 fix #4, pre-fix-failing). |
| T-22-66 | Spoofing | --require-parity finds no pairs (PID in key differs across runs) → vacuous green | mitigate | `it_pairing_key` strips the `-<pid>`; Plan 05's --require-parity pairs on the pid-independent `<suite>/<testbasename>/<tool>-<NN>` identity and FAILS if a pairing key is present on one side but missing on the other (cycle-6 fix #4). |
| T-22-67 | Spoofing | a real Phase-23 ported shim lacks its bootstrap but passes (only the exemplar was checked) | mitigate | `test_shim_smoke.sh` iterates `tests/ported.manifest` and asserts each real shim owns its bootstrap with the seam PYTHONPATH cleared; empty in P22, it enforces per real shim in Phase 25; the loop is proven now via a WIKI_EXEC_ROOT scaffold (cycle-6 fix #5). |
| T-22-45 | Spoofing | silent HEAD fallback collapses the differential (both legs python) | mitigate | When ported.manifest is non-empty and no reachable baseline resolves, the oracle FAILS LOUDLY (not HEAD), and tag-vs-SHA equality is required when both exist (N-4). |
| T-22-46 | Denial of Service | shared /tmp worktree path races under Phase-23 parallelism | mitigate | The worktree path is per-repo/per-baseline keyed (hash of $REPO_ROOT + ref), with the WIKI_ORACLE_WORKTREE override (N-5). |
| T-22-10 | Tampering | normalizer masks a real divergence (false parity) | mitigate | Narrowed to time-bearing timestamps only; bare-date + blanket-hex redaction removed. The normalizer self-test proves a WRONG contractual date/ID/hash is NOT masked, and lint JSON order is not reordered. |
| T-22-11 | Repudiation | seam alters bytes vs direct call (baseline drift) | mitigate | `test_invoke_tool_selfparity.sh` asserts WIKI_IMPL=bash through the seam is `cmp`-equal to a direct oracle call, protecting baseline attribution (D-13). |
| T-22-26 | Denial of Service | expected-nonzero exit aborts a set -e caller | mitigate | `invoke_tool` returns 0 and exposes status only via IT_EXIT (REVIEWS HIGH#2); `test_invoke_tool_seterm.sh` runs the exact call-site form under set -e and proves the after-line is reached and IT_EXIT holds the real code. |
| T-22-27 | Spoofing | tree channel misses exec-bit/symlink/empty-dir divergence | mitigate | The tree manifest records type + mode + symlink target + empty dirs, so a port that changes a generated script's executability or a symlink target is caught. |
| T-22-12 | Information Disclosure | fixture/normalizer comments embed vault terms (template-public) | accept | `tests/lib/*` uses only neutral placeholders; `bin/check-neutrality.sh` is the backstop. Low risk. |
</threat_model>

<verification>
- `bash tests/lib/test_oracle_scriptrelative.sh` exits 0 (audit-claims [real --since/--format] + brownfield [scan --root] + gen-skills --check run through the worktree oracle past their lib-resolution lines without aborting — REVIEWS HIGH#1 + finding #1 refinement, pre-fix-failing + non-vacuous).
- `bash tests/lib/test_invoke_tool_seterm.sh` exits 0 (the set -e caller survives + IT_EXIT holds the real code — REVIEWS HIGH#2, pre-fix-failing).
- `bash tests/lib/test_capture_dir.sh` exits 0 (per-call keyed IT_CAPTURE_DIR record + CROSS-TEST-FILE key distinctness + injected byte divergence caught — REVIEWS cycle-3 finding #2 + cycle-4 finding #1, pre-fix-failing).
- `bash tests/lib/test_shim_smoke.sh` exits 0 (seam PYTHONPATH cleared: a bootstrap-free shim FAILS, the canonical shim PASSES, and a broken shim is caught on the py lane — REVIEWS cycle-3 finding #3 + cycle-4 finding #3, pre-fix-failing).
- `bash tests/lib/test_normalize.sh` exits 0 (redaction pinned; wrong contractual value NOT masked; JSON order preserved).
- `bash tests/lib/test_invoke_tool_selfparity.sh` exits 0 (seam == direct call under WIKI_IMPL=bash).
- `pytest tests/test_conftest_fixtures.py` passes in a venv (fixtures behaviorally mirror the bash helpers; fresh per call; SEED_MSG unified).
- `git diff --name-only HEAD -- tests/phase-*/lib.sh` is empty (D-13: helpers untouched).
</verification>

<success_criteria>
- TEST-01: `invoke_tool` BRANCHES on `WIKI_IMPL=bash|py`, runs a WORKTREE-backed held-fixed bash oracle for bash (script-relative tools resolve their real libs — REVIEWS HIGH#1) + the bin/<tool>.sh SHIM for ported tools (finding #3), returns 0 with status only via IT_EXIT (REVIEWS HIGH#2), self-records per-call channels into IT_CAPTURE_DIR under a COLLISION-PROOF key (finding #2 + cycle-4 finding #1), captures 4 channels (incl. exec-bit/symlink/empty-dir tree) in a <case>/ layout; `WIKI_IMPL=bash` byte-identical to today.
- TEST-05: `conftest.py` with `git_repo`/`fixture_repo` (fresh per call, unified SEED_MSG) + `assert_golden_tree` + skipif markers, behaviorally identical to the bash helpers.
- REVIEWS HIGH#1 (worktree oracle for script-relative tools), HIGH#2 (return 0 + IT_EXIT-only) resolved; cycle-3 finding #1 refinement (reach-lib subcommands), finding #2 (IT_CAPTURE_DIR per-call record + catch-a-divergence), finding #3 (py lane via shim + shim-smoke) resolved; cycle-4 finding #1 (collision-proof capture key) + cycle-4 finding #3 (shim-smoke with seam PYTHONPATH cleared) resolved; N-4 (loud-fail + tag/SHA equality), N-5 (per-repo path) folded; cycle-1 HIGH#2/#5/#6 normalizer/tree/fixture resolutions preserved.
- The 12 per-phase `make_*_repo` helpers are untouched (D-13).
</success_criteria>

<output>
After completion, create `.planning/phases/24-foundation-package-skeleton-frozen-shared-core-parity-oracle/24-03-SUMMARY.md`
</output>
</content>
