#!/usr/bin/env bash
# tests/phase-23/run.sh -- Phase 23 External Source Drift test aggregator.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
PASS=0; FAIL=0
run_test() {
    local name="$1"
    # Missing test file = FAILURE (a renamed test must not silently drop out).
    if [ ! -f "$SCRIPT_DIR/$name" ]; then
        echo "--- FAIL $name (test file missing) ---"; FAIL=$((FAIL+1)); return 0
    fi
    local OUT rc
    set +e
    OUT=$(bash "$SCRIPT_DIR/$name" 2>&1); rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
        echo "--- PASS $name ---"; PASS=$((PASS+1))
    else
        echo "--- FAIL $name ---"; echo "$OUT"; FAIL=$((FAIL+1))
    fi
}
run_test test_network_drift.sh
TOTAL=$((PASS+FAIL))
echo ""
echo "PHASE 23 TESTS: $PASS/$TOTAL"
[ "$FAIL" -eq 0 ]
