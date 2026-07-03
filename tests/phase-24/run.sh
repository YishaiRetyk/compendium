#!/usr/bin/env bash
# tests/phase-24/run.sh -- Phase 24 test aggregator (characterization goldens + guards).
# Iterates tests/phase-24/test_*.sh via the glob (AUTO-DISCOVERY: later-added tests —
# the shim-preflight/exit-3 contract test, the inventory guard, Plan 06's freeze/hook
# self-tests — join with NO edit here). Tallies pass/fail, exits non-zero on any failure.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TOTAL=0
FAILED_TESTS=()

shopt -s nullglob
for t in "$SCRIPT_DIR"/test_*.sh; do
    TOTAL=$((TOTAL + 1))
    name="$(basename "$t")"
    echo "--- Running $name ---"
    if bash "$t"; then
        PASS=$((PASS + 1))
        echo "--- PASS $name ---"
    else
        FAIL=$((FAIL + 1))
        FAILED_TESTS+=("$name")
        echo "--- FAIL $name ---"
    fi
done

echo ""
echo "PHASE 24 TESTS: ${PASS}/${TOTAL}"
if [ "$FAIL" -gt 0 ]; then
    echo "Failed: ${FAILED_TESTS[*]}" >&2
    exit 1
fi
exit 0
