#!/usr/bin/env bash
# COLAB-04 / D-20: single-author repo auto-omits contributor:: field.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo contributor-single)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Create a fake source file
SRC_DIR="$(mktemp -d)"
echo "# test source" > "$SRC_DIR/source.md"

OUT="$(invoke_tool_compat ingest "$SRC_DIR/source.md" 2>&1 || true)"

# Must NOT contain contributor::
if echo "$OUT" | grep -q "contributor::"; then
    echo "FAIL: single-author repo should omit contributor::" >&2
    echo "$OUT" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR"
    exit 1
fi
# Pitfall 5 guard: no bare email
if echo "$OUT" | grep -qE "contributor:: [^@]"; then
    echo "FAIL: bare email leaked into contributor:: field (D-21 Pitfall 5)" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR"
    exit 1
fi

popd >/dev/null
rm -rf "$SRC_DIR"
echo "PASS: single-author omits contributor::"
