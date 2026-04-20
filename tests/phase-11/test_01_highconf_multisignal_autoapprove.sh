#!/usr/bin/env bash
# EXPECTED_BY: 11-02
# tests/phase-11/test_01_highconf_multisignal_autoapprove.sh — REVIEWS
# item 7 + D-03: clusters with confidence=high AND 3+ non-frontmatter
# signals agreeing auto-approve in decisions.yaml; clusters with only
# confidence=medium stay pending.
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

DECFILE="$TMP/.brownfield/page-typing-decisions.yaml"
assert_file_exists "$DECFILE"

# Assert at least one cluster is decision: approve (the high-confidence
# multi-signal auto-approve path exercised by D-03 widening in REVIEWS #7)
approved=$(grep -cE 'decision:[[:space:]]*approve' "$DECFILE" || true)
if [ "$approved" -lt "1" ]; then
    echo "FAIL: no auto-approved clusters in decisions.yaml (expected ≥1 from multi-signal agreement)" >&2
    cat "$DECFILE" >&2
    exit 1
fi

# Assert at least one cluster stays pending (ambiguous cases)
pending=$(grep -cE 'decision:[[:space:]]*pending' "$DECFILE" || true)
if [ "$pending" -lt "1" ]; then
    echo "FAIL: no pending clusters (all auto-approved — over-approval would defeat review path)" >&2
    cat "$DECFILE" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
