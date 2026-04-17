#!/usr/bin/env bash
# Plan 10-03 Task 2: bootstrap --apply preserves YAML comments via ruamel round-trip (BRWN-06).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"

FIXTURE="frontmatter-with-comments"
tmp=$(make_fixture_repo "$FIXTURE")
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$tmp/input" >/dev/null 2>&1

assert_byte_equal \
    "$REPO_ROOT/tests/phase-10/fixtures/$FIXTURE/expected/page.md" \
    "$tmp/input/page.md" \
    "bootstrap --apply on $FIXTURE did not produce expected/page.md"

assert_byte_equal \
    "$REPO_ROOT/tests/phase-10/fixtures/$FIXTURE/expected/page.md" \
    "$tmp/expected/page.md" \
    "$tmp/expected/page.md was mutated — W-2 isolation violated"

# Both YAML comments from the input survived.
grep -qF "# Set by user 2025-12-01" "$tmp/input/page.md" \
    || { echo "FAIL: YAML comment '# Set by user ...' dropped by round-trip (BRWN-06 violated)" >&2; exit 1; }
grep -qF "# Last reviewed: 2025-12-15" "$tmp/input/page.md" \
    || { echo "FAIL: YAML comment '# Last reviewed ...' dropped by round-trip (BRWN-06 violated)" >&2; exit 1; }

# Idempotency
snap_before=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$tmp/input" >/dev/null 2>&1
snap_after=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
[ "$snap_before" = "$snap_after" ] \
    || { echo "FAIL: re-run mutated $FIXTURE — BRWN-03 violated" >&2; exit 1; }

echo "PASS: bootstrap apply $FIXTURE"
