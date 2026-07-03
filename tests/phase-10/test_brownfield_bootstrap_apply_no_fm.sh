#!/usr/bin/env bash
# Plan 10-03 Task 2: bootstrap --apply on no-frontmatter fixture (D-14 full sentinel set).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"
export BROWNFIELD_FIXTURE_CREATED_AT="2026-04-17"

FIXTURE="no-frontmatter"
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

# Body preservation for no-frontmatter: the input has no frontmatter, so the
# whole input IS the body.  After bootstrap the file has frontmatter
# prepended; the post-frontmatter slice must byte-equal the original input.
python3 - <<PYEOF
with open('$tmp/input/page.md','rb') as f: actual = f.read()
with open('$REPO_ROOT/tests/phase-10/fixtures/$FIXTURE/input/page.md','rb') as f: orig = f.read()
parts = actual.split(b'---\n', 2)
assert len(parts) == 3, 'expected 3 parts (before, yaml, body) in bootstrapped file'
post_fm = parts[2]
# post_fm has one leading newline per write_roundtrip's blank-line convention;
# strip it to compare to the original no-frontmatter body.
if post_fm.startswith(b'\n'):
    post_fm = post_fm[1:]
assert post_fm == orig, 'BODY MUTATED — BRWN-05 violated'
PYEOF

snap_before=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
invoke_tool_compat brownfield bootstrap --apply --root "$tmp/input" >/dev/null 2>&1
snap_after=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
[ "$snap_before" = "$snap_after" ] \
    || { echo "FAIL: re-run mutated $FIXTURE — BRWN-03 violated" >&2; exit 1; }

echo "PASS: bootstrap apply $FIXTURE"
