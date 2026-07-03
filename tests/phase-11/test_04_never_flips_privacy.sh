#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_04_never_flips_privacy.sh — BRWN-18 + D-07: 04 NEVER
# flips the privacy frontmatter field. Every fixture page is local_only
# before AND after 04 runs.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo privacy-sensitive-vault)
trap 'rm -rf "$TMP"' EXIT

# Count local_only entries before
before=$(grep -r -c '^privacy: local_only' "$TMP/wiki/" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

if ! bash "$TMP/.brownfield/migrations/04-privacy-review.sh" >/dev/null 2>&1; then
    echo "FAIL: 04-privacy-review.sh not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

after=$(grep -r -c '^privacy: local_only' "$TMP/wiki/" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')

if [ "$before" != "$after" ]; then
    echo "FAIL: 04 changed privacy field count (before=$before, after=$after)" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
