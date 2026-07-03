#!/usr/bin/env bash
# COLAB-04 / D-20: --contributor overrides detection in both directions.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SRC_DIR="$(mktemp -d)"
echo "# test" > "$SRC_DIR/source.md"

cleanup_all() {
    rm -rf "$SRC_DIR"
    [ -n "${FIXTURE:-}" ] && cleanup_fixture_repo "$FIXTURE"
    [ -n "${FIX2:-}" ] && cleanup_fixture_repo "$FIX2"
    [ -n "${FIX3:-}" ] && cleanup_fixture_repo "$FIX3"
}
trap cleanup_all EXIT

# ---------------------------------------------------------------------------
# 1. Multi-author: explicit flag overrides map lookup
# ---------------------------------------------------------------------------
FIXTURE="$(make_fixture_repo contributor-multi)"
setup_git_author "$FIXTURE" "Alice" "alice@example.com"
setup_git_author "$FIXTURE" "Bob" "bob@example.com"
pushd "$FIXTURE" >/dev/null
git config user.email "alice@example.com"  # would map to @alice

# Override with @other
OUT="$(invoke_tool_compat ingest --contributor @other "$SRC_DIR/source.md" 2>&1 || true)"
if ! echo "$OUT" | grep -q "contributor:: @other"; then
    echo "FAIL: explicit --contributor @other should override" >&2
    echo "$OUT" >&2
    popd >/dev/null
    exit 1
fi
# Not @alice
if echo "$OUT" | grep -q "contributor:: @alice"; then
    echo "FAIL: explicit flag should win over map" >&2
    popd >/dev/null
    exit 1
fi
popd >/dev/null

# ---------------------------------------------------------------------------
# 2. Single-author: explicit flag forces emit
# ---------------------------------------------------------------------------
FIX2="$(make_fixture_repo contributor-single)"
pushd "$FIX2" >/dev/null
OUT2="$(invoke_tool_compat ingest --contributor @forced "$SRC_DIR/source.md" 2>&1 || true)"
if ! echo "$OUT2" | grep -q "contributor:: @forced"; then
    echo "FAIL: explicit --contributor should force emit on single-author" >&2
    echo "$OUT2" >&2
    popd >/dev/null
    exit 1
fi
popd >/dev/null

# ---------------------------------------------------------------------------
# 3. Bare handle accepted (no @) -> normalized to @
# ---------------------------------------------------------------------------
FIX3="$(make_fixture_repo contributor-multi)"
setup_git_author "$FIX3" "X" "x@e.com"
setup_git_author "$FIX3" "Y" "y@e.com"
pushd "$FIX3" >/dev/null
OUT3="$(invoke_tool_compat ingest --contributor bare "$SRC_DIR/source.md" 2>&1 || true)"
if ! echo "$OUT3" | grep -q "contributor:: @bare"; then
    echo "FAIL: bare handle should normalize to @bare" >&2
    echo "$OUT3" >&2
    popd >/dev/null
    exit 1
fi
popd >/dev/null

echo "PASS: --contributor overrides + bare-handle normalization"
