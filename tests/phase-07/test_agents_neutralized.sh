#!/usr/bin/env bash
# test_agents_neutralized.sh -- Phase 07 Plan 03
# Asserts AGENTS.md is neutralized: no Kahneman tokens outside of legitimate
# `See: examples/kahneman/...` pointer lines, >=3 section-end pointers exist,
# example: field documented (NEUT-04), and §2 Directory Structure references
# the new top-level dirs.
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

# 2. At least 3 `See: examples/kahneman/...` pointers at illustrative section ends
POINTERS=$(grep -c '^See: examples/kahneman/' AGENTS.md || true)
if [ "${POINTERS:-0}" -lt 3 ]; then
  echo "FAIL: expected >=3 See: examples/kahneman/ pointers in AGENTS.md, got $POINTERS"
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

echo "PASS: AGENTS.md neutralized ($POINTERS See: pointers, example: documented, dirs listed)"
exit 0
