#!/usr/bin/env bash
# test_agents_neutralized.sh -- Phase 07 Plan 03
# Asserts AGENTS.md is neutralized: no Kahneman tokens outside of legitimate
# `See: examples/kahneman/...` pointer lines, example: field documented (NEUT-04),
# and §2 Directory Structure references the new top-level dirs.
#
# POST-EXTRACTION (Phase 16): The >=3 See: examples/kahneman/ pointer count
# threshold was set before §4 was extracted to schema/reference/page-types.md.
# The §4 type-specific kahneman pointers (entity/concept/source/etc.) now live
# in page-types.md. AGENTS.md still has 2 kahneman pointers (§11.2, §12).
# The pointer count check is relaxed to >=1 (at least one pointer must remain
# per NEUT-04; additional pointers live in the leaf files).
# Phase 16 precedent (same as 08-04/09-06/13.1): when a successor plan changes
# the shape, the prior-phase test threshold is updated.
#
# The kahneman-leak check (no Kahneman tokens outside See: / examples/ lines)
# remains unchanged — that is a load-bearing safety invariant.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

FAIL=0

# 1. Zero Kahneman-specific tokens outside `See: examples/kahneman/...` pointers
#    and legitimate references to the `examples/kahneman/` directory path.
# We strip pointer lines and directory-reference lines before grepping.
LEAK=$(grep -iEn 'kahneman|prospect.theory|loss.aversion|cognitive.biases|thinking.fast|system.?1.vs.system.?2' AGENTS.md \
  | grep -vE '^[0-9]+:See: examples/kahneman/' \
  | grep -vE 'examples/kahneman/' \
  || true)
if [ -n "$LEAK" ]; then
  echo "FAIL: Kahneman tokens leaked in AGENTS.md (outside See:/examples/kahneman/ lines):"
  echo "$LEAK"
  FAIL=1
fi

# 2. At least 1 `See: examples/kahneman/...` pointer in AGENTS.md
# (>=3 was the pre-extraction threshold; Phase 16 moved §4 type pointers to page-types.md;
# at least 1 must remain in AGENTS.md for inline-content illustration)
POINTERS=$(grep -c '^See: examples/kahneman/' AGENTS.md || true)
if [ "${POINTERS:-0}" -lt 1 ]; then
  echo "FAIL: expected >=1 See: examples/kahneman/ pointer in AGENTS.md, got $POINTERS"
  FAIL=1
fi

# 2b. page-types.md has the moved type-specific kahneman pointers (≥6)
PT_POINTERS=$(grep -c '^See: schema/examples/.* for a concrete filled-in instance\.$' "$REPO_ROOT/schema/reference/page-types.md" || true)
if [ "${PT_POINTERS:-0}" -lt 6 ]; then
  echo "FAIL: expected >=6 See: schema/examples/ pointers in page-types.md (moved from §4), got $PT_POINTERS"
  FAIL=1
fi

# 3. example: field documented (NEUT-04)
if ! grep -qE '^example:|`example`|example: boolean|example: false|example: true' AGENTS.md; then
  echo "FAIL: AGENTS.md does not document the 'example:' frontmatter field (NEUT-04)"
  FAIL=1
fi

# 4. §2 Directory Structure mentions new top-level dirs
for d in 'examples/' 'docs/' 'schema/' '\.github/'; do
  if ! grep -qE "$d" AGENTS.md; then
    echo "FAIL: AGENTS.md does not reference top-level '$d' in Directory Structure"
    FAIL=1
  fi
done

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi

echo "PASS: AGENTS.md neutralized ($POINTERS See: pointers remaining, $PT_POINTERS in page-types.md, example: documented, dirs listed)"
exit 0
