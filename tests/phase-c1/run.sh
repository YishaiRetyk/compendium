#!/usr/bin/env bash
# tests/phase-c1/run.sh -- C-1 ledger-emitter fallback suite aggregator (ADR-008
# failure handling). Iterates tests/phase-c1/test_*.sh via the glob (AUTO-DISCOVERY:
# later-added tests join with NO edit here). Tallies pass/fail, exits non-zero on any
# failure. Standalone/dev entrypoint — CI runs the same files through the pytest
# bridge (tests/test_blackbox_suites.py, suite "c1").
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
echo "PHASE C1 TESTS: ${PASS}/${TOTAL}"
if [ "$FAIL" -gt 0 ]; then
    echo "Failed: ${FAILED_TESTS[*]}" >&2
    exit 1
fi
exit 0
