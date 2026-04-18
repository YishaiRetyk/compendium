#!/usr/bin/env bash
# Plan 10-03 Task 2: bootstrap --apply on clean-frontmatter produces byte-equal expected.
# Also asserts body preservation + idempotency + W-2 isolation.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"
export BROWNFIELD_FIXTURE_CREATED_AT="2026-04-17"

FIXTURE="clean-frontmatter"
tmp=$(make_fixture_repo "$FIXTURE")
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

# W-2 isolation: root at $tmp/input (never $tmp).
bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$tmp/input" >/dev/null 2>&1

assert_byte_equal \
    "$REPO_ROOT/tests/phase-10/fixtures/$FIXTURE/expected/page.md" \
    "$tmp/input/page.md" \
    "bootstrap --apply on $FIXTURE did not produce expected/page.md"

# W-2: expected/ must remain byte-equal (never visited).
assert_byte_equal \
    "$REPO_ROOT/tests/phase-10/fixtures/$FIXTURE/expected/page.md" \
    "$tmp/expected/page.md" \
    "$tmp/expected/page.md was mutated — W-2 isolation violated"

# Body preservation (BRWN-05): bytes after closing '---\n' must match original.
python3 - <<PYEOF
with open('$tmp/input/page.md','rb') as f: actual = f.read()
with open('$REPO_ROOT/tests/phase-10/fixtures/$FIXTURE/input/page.md','rb') as f: orig = f.read()
def body(b):
    parts = b.split(b'---\n', 2)
    return parts[2] if len(parts) == 3 else b
assert body(actual) == body(orig), 'BODY MUTATED — BRWN-05 violated'
PYEOF

# Idempotency (BRWN-03): second --apply run is a byte-equal no-op.
snap_before=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$tmp/input" >/dev/null 2>&1
snap_after=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
[ "$snap_before" = "$snap_after" ] \
    || { echo "FAIL: re-run mutated $FIXTURE — BRWN-03 violated" >&2; exit 1; }

echo "PASS: bootstrap apply $FIXTURE"
