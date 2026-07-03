#!/usr/bin/env bash
# bin/check-staged-parity.sh — Phase 24 (REVIEWS HIGH#6 + cycle-3 #4/#5 + cycle-4 #4/#5 +
# cycle-6 #1/#2/#3): the LOCAL parity gate. CI parity runs ONLY in GitHub Actions, which
# NEVER runs on the never-pushed private migration branches — this gate makes parity
# locally enforceable at commit time.
#
# It tests the STAGED INDEX, not the working tree (cycle-3 #4: an unstaged fix must not
# mask a broken staged commit), via the EXPLICIT two-root split (cycle-4 #4):
#   STAGED_EXEC_ROOT = a materialized temp tree of the index (git checkout-index — NO .git)
#                      from which the py leg reads the STAGED shim bodies / src / manifest;
#   ORACLE_GIT_ROOT  = the REAL repo (.git intact) against which the seam's worktree-oracle
#                      git commands (worktree add / rev-parse / freeze-baseline.sha) resolve.
# The materialized tree has NO .git (the oracle's git would fail there) and the real repo
# holds WORKING-tree bodies (not staged) — the split is what makes BOTH legs correct. It is
# wired by CONSUMING the frozen seam's per-lane root knobs as env vars (cycle-6 #1/#2):
# WIKI_EXEC_ROOT + WIKI_ORACLE_GIT_ROOT — this gate never edits tests/lib/invoke_tool.sh or
# tests/lib/oracle-worktree.sh (they are FROZEN; consume, never edit).
#
# Recursion (cycle-3 #5 + cycle-4 #5 + cycle-6 #3): the fallback runs the full enumerated
# run-all, whose phase-24 suite contains the two hook self-tests that re-invoke this gate.
# The PRIMARY break: exclude ONLY those two TEST FILES via the runner's --exclude-test knob
# (phase-24 STAYS in the run — every other 4-channel golden still executes on this, the only
# private-branch gate). WIKI_PARITY_GATE_ACTIVE is the belt-and-suspenders secondary bound.
#
# Escape hatch: PARITY_GATE_SKIP=1 exits 0 with a loud warning (WIP commits only; its use
# must be recorded in the owning plan's SUMMARY — N-7).
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/check-staged-parity.sh

Runs the parity suites against the MATERIALIZED STAGED INDEX when bin/, src/compendium/,
or tests/ported.manifest is staged. Blocks (exit 2) on any per-test regression or channel
byte-divergence. Fast-skips (exit 0) when nothing migration-relevant is staged.
Env: PARITY_GATE_SKIP=1 (WIP escape hatch, N-7) | WIKI_PARITY_GATE_ACTIVE (re-entrancy).
EOF
}
case "${1:-}" in --help|-h) usage; exit 0 ;; esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if [ "${PARITY_GATE_SKIP:-0}" = "1" ]; then
    echo "WARNING: PARITY GATE SKIPPED (PARITY_GATE_SKIP=1) — WIP only; record this in the plan SUMMARY (N-7)." >&2
    exit 0
fi

# RE-ENTRANCY GUARD (cycle-3 #5 — secondary bound; the primary break is --exclude-test below).
if [ "${WIKI_PARITY_GATE_ACTIVE:-0}" = "1" ]; then
    echo "parity gate re-entry detected — short-circuiting (nested invocation)" >&2
    exit 0
fi
export WIKI_PARITY_GATE_ACTIVE=1

# Migration-relevant staged set (the fast path for ordinary commits).
STAGED_SET="$(git diff --cached --name-only -- bin/ src/compendium/ tests/ported.manifest)"
if [ -z "$STAGED_SET" ]; then
    echo "no migration-relevant change staged — parity gate skipped"
    exit 0
fi
echo "parity gate: migration-relevant staged paths:" >&2
printf '  %s\n' $STAGED_SET >&2

# THE STAGED_EXEC_ROOT vs ORACLE_GIT_ROOT SPLIT (cycle-4 #4).
ORACLE_GIT_ROOT="$REPO_ROOT"                       # real repo, .git intact (oracle git commands)
STAGED_EXEC_ROOT="$(mktemp -d)"                    # materialized index, no .git (staged py bodies)
BASHCH="$(mktemp -d)"; PYCH="$(mktemp -d)"
trap 'rm -rf "$STAGED_EXEC_ROOT" "$BASHCH" "$PYCH"' EXIT
echo "materializing the STAGED index into $STAGED_EXEC_ROOT (git checkout-index; no working-tree mutation, no .git)..." >&2
git checkout-index -a -f --prefix="$STAGED_EXEC_ROOT/"

# Safe default: the full enumerated run-all on both legs + the channel byte-comparison,
# EXCLUDING ONLY the two recursive hook self-tests (cycle-6 #3 — NOT the whole phase-24
# suite; its goldens are the richest parity signal on private branches).
EXCL="--exclude-test test_precommit_hooks.sh --exclude-test test_staged_parity_index.sh"

# bash leg: exec-root = the real repo (frozen bash bodies via the worktree oracle); git-root = the real repo.
if WIKI_IMPL=bash WIKI_EXEC_ROOT="$ORACLE_GIT_ROOT" WIKI_ORACLE_GIT_ROOT="$ORACLE_GIT_ROOT" \
     bash "$ORACLE_GIT_ROOT/tests/run-all-suites.sh" --capture-channels "$BASHCH" $EXCL >&2; then bl_rc=0; else bl_rc=$?; fi
# py leg: exec-root = the STAGED index (staged shim + src + ported.manifest); git-root = the real repo (.git for the oracle).
if WIKI_IMPL=py WIKI_EXEC_ROOT="$STAGED_EXEC_ROOT" WIKI_ORACLE_GIT_ROOT="$ORACLE_GIT_ROOT" \
     bash "$ORACLE_GIT_ROOT/tests/run-all-suites.sh" --capture-channels "$PYCH" $EXCL >&2; then py_rc=0; else py_rc=$?; fi
# channel comparison (pid-independent pairing — cycle-6 #4): fails on byte-divergence OR unpaired keys.
if bash "$ORACLE_GIT_ROOT/tests/run-all-suites.sh" --require-parity "$BASHCH" "$PYCH" >&2; then rp_rc=0; else rp_rc=$?; fi

if [ "$bl_rc" != "0" ] || [ "$py_rc" != "0" ] || [ "$rp_rc" != "0" ]; then
    echo "" >&2
    echo "PARITY GATE BLOCK (bash=$bl_rc py=$py_rc channels=$rp_rc): the STAGED migration change" >&2
    echo "diverges from the held-fixed bash oracle (or regressed a pinned test)." >&2
    echo "Fix parity in the STAGED content, or commit WIP with PARITY_GATE_SKIP=1 (record it — N-7)." >&2
    exit 2
fi

echo "OK: staged-index parity green (bash leg, py leg, channel byte-comparison)"
exit 0
