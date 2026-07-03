#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_02_honest_no_eligible.sh — D-05: when a page has no
# eligible bullets, 02's provenance-bootstrap-report.yaml records
# eligible_bullets: 0 with an honest "no eligible claim bullets found" note.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo already-tagged-vault)
trap 'rm -rf "$TMP"' EXIT

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

REPORT="$TMP/.brownfield/provenance-bootstrap-report.yaml"
assert_file_exists "$REPORT"

# Every page in already-tagged-vault has zero eligible bullets; at least one
# page entry should report eligible_bullets: 0 AND carry the honest note.
if ! grep -qE '^[[:space:]]*eligible_bullets:[[:space:]]*0[[:space:]]*$' "$REPORT"; then
    echo "FAIL: provenance-bootstrap-report.yaml does not record eligible_bullets: 0 for any page" >&2
    cat "$REPORT" >&2
    exit 1
fi

if ! grep -q 'no eligible claim bullets found' "$REPORT"; then
    echo "FAIL: honest note 'no eligible claim bullets found' missing from report" >&2
    cat "$REPORT" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
