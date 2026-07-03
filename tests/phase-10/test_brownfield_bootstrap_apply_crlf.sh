#!/usr/bin/env bash
# Plan 10-03 Task 2: bootstrap --apply on CRLF input; output is LF-normalized.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"
export BROWNFIELD_FIXTURE_CREATED_AT="2026-04-17"

FIXTURE="crlf"
tmp=$(make_fixture_repo "$FIXTURE")
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

invoke_tool_compat brownfield bootstrap --apply --root "$tmp/input" >/dev/null 2>&1

assert_byte_equal \
    "$REPO_ROOT/tests/phase-10/fixtures/$FIXTURE/expected/page.md" \
    "$tmp/input/page.md" \
    "bootstrap --apply on $FIXTURE did not produce expected/page.md"

assert_byte_equal \
    "$REPO_ROOT/tests/phase-10/fixtures/$FIXTURE/expected/page.md" \
    "$tmp/expected/page.md" \
    "$tmp/expected/page.md was mutated — W-2 isolation violated"

# Output must be LF (no CR bytes anywhere — ruamel normalizes CRLF on write per D-03).
if grep -q $'\r' "$tmp/input/page.md"; then
    echo "FAIL: CRLF fixture output contains CR bytes (should be LF-normalized)" >&2
    exit 1
fi

# Idempotency
snap_before=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
invoke_tool_compat brownfield bootstrap --apply --root "$tmp/input" >/dev/null 2>&1
snap_after=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
[ "$snap_before" = "$snap_after" ] \
    || { echo "FAIL: re-run mutated $FIXTURE — BRWN-03 violated" >&2; exit 1; }

echo "PASS: bootstrap apply $FIXTURE"
