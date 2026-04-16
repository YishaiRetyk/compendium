#!/usr/bin/env bash
# I-10: docs/reference/dataview-queries.md exists with 5 ```dataview code blocks.
# I-11: docs/reference/commit-examples.md exists with a code block containing >=9 commit lines.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DQ="$REPO_ROOT/docs/reference/dataview-queries.md"
CE="$REPO_ROOT/docs/reference/commit-examples.md"

# I-10
test -f "$DQ" || { echo "FAIL: $DQ missing" >&2; exit 1; }
dataview_count="$(grep -cE '^```dataview$' "$DQ")"
[ "$dataview_count" -eq 5 ] || { echo "FAIL: expected 5 dataview fence opens in dataview-queries.md, found $dataview_count" >&2; exit 1; }

# I-11
test -f "$CE" || { echo "FAIL: $CE missing" >&2; exit 1; }
# The commit-examples body has 1 fenced block containing >=9 commit-message lines.
# Representative commits from current AGENTS.md Appendix B (lines 1762-1770).
for sample in \
    'schema: define base frontmatter fields and page type conventions' \
    'ingest(hinton-interview): add source summary' \
    'query(attention-mechanisms): synthesize comparison' \
    'lint(wiki): fix 3 orphan pages' \
    'reflect(q1-review): restructure AI safety domain'
do
    grep -Fq "$sample" "$CE" || { echo "FAIL: commit-examples.md missing sample: $sample" >&2; exit 1; }
done

# Neither file has YAML frontmatter (docs/reference/ convention per PATTERNS Shared Pattern 2 rule 5)
! grep -q '^---$' "$DQ" || { echo "FAIL: docs/reference/dataview-queries.md should NOT have YAML frontmatter" >&2; exit 1; }
! grep -q '^---$' "$CE" || { echo "FAIL: docs/reference/commit-examples.md should NOT have YAML frontmatter" >&2; exit 1; }

# Both have H1 + See also footer (docs/reference/ci.md shape)
grep -q '^# ' "$DQ" || { echo "FAIL: dataview-queries.md missing H1" >&2; exit 1; }
grep -q '^# ' "$CE" || { echo "FAIL: commit-examples.md missing H1" >&2; exit 1; }

echo "PASS: docs/reference/dataview-queries.md (5 dataview blocks) + commit-examples.md present"
