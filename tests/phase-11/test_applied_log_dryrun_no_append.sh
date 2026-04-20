#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_applied_log_dryrun_no_append.sh — BRWN-14: dry-run
# invocations never append to applied.log (only --apply / advisory runs do).
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

if ! bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

if ! bash "$TMP/.brownfield/migrations/01-page-typing.sh" --dry-run >/dev/null 2>&1; then
    echo "FAIL: 01-page-typing.sh --dry-run not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

LOG="$TMP/.brownfield/applied.log"
if [ -f "$LOG" ]; then
    count=$(grep -c '^## 01-page-typing' "$LOG" || true)
    if [ "$count" != "0" ]; then
        echo "FAIL: dry-run appended to applied.log ($count 01 blocks found)" >&2
        exit 1
    fi
fi

echo "PASS $NAME"; exit 0
