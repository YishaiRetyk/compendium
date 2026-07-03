#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_verify_promote_gate5_pending.sh — D-13 gate 5:
# pages that appear in a `decision: pending` cluster of
# page-typing-decisions.yaml MUST NOT be promoted, even when gates 1-4 pass.
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

# Leave decisions.yaml in its suggest state (some/all clusters pending).
# Now pretend pages have been typed (write type: concept directly).
for p in "$TMP"/wiki/concepts/*.md; do
    sed -i 's/^type: ""$/type: concept/' "$p"
done
for p in "$TMP"/wiki/entities/*.md; do
    sed -i 's/^type: ""$/type: entity/' "$p"
done
for p in "$TMP"/wiki/overviews/*.md; do
    sed -i 's/^type: ""$/type: overview/' "$p"
done

set +e
invoke_tool_compat brownfield verify --promote --root "$TMP" >/dev/null 2>stderr.txt
ec=$?
set -e

if grep -q "not yet implemented" stderr.txt 2>/dev/null; then
    rm -f stderr.txt
    echo "FAIL: bin/brownfield.sh verify --promote not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi
rm -f stderr.txt

# If any cluster in decisions.yaml is still `pending`, then pages in that
# cluster MUST NOT be promoted — gate 5 blocks them.
DECFILE="$TMP/.brownfield/page-typing-decisions.yaml"
pending_count=$(grep -c 'decision:[[:space:]]*pending' "$DECFILE" || true)
if [ "$pending_count" = "0" ]; then
    # Nothing to verify here — suggest auto-approved everything. Pass.
    echo "PASS $NAME (no pending clusters in fixture, gate 5 skip path)"; exit 0
fi

# At least one page that lives in a pending cluster should remain
# bootstrapped (NOT verified).
unpromoted=$(grep -r -c '^bootstrap_stage: bootstrapped' "$TMP/wiki/" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
if [ "$unpromoted" -lt "1" ]; then
    echo "FAIL: all pages promoted despite pending clusters in decisions.yaml (gate 5 not enforced)" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
