#!/usr/bin/env bash
# Plan 10-03 Task 2: tabs-in-yaml fixture — input unchanged + SKIPPED.md entry.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"

FIXTURE="tabs-in-yaml"
tmp=$(make_fixture_repo "$FIXTURE")
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

snap_before=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)

invoke_tool_compat brownfield bootstrap --apply --root "$tmp/input" >/dev/null 2>&1

snap_after=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
[ "$snap_before" = "$snap_after" ] \
    || { echo "FAIL: unparseable $FIXTURE input was mutated" >&2; exit 1; }

assert_file_exists "$tmp/input/.brownfield/SKIPPED.md" "SKIPPED.md missing after skip"
# Parse-error string is library-version-dependent so assert structural match
# (header + path reference) not byte-exact match of the expected-skipped-entry.
assert_grep "## Skipped due to parse failure" "$tmp/input/.brownfield/SKIPPED.md"
assert_grep "page.md" "$tmp/input/.brownfield/SKIPPED.md"

echo "PASS: bootstrap skip $FIXTURE"
