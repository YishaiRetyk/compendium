#!/usr/bin/env bash
# tests/phase-09/run.sh -- Phase 09 test aggregator (harness for CI lint + privacy + contributor tests).
# Iterates tests/phase-09/test_*.sh, tallies pass/fail, exits non-zero on any failure.
set -euo pipefail

FULL=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --full) FULL=1; shift ;;
        --help|-h)
            cat <<'EOF'
Usage: tests/phase-09/run.sh [--full]
  --full   Reserved for future full-suite runs (no-op in P1).
EOF
            exit 0
            ;;
        *) echo "ERROR: unknown option: $1" >&2; exit 1 ;;
    esac
done

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
echo "PHASE 09 TESTS: ${PASS}/${TOTAL}"
if [ "$FAIL" -gt 0 ]; then
    echo "Failed: ${FAILED_TESTS[*]}" >&2
    exit 1
fi
exit 0
