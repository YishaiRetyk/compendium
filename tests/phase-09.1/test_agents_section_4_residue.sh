#!/usr/bin/env bash
# I-6 (POST-EXTRACTION): AGENTS.md §4 is now a bare pointer stub (Phase 16).
# The six type names remain as dispatch vocabulary; the worked-example See: pointers
# and subsection bodies have moved to schema/reference/page-types.md.
#
# Phase 08-04 / 09-06 / 13.1 precedent: when a successor plan changes the shape,
# the prior-phase tests are relaxed to assert the NEW invariant.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"
PT="$REPO_ROOT/schema/reference/page-types.md"

# ASSERTION 1: §4 contains the six type names (dispatch vocabulary)
for t in entity concept source comparison overview decision; do
    grep -qi "$t" "$A" \
        || { echo "FAIL: §4 missing type name '$t' in AGENTS.md" >&2; exit 1; }
done

# ASSERTION 2: §4 contains the routing pointer to page-types.md
grep -q 'schema/reference/page-types.md' "$A" \
    || { echo "FAIL: §4 stub missing 'schema/reference/page-types.md' routing pointer in AGENTS.md" >&2; exit 1; }

# ASSERTION 3: page-types.md exists (§4 body moved there)
test -f "$PT" \
    || { echo "FAIL: schema/reference/page-types.md missing (§4 body should live here)" >&2; exit 1; }

# ASSERTION 4: The six worked-example See: pointers now live in page-types.md (not AGENTS.md)
count="$(grep -cE '^See: schema/examples/(entity|concept|source-summary|comparison|overview|decision)\.md for a concrete filled-in instance\.$' "$PT" || true)"
[ "$count" -eq 6 ] \
    || { echo "FAIL: expected 6 See: schema/examples/ pointers in page-types.md, found $count" >&2; exit 1; }

# ASSERTION 5: The See: pointers are NOT in AGENTS.md (they moved to page-types.md)
count_in_agents="$(grep -cE '^See: schema/examples/(entity|concept|source-summary|comparison|overview|decision)\.md' "$A" || true)"
[ "$count_in_agents" -eq 0 ] \
    || { echo "FAIL: §4 example pointers still in AGENTS.md (should be in page-types.md only); found $count_in_agents" >&2; exit 1; }

# ASSERTION 6: Anti-patterns — no **See:** bold or markdown-link forms in page-types.md
! grep -qE '^\s*-?\s*\*\*See:\*\*' "$PT" \
    || { echo "FAIL: found **See:** (bold) in page-types.md — D-09 violation" >&2; exit 1; }
! grep -qE 'See: \[schema/examples/' "$PT" \
    || { echo "FAIL: found markdown-link See pointer in page-types.md — D-09 violation" >&2; exit 1; }

# ASSERTION 7: Former §4 worked-example content ABSENT from AGENTS.md
for old in \
    "British-Canadian computer scientist, pioneer of deep learning" \
    "A neural network component that allows models to focus" \
    "Seminal paper introducing the Transformer architecture based entirely on attention" \
    "Comparison of recurrent neural networks and Transformer architectures" \
    "High-level overview of deep learning: history, key architectures"
do
    if grep -Fq "$old" "$A"; then
        echo "FAIL: AGENTS.md still contains former §4 worked-example content: '$old'" >&2
        exit 1
    fi
done

# ASSERTION 8: §4 preamble has 'Six page types' (R8 polish preserved)
grep -F -q 'Six page types' "$A" \
    || { echo "FAIL: §4 preamble must read 'Six page types' (R8 polish); found outdated or missing" >&2; exit 1; }
! grep -F -q 'Five page types exist.' "$A" \
    || { echo "FAIL: §4 preamble still has outdated 'Five page types exist.' — R8 polish not applied" >&2; exit 1; }

echo "PASS: AGENTS.md §4 is a correct post-extraction stub; §4 body (incl. 6 See: pointers) in page-types.md"
