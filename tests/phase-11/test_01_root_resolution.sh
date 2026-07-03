#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_01_root_resolution.sh — REVIEWS item 1 (HIGH):
# 01-page-typing.sh MUST derive vault root from its own script location
# (parent of .brownfield/), NOT from $(pwd). Test invokes the script from
# a DIFFERENT vault's cwd and asserts the other vault is untouched.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP_A=$(make_fixture_repo small-vault-ambiguous)
TMP_B=$(make_fixture_repo small-vault-ambiguous)
trap 'rm -rf "$TMP_A" "$TMP_B"' EXIT

# Capture B's state before the test
cp -a "$TMP_B" "$TMP_B.snapshot"

# Suggest into A only
if ! invoke_tool_compat brownfield suggest --root "$TMP_A" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    rm -rf "$TMP_B.snapshot"
    exit 1
fi

# Approve all in A
DECFILE="$TMP_A/.brownfield/page-typing-decisions.yaml"
sed -i 's/^\([[:space:]]*\)decision:[[:space:]]*pending/\1decision: approve/g' "$DECFILE"

# Invoke A's migration script with cwd=B using its absolute path
if ! (cd "$TMP_B" && bash "$TMP_A/.brownfield/migrations/01-page-typing.sh" --apply) >/dev/null 2>&1; then
    echo "FAIL: 01-page-typing.sh --apply from TMP_B cwd failed — Plan 11-03 pending" >&2
    rm -rf "$TMP_B.snapshot"
    exit 1
fi

# TMP_B MUST be byte-identical to its snapshot — script must resolve root
# from its own location, NOT $(pwd).
if ! diff -rq "$TMP_B" "$TMP_B.snapshot" >/dev/null; then
    echo "FAIL: TMP_B was mutated when A's script ran with B as cwd" >&2
    diff -rq "$TMP_B" "$TMP_B.snapshot" | head -20 >&2
    rm -rf "$TMP_B.snapshot"
    exit 1
fi

rm -rf "$TMP_B.snapshot"
echo "PASS $NAME"; exit 0
