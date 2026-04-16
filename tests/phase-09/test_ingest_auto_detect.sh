#!/usr/bin/env bash
# COLAB-04: multi-author + git config email in map -> auto-detect @handle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo contributor-multi)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# Seed 2 authors so git log has > 1 unique email
setup_git_author "$FIXTURE" "Alice" "alice@example.com"
setup_git_author "$FIXTURE" "Bob" "bob@example.com"

pushd "$FIXTURE" >/dev/null
git config user.email "alice@example.com"

SRC_DIR="$(mktemp -d)"
echo "# test" > "$SRC_DIR/source.md"

OUT="$(bash "$REPO_ROOT/bin/ingest.sh" "$SRC_DIR/source.md" 2>&1 || true)"

if ! echo "$OUT" | grep -q "contributor:: @alice"; then
    echo "FAIL: expected 'contributor:: @alice', got:" >&2
    echo "$OUT" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR"
    exit 1
fi

popd >/dev/null
rm -rf "$SRC_DIR"
echo "PASS: auto-detect via .git-author-map.txt hit"
