#!/usr/bin/env bash
# COLAB-03: AGENTS.md §12 documents contributor:: @handle inline body field.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"
SECTION="$(awk '/^## 12\./,/^## 13\./' "$A" | head -n -1)"

echo "$SECTION" | grep -q "contributor::" \
    || { echo "FAIL: §12 missing contributor:: field" >&2; exit 1; }
echo "$SECTION" | grep -qi "@github-handle\|@handle\|github handle" \
    || { echo "FAIL: §12 missing @handle format doc" >&2; exit 1; }
echo "$SECTION" | grep -qi "inline body\|body field\|Dataview inline" \
    || { echo "FAIL: §12 missing 'inline body field' distinction (not frontmatter)" >&2; exit 1; }
echo "$SECTION" | grep -qi "source of truth\|authoritative" \
    || { echo "FAIL: §12 missing git-authorship-source-of-truth statement" >&2; exit 1; }
echo "$SECTION" | grep -qi "single.author.*omit\|omit.*single.author" \
    || { echo "FAIL: §12 missing single-author omission rule" >&2; exit 1; }
echo "$SECTION" | grep -q "\.git-author-map\.txt" \
    || { echo "FAIL: §12 missing .git-author-map.txt reference" >&2; exit 1; }

# CLAUDE.md byte-equality still holds
(cd "$REPO_ROOT" && bash bin/sync-claude.sh --check) \
    || { echo "FAIL: CLAUDE.md drifted from AGENTS.md after amendments" >&2; exit 1; }

echo "PASS: AGENTS.md §12 + CLAUDE.md sync"
