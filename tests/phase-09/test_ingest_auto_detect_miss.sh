#!/usr/bin/env bash
# COLAB-04 / D-21 / Pitfall 5: map miss -> warn + omit (never bare email).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo contributor-multi)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

setup_git_author "$FIXTURE" "Alice" "alice@example.com"
setup_git_author "$FIXTURE" "Bob" "bob@example.com"

pushd "$FIXTURE" >/dev/null
# Charlie is NOT in the map
git config user.email "charlie@example.com"
setup_git_author "$FIXTURE" "Charlie" "charlie@example.com"
# Reset current email to charlie again (setup_git_author may have left a different one)
git config user.email "charlie@example.com"

SRC_DIR="$(mktemp -d)"
echo "# test" > "$SRC_DIR/source.md"

ING_ERR="$(mktemp)"
OUT="$(bash "$REPO_ROOT/bin/ingest.sh" "$SRC_DIR/source.md" 2>"$ING_ERR" || true)"

# No contributor:: line
if echo "$OUT" | grep -q "contributor::"; then
    echo "FAIL: map miss should omit contributor::" >&2
    echo "$OUT" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR" "$ING_ERR"
    exit 1
fi
# Pitfall 5: no bare email anywhere in stdout
if echo "$OUT" | grep -qE "contributor:: [^@]"; then
    echo "FAIL: bare email leaked (Pitfall 5)" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR" "$ING_ERR"
    exit 1
fi
# And no contributor:: email in stderr
if grep -q "contributor:: charlie@example.com" "$ING_ERR"; then
    echo "FAIL: email leaked to stderr as contributor::" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR" "$ING_ERR"
    exit 1
fi
# stderr must contain 3 actionable tokens
if ! grep -q "charlie@example.com" "$ING_ERR"; then
    echo "FAIL: stderr missing email" >&2
    cat "$ING_ERR" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR" "$ING_ERR"
    exit 1
fi
if ! grep -q -- "--contributor" "$ING_ERR"; then
    echo "FAIL: stderr missing --contributor suggestion" >&2
    cat "$ING_ERR" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR" "$ING_ERR"
    exit 1
fi
if ! grep -q "\.git-author-map.txt" "$ING_ERR"; then
    echo "FAIL: stderr missing .git-author-map.txt suggestion" >&2
    cat "$ING_ERR" >&2
    popd >/dev/null
    rm -rf "$SRC_DIR" "$ING_ERR"
    exit 1
fi

popd >/dev/null
rm -rf "$SRC_DIR" "$ING_ERR"
echo "PASS: map miss -> warn + omit (no bare email)"
