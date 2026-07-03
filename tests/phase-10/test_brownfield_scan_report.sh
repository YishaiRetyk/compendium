#!/usr/bin/env bash
# Plan 10-02 Task 2 Test 2: REPORT.md shape + no-vault-mutation contract (T-10-02-01).
# Asserts:
#   - `scan --root <tmp>` writes .brownfield/REPORT.md
#   - REPORT.md has all three scan sections (Inventory, Excluded, Needs human judgment)
#   - Inventory table includes wiki/entities/SomeEntity.md (brownfield fixture has old wiki/ layout)
#   - .obsidian/workspace.json NOT in Inventory
#   - non-.brownfield fixture files are UNCHANGED (SHA-256 before/after)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

tmp=$(make_fixture_repo scan-vault-basic)
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

# Snapshot SHA-256 of every non-.brownfield file BEFORE scan.
pre_snapshot=$(cd "$tmp" && find . -type f ! -path './.brownfield/*' -exec sha256sum {} + | sort)

# Run scan.
invoke_tool_compat brownfield scan --root "$tmp" >/dev/null 2>&1

report="$tmp/.brownfield/REPORT.md"
assert_file_exists "$report" "REPORT.md was not written"
assert_grep "## Inventory" "$report" "REPORT.md missing Inventory section"
assert_grep "## Excluded" "$report" "REPORT.md missing Excluded section"
assert_grep "## Needs human judgment" "$report" "REPORT.md missing 'Needs human judgment' section"
assert_grep "wiki/entities/SomeEntity.md" "$report" "REPORT.md Inventory missing SomeEntity row"

# .obsidian/workspace.json must NOT appear in Inventory.
if grep -q "workspace.json" "$report"; then
    echo "FAIL: .obsidian/workspace.json appears in REPORT.md (should be excluded)" >&2
    exit 1
fi

# Snapshot AFTER scan; only .brownfield/ should differ.
post_snapshot=$(cd "$tmp" && find . -type f ! -path './.brownfield/*' -exec sha256sum {} + | sort)
if [ "$pre_snapshot" != "$post_snapshot" ]; then
    echo "FAIL: scan mutated non-.brownfield files (T-10-02-01 threat)" >&2
    echo "--- pre ---" >&2; echo "$pre_snapshot" >&2
    echo "--- post ---" >&2; echo "$post_snapshot" >&2
    exit 1
fi

echo "PASS: scan report structure + no-mutation contract"
