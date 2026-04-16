#!/usr/bin/env bash
# I-4: schema/examples/ contains exactly 6 files: entity.md, concept.md, source-summary.md,
# comparison.md, overview.md, decision.md.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

D="$REPO_ROOT/schema/examples"
test -d "$D" || { echo "FAIL: $D missing" >&2; exit 1; }

for t in entity concept source-summary comparison overview decision; do
    test -f "$D/$t.md" || { echo "FAIL: $D/$t.md missing" >&2; exit 1; }
done

count="$(find "$D" -maxdepth 1 -type f -name '*.md' | wc -l)"
# Accept >=6; if planner opts in to schema/examples/README.md that is fine (PATTERNS Note 3).
[ "$count" -ge 6 ] || { echo "FAIL: expected >=6 .md files in $D, found $count" >&2; exit 1; }

echo "PASS: schema/examples/ has all 6 page-type examples"
