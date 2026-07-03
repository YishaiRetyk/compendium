#!/usr/bin/env bash
# Phase 24 Plan 06 (REVIEWS HIGH#2 hook leg + HIGH#6 + cycle-4 finding #5): BEHAVIOR-level
# hook self-test. Asserts observable OUTCOMES (skip reached / block / parity path executed),
# not string presence:
#   1. the freeze step's exit-3 SKIP branch is REACHED on an unreachable baseline (the
#      buggy `if ! cmd; then rc=$?` idiom makes it dead — this uses the hook's exact form);
#   2. the freeze step BLOCKS on real staged frozen-surface drift;
#   3. the parity gate EXECUTES the materialize+compare path on a staged src/compendium
#      change (NOT the re-entry skip, NOT the fast-skip) — NON-VACUOUS because the gate
#      excludes only the two recursive hook self-tests, so this test never re-enters it;
#   4. the parity gate fast-skips a non-migration commit.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }

# The EXACT freeze capture+branch logic the hook uses (REVIEWS HIGH#2: `if cmd; then rc=0;
# else rc=$?; fi` — never `if ! cmd`). Returns 0 = commit allowed, 1 = blocked; emits the
# same skip/block messages.
hook_freeze_step() {
    local fc_rc
    if bash bin/check-common-freeze.sh --staged; then
        fc_rc=0
    else
        fc_rc=$?
    fi
    if [ "$fc_rc" = "3" ]; then
        echo "freeze guard skipped (baseline unreachable) — proceeding." >&2
    elif [ "$fc_rc" != "0" ]; then
        echo "Frozen surface touched — commit blocked." >&2
        return 1
    fi
    return 0
}

# Scratch repo for the freeze cases (guard copied in; mini frozen surface).
FZ="$(mktemp -d)"
mkdir -p "$FZ/bin" "$FZ/src/compendium/common" "$FZ/tests"
cp "$REPO_ROOT/bin/check-common-freeze.sh" "$FZ/bin/"
printf '# module\n' > "$FZ/src/compendium/common/x.py"
(
    cd "$FZ"
    git init -q -b main
    git config user.email fixture@example.com && git config user.name Fixture
    git add -A && git -c commit.gpgsign=false commit -qm seed
    git rev-parse HEAD > tests/freeze-baseline.sha
    git add tests/freeze-baseline.sha && git -c commit.gpgsign=false commit -qm pin
)

# 1. SKIP branch reached on an unreachable baseline (commit ALLOWED, not blocked).
out="$( cd "$FZ" && printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' > tests/freeze-baseline.sha \
        && hook_freeze_step 2>&1 && echo HOOK_CONTINUED )" || fail "unreachable baseline BLOCKED the commit (skip branch dead — the HIGH#2 bug)"
echo "$out" | grep -q 'freeze guard skipped' || fail "skip message not emitted: $out"
echo "$out" | grep -q 'HOOK_CONTINUED' || fail "hook did not continue past the skip branch"
( cd "$FZ" && git checkout -q -- tests/freeze-baseline.sha )
echo "ok: exit-3 skip branch reached (commit allowed, message emitted)"

# 2. Hard-block on real staged frozen drift.
rc=0
out="$( cd "$FZ" && printf '# drift\n' >> src/compendium/common/x.py && git add src/compendium/common/x.py \
        && hook_freeze_step 2>&1 )" || rc=$?
[ "$rc" != "0" ] || fail "staged frozen drift NOT blocked: $out"
echo "$out" | grep -qi 'blocked\|Frozen surface' || fail "block message missing: $out"
( cd "$FZ" && git reset -q HEAD -- src/compendium/common/x.py && git checkout -q -- src/compendium/common/x.py )
rm -rf "$FZ"
echo "ok: staged frozen-surface drift blocks the commit"

# 3. Parity gate EXECUTES the materialize+compare path (non-vacuous) on a staged
#    src/compendium change in the gate scaffold.
SC="$(build_parity_gate_scaffold)"
SC_WT="$(scaffold_oracle_worktree_dir "$SC")"
trap 'rm -rf "$SC" "$SC_WT"' EXIT
scaffold_write_shim "$SC"                      # working faketool = the canonical shim -> python
( cd "$SC" && printf '# staged tweak\n' >> src/compendium/faketool.py && git add bin/faketool.sh src/compendium/faketool.py )
rc=0
out="$( cd "$SC" && WIKI_PARITY_ONLY_SUITES="$SC/tests/phase-divtest" bash bin/check-staged-parity.sh 2>&1 )" || rc=$?
[ "$rc" = "0" ] || fail "parity gate blocked a parity-green staged change (rc=$rc): $out"
echo "$out" | grep -q 'materializing the STAGED index' || fail "gate did NOT reach the materialize path: $out"
echo "$out" | grep -qE 'PARITY OK|staged-index parity green' || fail "gate did NOT reach the compare path: $out"
echo "$out" | grep -q 're-entry detected' && fail "gate took the re-entry skip branch (vacuous run — cycle-4 finding #5)"
echo "$out" | grep -q 'no migration-relevant change' && fail "gate took the fast-skip branch (vacuous run)"
echo "ok: parity gate executed materialize+compare (non-vacuous; no skip branch)"

# 4. Fast-skip for a non-migration staged change.
( cd "$SC" && git reset -q && printf 'note\n' > notes.md && git add notes.md )
rc=0
out="$( cd "$SC" && bash bin/check-staged-parity.sh 2>&1 )" || rc=$?
[ "$rc" = "0" ] || fail "non-migration commit blocked (rc=$rc): $out"
echo "$out" | grep -q 'no migration-relevant change' || fail "fast-skip message missing: $out"
echo "ok: non-migration commit fast-skips the gate"

echo "PASS: hook behavior (skip-branch live, drift blocks, parity path executes, fast-skip)"
