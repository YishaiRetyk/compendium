#!/usr/bin/env bash
# tests/phase-20/test_ingest_asset_flag.sh -- PDF-04 --asset co-location (no model call).
#
# Runs bin/ingest.sh --asset against fixture files in an isolated temp cwd and
# asserts BOTH source.md and the original asset land in the same dated bundle dir.
#
# ISOLATION: ingest.sh writes under sources/ RELATIVE to cwd (DEST_DIR=
# "sources/${YEAR}/..." is cwd-relative), so running it from a temp cwd keeps the
# real repo tree untouched. An explicit --contributor is REQUIRED: without it,
# resolve_contributor runs `git log --all ... | wc -l` in a command substitution
# that fails under `set -euo pipefail` in a non-git temp cwd and aborts the
# script. An explicit value short-circuits the git-based resolution.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

printf '# x\n' > "$TMP/extracted.md"
printf '%%PDF-1.4 fake\n' > "$TMP/original.pdf"

( cd "$TMP" && invoke_tool_compat ingest \
    --slug asset-test \
    --contributor @phase20-test \
    --asset "$TMP/original.pdf" \
    "$TMP/extracted.md" ) >/dev/null 2>&1

# Locate the created bundle dir (newest dir under the temp sources tree).
BUNDLE=$(find "$TMP/sources" -type d -name '*-asset-test' | head -1)
if [ -z "$BUNDLE" ]; then
    echo "FAIL: no bundle directory created under $TMP/sources" >&2
    exit 1
fi

if [ ! -f "$BUNDLE/source.md" ]; then
    echo "FAIL: source.md not found in bundle dir $BUNDLE" >&2
    exit 1
fi

if [ ! -f "$BUNDLE/original.pdf" ]; then
    echo "FAIL: co-located asset original.pdf not found in bundle dir $BUNDLE" >&2
    exit 1
fi

# CR-01 regression: a non-Markdown source lands at source.<ext>, so an --asset
# whose basename collides with that resolved destination (here source.pdf vs a
# .pdf source) MUST be rejected before any copy -- otherwise the asset silently
# overwrites the just-copied source (data loss). Assert a non-zero exit AND that
# the source content survives.
TMP2=$(mktemp -d); trap 'rm -rf "$TMP" "$TMP2"' EXIT
printf '%%PDF-1.4 SOURCE-CONTENT\n' > "$TMP2/mydoc.pdf"
printf '%%PDF-1.4 ASSET-CONTENT\n'  > "$TMP2/source.pdf"

set +e
COLLIDE_OUT=$( cd "$TMP2" && invoke_tool_compat ingest \
    --slug collide-test \
    --contributor @phase20-test \
    --asset "$TMP2/source.pdf" \
    "$TMP2/mydoc.pdf" 2>&1 )
COLLIDE_RC=$?
set -e

if [ "$COLLIDE_RC" -eq 0 ]; then
    echo "FAIL: --asset basename colliding with source destination should error, but exit was 0" >&2
    echo "  output: $COLLIDE_OUT" >&2
    exit 1
fi

# The source destination must NOT have been written with the asset's bytes.
# Guard the find against set -e/pipefail: the collision should abort before
# sources/ is created, so find on a missing tree returns non-zero -- expected.
COLLIDE_BUNDLE=$( { find "$TMP2/sources" -type d -name '*-collide-test' 2>/dev/null || true; } | head -1)
if [ -n "$COLLIDE_BUNDLE" ] && grep -q 'ASSET-CONTENT' "$COLLIDE_BUNDLE/source.pdf" 2>/dev/null; then
    echo "FAIL: collision corrupted the source -- source.pdf holds ASSET-CONTENT (data loss)" >&2
    exit 1
fi

echo "PASS: test_ingest_asset_flag.sh"
