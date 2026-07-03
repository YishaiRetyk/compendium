#!/usr/bin/env bash
# Plan 10-02 Task 2 Test 6: .brownfield-ignore negation contract (D-19).
# Asserts:
#   - WITH `.brownfield-ignore` containing `!attachments`, attachments/diagram.md
#     appears in Inventory (negation lifted the built-in attachments/** exclude)
#   - WITHOUT `.brownfield-ignore`, attachments/diagram.md is back under the
#     default denylist and NOT in Inventory
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

tmp=$(make_fixture_repo scan-vault-basic)
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

# --- Part 1: negation lifts the exclude -------------------------------------
[ -f "$tmp/.brownfield-ignore" ] || { echo "FAIL: fixture .brownfield-ignore missing in temp copy" >&2; exit 1; }
invoke_tool_compat brownfield scan --root "$tmp" >/dev/null 2>&1
report="$tmp/.brownfield/REPORT.md"

if ! grep -E '`attachments/diagram.md`' "$report" >/dev/null; then
    echo "FAIL: with !attachments negation, attachments/diagram.md should appear in Inventory" >&2
    cat "$report" >&2
    exit 1
fi

# --- Part 2: remove ignore file, re-scan, attachments is back in Excluded ---
rm -f "$tmp/.brownfield-ignore"
rm -rf "$tmp/.brownfield"
invoke_tool_compat brownfield scan --root "$tmp" >/dev/null 2>&1
report2="$tmp/.brownfield/REPORT.md"

if grep -E '^\|\s*`attachments/diagram.md`' "$report2" >/dev/null; then
    echo "FAIL: without .brownfield-ignore, attachments/diagram.md should NOT be in Inventory" >&2
    cat "$report2" >&2
    exit 1
fi

if ! grep -q "attachments" "$report2"; then
    echo "FAIL: Excluded section does not mention attachments after removing .brownfield-ignore" >&2
    cat "$report2" >&2
    exit 1
fi

echo "PASS: .brownfield-ignore negation contract"
