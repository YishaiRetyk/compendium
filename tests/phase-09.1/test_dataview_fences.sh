#!/usr/bin/env bash
# R2: docs/reference/dataview-queries.md uses DIRECT ```dataview fences.
# The AGENTS.md §16 Appendix A wraps each inner ```dataview``` block in an outer ```markdown
# fence (illustrative inline-markdown-showing-how-obsidian-renders-a-dataview-page). That outer
# wrapper is WRONG in a standalone cookbook — it turns copy-pasteable queries into
# markdown-escaped examples. Cookbook must emit inner fences only.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DQ="$REPO_ROOT/docs/reference/dataview-queries.md"
test -f "$DQ" || { echo "FAIL: $DQ missing (expected after Wave 1 extraction)" >&2; exit 1; }

# Positive: 5 inner ```dataview``` fence opens at column 0
dataview_opens="$(grep -cE '^```dataview$' "$DQ")"
[ "$dataview_opens" -eq 5 ] \
    || { echo "FAIL: expected 5 '```dataview' fence opens in $DQ, found $dataview_opens" >&2; exit 1; }

# Negative: ZERO outer ```markdown fences. These are appropriate inside AGENTS.md (illustrative)
# but forbidden in the standalone cookbook.
markdown_opens="$(grep -cE '^```markdown$' "$DQ")"
[ "$markdown_opens" -eq 0 ] \
    || { echo "FAIL: found $markdown_opens outer '```markdown' fence(s) in $DQ; standalone cookbook must strip the AGENTS.md §16 Appendix A outer wrapper (R2 review consensus)" >&2; exit 1; }

echo "PASS: docs/reference/dataview-queries.md uses direct \`\`\`dataview\`\`\` fences (no outer markdown wrappers)"
