#!/usr/bin/env bash
# PRIV-07: After migration, CLAUDE.md §13 body is reduced to a one-line structural
# pointer. Asserts: section is SHORT (< 15 lines between ## 13 and ## 14);
# contains a pointer phrase; does NOT contain 'fail-closed' / 'Three-Level' / 'inheritance'.
# Today this FAILS (§13 is ~44 lines with full machinery).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
test -f "$CLAUDE_MD" || { echo "FAIL: CLAUDE.md missing" >&2; exit 1; }

FAIL=0

# Count lines in §13 (between '## 13.' and '## 14.')
python3 - "$CLAUDE_MD" <<'PYEOF'
import sys, pathlib, re

text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')

# Extract §13 body (from "## 13" heading to "## 14" heading)
m = re.search(r'^(## 13\..*?$)(.*?)(?=^## 14\.)', text, flags=re.DOTALL | re.MULTILINE)
if not m:
    sys.exit("FAIL: Could not extract §13 section from CLAUDE.md (## 13. heading not found or ## 14. boundary missing)")

section_body = m.group(2)
lines = section_body.splitlines()
line_count = len([l for l in lines if l.strip()])  # count non-blank lines

if line_count >= 15:
    sys.exit(f"FAIL: §13 has {line_count} non-blank lines (>= 15); must be reduced to a one-line pointer (PRIV-07)")

print(f"OK: §13 has {line_count} non-blank lines (< 15)")
PYEOF
rc=$?
if [ "$rc" -ne 0 ]; then
    FAIL=1
fi

# §13 must contain a pointer phrase to the reference doc
if ! grep -qiE 'schema/reference/privacy|see.*privacy' "$CLAUDE_MD" 2>/dev/null; then
    echo "FAIL: CLAUDE.md §13 does not contain a pointer phrase (e.g. 'schema/reference/privacy' or 'See...privacy') (PRIV-07)" >&2
    FAIL=1
fi

# §13 must NOT contain 'fail-closed' prose (full machinery removed)
if grep -q 'fail-closed' "$CLAUDE_MD" 2>/dev/null; then
    echo "FAIL: CLAUDE.md still contains 'fail-closed' (full §13 machinery not removed) (PRIV-07)" >&2
    FAIL=1
fi

# §13 must NOT contain 'Three-Level' prose
if grep -q 'Three-Level' "$CLAUDE_MD" 2>/dev/null; then
    echo "FAIL: CLAUDE.md still contains 'Three-Level' (§13 not reduced to pointer) (PRIV-07)" >&2
    FAIL=1
fi

# §13 must NOT contain 'inheritance' (per-page privacy inheritance prose removed)
if grep -q 'inheritance' "$CLAUDE_MD" 2>/dev/null; then
    echo "FAIL: CLAUDE.md still contains 'inheritance' (§13 privacy inheritance prose not removed) (PRIV-07)" >&2
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: CLAUDE.md §13 is a short pointer; no fail-closed/Three-Level/inheritance machinery"
