#!/usr/bin/env bash
# tests/phase-15/run.sh -- Phase 15 test aggregator (added by Phase 24 Plan 05 — the suite
# existed without a runner). Iterates tests/phase-15/test_*.sh, tallies pass/fail, exits
# non-zero on any failure.
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
echo "PHASE 15 TESTS: ${PASS}/${TOTAL}"
if [ "$FAIL" -gt 0 ]; then
    echo "Failed: ${FAILED_TESTS[*]}" >&2
    exit 1
fi
exit 0
