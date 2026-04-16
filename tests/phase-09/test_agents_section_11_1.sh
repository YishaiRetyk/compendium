#!/usr/bin/env bash
# COLAB-04 doc: AGENTS.md §11.1 documents --contributor auto-detect flow.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"

# Extract §11.1 section body (from "### 11.1" to next "### 11.")
SECTION="$(awk '/^### 11\.1/,/^### 11\.[0-9]/' "$A" | head -n -1)"
echo "$SECTION" | grep -q -- "--contributor" \
    || { echo "FAIL: §11.1 missing --contributor documentation" >&2; exit 1; }
echo "$SECTION" | grep -q "\.git-author-map\.txt" \
    || { echo "FAIL: §11.1 missing .git-author-map.txt reference" >&2; exit 1; }
echo "$SECTION" | grep -qi "single.author" \
    || { echo "FAIL: §11.1 missing single-author detection note" >&2; exit 1; }
echo "$SECTION" | grep -q "contributor::" \
    || { echo "FAIL: §11.1 missing contributor:: field name" >&2; exit 1; }
echo "$SECTION" | grep -qi "never.*bare.*email\|never.*email.*bare\|NEVER.*bare" \
    || { echo "FAIL: §11.1 missing 'never bare email' rule" >&2; exit 1; }

echo "PASS: AGENTS.md §11.1 documents --contributor flow"
