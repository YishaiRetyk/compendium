#!/usr/bin/env bash
# Plan 10-02 Task 2 Test 3: default exclusion contract (D-19).
# Without a .brownfield-ignore override, `attachments/diagram.md` must be
# excluded via the built-in attachments/** denylist and NOT appear in
# Inventory.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

tmp=$(make_fixture_repo scan-vault-basic)
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

# Remove the fixture's .brownfield-ignore so defaults apply.
rm -f "$tmp/.brownfield-ignore"

invoke_tool_compat brownfield scan --root "$tmp" >/dev/null 2>&1
report="$tmp/.brownfield/REPORT.md"
assert_file_exists "$report" "REPORT.md was not written"

# Inventory should not contain attachments/diagram.md without the override.
if grep -E '^\|\s*`attachments/diagram.md`' "$report"; then
    echo "FAIL: attachments/diagram.md appears in Inventory without user override" >&2
    cat "$report" >&2
    exit 1
fi

# The Excluded section MUST mention attachments — either via the default
# denylist rule line or a per-file count.
if ! grep -q "attachments" "$report"; then
    echo "FAIL: Excluded section does not mention attachments" >&2
    cat "$report" >&2
    exit 1
fi

echo "PASS: default exclusion of attachments/**"
