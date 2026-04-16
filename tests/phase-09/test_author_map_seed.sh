#!/usr/bin/env bash
# Verify .git-author-map.txt committed at repo root with expected header.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

MAP="$REPO_ROOT/.git-author-map.txt"
test -f "$MAP" || { echo "FAIL: .git-author-map.txt missing at repo root" >&2; exit 1; }
# Must be tracked by git (not gitignored)
(cd "$REPO_ROOT" && git ls-files --error-unmatch .git-author-map.txt >/dev/null 2>&1) \
    || { echo "FAIL: .git-author-map.txt is not tracked by git" >&2; exit 1; }
# Header documents format
grep -q "email" "$MAP" || { echo "FAIL: header missing 'email' keyword" >&2; exit 1; }
grep -q "@" "$MAP" || { echo "FAIL: header missing '@' in format example" >&2; exit 1; }
grep -q "^#" "$MAP" || { echo "FAIL: no '#' comment lines (header missing)" >&2; exit 1; }
echo "PASS: .git-author-map.txt seeded with header"
