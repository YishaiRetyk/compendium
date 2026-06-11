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

( cd "$TMP" && bash "$REPO_ROOT/bin/ingest.sh" \
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

echo "PASS: test_ingest_asset_flag.sh"
