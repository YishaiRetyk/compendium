#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_review_typing_eof_handling.sh — REVIEWS item 4:
# review-typing treats immediate EOF on stdin as clean abort / skip, NOT
# as an infinite loop. Wrapped in `timeout 3` so a hang becomes exit 124.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo small-vault-ambiguous)
trap 'rm -rf "$TMP"' EXIT

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

set +e
timeout 3 bash -c "bash \"$REPO_ROOT/bin/brownfield.sh\" review-typing --root \"$TMP\" </dev/null" >/dev/null 2>stderr.txt
ec=$?
set -e

if [ "$ec" = "124" ]; then
    echo "FAIL: review-typing hung on immediate EOF (timed out at 3s)" >&2
    cat stderr.txt >&2 || true
    rm -f stderr.txt
    exit 1
fi

# Must not be the Wave-0 stub (exit 2 from bin/brownfield.sh)
if grep -q "not yet implemented" stderr.txt 2>/dev/null; then
    rm -f stderr.txt
    echo "FAIL: review-typing hit the Wave-0 stub — Plan 11-04 pending" >&2
    exit 1
fi

rm -f stderr.txt
echo "PASS $NAME"; exit 0
