#!/usr/bin/env bash
# Phase 24 Plan 06 (cycle-3 finding #4 + cycle-4 finding #4 + cycle-3/4 finding #5):
#   1. STAGED-BROKEN + WORKING-GOOD is BLOCKED — with a SEEDED ported.manifest entry so
#      the Python leg GENUINELY runs (an empty manifest -> py falls through to bash -> no
#      divergence -> vacuous). Proves the gate tests the STAGED blob via STAGED_EXEC_ROOT
#      while the oracle's git resolution succeeds against ORACLE_GIT_ROOT (real .git).
#   2. Staged-good passes (the gate is not over-blocking).
#   3. BOUNDED TERMINATION: the recursion-prone hook self-test exits 0 under `timeout`
#      (not 124) — the --exclude-test knob breaks the gate->run-all->phase-24->gate loop
#      while keeping the run-assertion non-vacuous (asserted inside test_precommit_hooks).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
# Env hygiene: these self-tests assert the gates' DEFAULT behavior — a commit-level
# escape hatch (FREEZE_ALLOW_REBASE on a D-09 commit, PARITY_GATE_SKIP) or GOLDEN_FREEZE
# leaking in from the invoking environment would invert the expected exits.
unset FREEZE_ALLOW_REBASE PARITY_GATE_SKIP GOLDEN_FREEZE


fail() { echo "FAIL: $1" >&2; exit 1; }

SC="$(build_parity_gate_scaffold)"          # seeds tests/ported.manifest with faketool (cycle-4 #4)
SC_WT="$(scaffold_oracle_worktree_dir "$SC")"
trap 'rm -rf "$SC" "$SC_WT"' EXIT

# 1. STAGE a DIVERGENT shim+module (the broken version), then OVERWRITE the working tree
#    with a PASSING version, leaving it UNSTAGED. The gate must test the STAGED blob.
scaffold_write_shim "$SC"
scaffold_write_module "$SC" 'OK X\n'        # DIVERGES from the committed bash oracle ("OK\n")
( cd "$SC" && git add bin/faketool.sh src/compendium/faketool.py )
scaffold_write_module "$SC" 'OK\n'          # working tree = PASSING; left UNSTAGED
rc=0
out="$( cd "$SC" && WIKI_PARITY_GATE_ONLY_SUITES="$SC/tests/phase-divtest" bash bin/check-staged-parity.sh 2>&1 )" || rc=$?
[ "$rc" != "0" ] || fail "staged-broken + working-good was NOT blocked — the gate tested the working tree, or the py leg never ran (vacuous): $out"
echo "$out" | grep -qE 'PARITY GATE BLOCK|PARITY FAIL' || fail "block happened without a parity-divergence diagnosis: $out"
echo "ok: staged-broken + working-good BLOCKED (staged blob tested; python leg genuinely ran)"

# 2. The inverse: stage the PASSING module too — the gate must NOT block.
( cd "$SC" && git add src/compendium/faketool.py )
rc=0
out="$( cd "$SC" && WIKI_PARITY_GATE_ONLY_SUITES="$SC/tests/phase-divtest" bash bin/check-staged-parity.sh 2>&1 )" || rc=$?
[ "$rc" = "0" ] || fail "staged-good was over-blocked (rc=$rc): $out"
echo "ok: staged-good passes (no over-blocking)"

# 3. Bounded termination of the recursion-prone path (cycle-3 finding #5): the hook
#    self-test must finish within the bound — 124 means the recursion returned.
rc=0
timeout 120 bash "$REPO_ROOT/tests/phase-24/test_precommit_hooks.sh" >/dev/null 2>&1 || rc=$?
[ "$rc" != "124" ] || fail "test_precommit_hooks hit the timeout (recursion NOT bounded)"
[ "$rc" = "0" ] || fail "test_precommit_hooks failed under the bound (rc=$rc)"
echo "ok: hook self-test terminates within the bound (rc=0, not 124)"

echo "PASS: staged-index gate (blocked/pass/bounded) — cycle-3 #4/#5 + cycle-4 #4/#5"
