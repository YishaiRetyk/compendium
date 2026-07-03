#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_review_typing_decisions_roundtrip.sh — BRWN-22:
# ruamel.yaml round-trip invariant — comment lines in decisions.yaml are
# preserved when review-typing writes back.
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

DECFILE="$TMP/.brownfield/page-typing-decisions.yaml"
assert_file_exists "$DECFILE"

COMMENT="# human note: approved after team review"
echo "$COMMENT" >> "$DECFILE"

input_lines=""
for _ in $(seq 1 20); do input_lines+="a"$'\n'; done

if ! echo -n "$input_lines" | invoke_tool_compat brownfield review-typing --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh review-typing not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi

if ! grep -q "$COMMENT" "$DECFILE"; then
    echo "FAIL: human comment line lost on review-typing write-back (ruamel round-trip invariant broken)" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
