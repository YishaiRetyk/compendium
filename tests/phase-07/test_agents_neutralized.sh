#!/usr/bin/env bash
# test_agents_neutralized.sh -- Phase 07 Plan 03
# Asserts AGENTS.md is neutralized: no Kahneman tokens outside of legitimate
# `See: examples/kahneman/...` pointer lines, example: field documented (NEUT-04),
# and §2 Directory Structure references the new top-level dirs.
#
# POST-EXTRACTION (Phase 16 -> 17): the type-specific `See: examples/kahneman/` pointers were
# EXTRACTED out of AGENTS.md — §4 to schema/reference/page-types.md (Phase 16), then the §11.2/§12
# pointers to the workflow/reference leaf files (Phase 17). AGENTS.md is now a pure ROUTER with
# ZERO inline `See:` pointers; it references the cluster only in its §2 Directory Structure. The
# pointer-COUNT invariant now lives on page-types.md (>=6, checked at 2b). Precedent
# (08-04/09-06/16): when a successor plan changes the shape, the prior-phase threshold is updated.
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

# 2. AGENTS.md still REFERENCES the examples/kahneman/ cluster. Post-extraction the router
# carries that reference in §2 Directory Structure rather than inline `See:` pointers (which
# fully moved to the leaf files); the pointer COUNT invariant is enforced on page-types.md at 2b.
POINTERS=$(grep -c '^See: examples/kahneman/' AGENTS.md || true)
if ! grep -qE 'examples/kahneman/' AGENTS.md; then
  echo "FAIL: AGENTS.md no longer references the examples/kahneman/ cluster at all (neutralization pointer lost)"
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
