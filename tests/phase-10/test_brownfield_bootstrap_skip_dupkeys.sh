#!/usr/bin/env bash
# Plan 10-03 Task 2: duplicate-yaml-keys fixture — input unchanged + SKIPPED.md entry.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"

FIXTURE="duplicate-yaml-keys"
tmp=$(make_fixture_repo "$FIXTURE")
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

snap_before=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)

bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$tmp/input" >/dev/null 2>&1

snap_after=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
[ "$snap_before" = "$snap_after" ] \
    || { echo "FAIL: unparseable $FIXTURE input was mutated" >&2; exit 1; }

assert_file_exists "$tmp/input/.brownfield/SKIPPED.md" "SKIPPED.md missing after skip"
assert_grep "## Skipped due to parse failure" "$tmp/input/.brownfield/SKIPPED.md"
assert_grep "page.md" "$tmp/input/.brownfield/SKIPPED.md"
# DuplicateKeyError pre-scan emits a deterministic message; assert it appears.
assert_grep "duplicate YAML key 'type'" "$tmp/input/.brownfield/SKIPPED.md"

echo "PASS: bootstrap skip $FIXTURE"
