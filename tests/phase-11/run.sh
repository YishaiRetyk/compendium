#!/usr/bin/env bash
# tests/phase-11/run.sh -- Phase 11 test aggregator (harness for brownfield suggest + verify tests).
# Iterates tests/phase-11/test_*.sh, tallies pass/fail, exits non-zero on any failure.
#
# --expected-by <plan-id> filter (item 6 contract decision):
#   Narrows the run to tests whose second-line comment is `# EXPECTED_BY: <plan-id>`.
#   Valid plan-id values: 11-01 | 11-02 | 11-03 | 11-04 | 11-05.
#   Tests without an EXPECTED_BY comment are ALWAYS counted (safety fallback).
set -euo pipefail

EXPECTED_BY=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --expected-by)
            if [ "$#" -lt 2 ]; then
                echo "ERROR: --expected-by requires a plan-id argument" >&2
                exit 1
            fi
            EXPECTED_BY="$2"
            case "$EXPECTED_BY" in
                11-01|11-02|11-03|11-04|11-05) ;;
                *)
                    echo "ERROR: --expected-by must be one of: 11-01, 11-02, 11-03, 11-04, 11-05 (got: $EXPECTED_BY)" >&2
                    exit 1
                    ;;
            esac
            shift 2
            ;;
        --help|-h)
            cat <<'EOF'
Usage: tests/phase-11/run.sh [--expected-by <plan-id>]
  --expected-by <plan-id>   Run only tests tagged `# EXPECTED_BY: <plan-id>`
                            (valid values: 11-01, 11-02, 11-03, 11-04, 11-05).
                            Tests without an EXPECTED_BY tag are always counted.
  --help, -h                Show this help.
EOF
            exit 0
            ;;
        *) echo "ERROR: unknown argument: $1" >&2; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TOTAL=0
FAILED_TESTS=()

shopt -s nullglob
for t in "$SCRIPT_DIR"/test_*.sh; do
    if [ -n "$EXPECTED_BY" ]; then
        if ! grep -q "^# EXPECTED_BY: $EXPECTED_BY\$" "$t" 2>/dev/null; then
            continue
        fi
    fi
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
if [ -n "$EXPECTED_BY" ]; then
    echo "PHASE 11 TESTS: ${PASS}/${TOTAL} (expected-by ${EXPECTED_BY})"
else
    echo "PHASE 11 TESTS: ${PASS}/${TOTAL}"
fi
if [ "$FAIL" -gt 0 ]; then
    echo "Failed: ${FAILED_TESTS[*]}" >&2
    exit 1
fi
exit 0
