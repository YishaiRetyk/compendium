#!/usr/bin/env bash
# test_no_stale_kahneman_paths.sh — Phase 07 Plan 02 (REVIEWS.md HIGH #4)
# Repo-wide scan asserting NO public file references the old wiki/.../kahneman/... paths.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

# Candidate public surfaces; guard each with existence check.
TARGETS=()
for t in README.md AGENTS.md CLAUDE.md PRIVACY.md docs .github bin wiki/index.md wiki/log.md; do
  if [ -e "$t" ]; then TARGETS+=("$t"); fi
done

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "PASS: no public surfaces present to scan"
  exit 0
fi

PATTERN='wiki/(entities|concepts|comparisons|overviews|sources)/(daniel-kahneman|prospect-theory|loss-aversion|cognitive-biases|system-1-vs-system-2|decision-making|thinking-fast|src-2026-04-09-thinking-fast-and-slow-part1|src-2026-04-10-kahneman-prospect-theory)'

HITS=$(grep -rIn -E "$PATTERN" \
  --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' \
  --exclude-dir=examples --exclude-dir=.planning --exclude-dir=.git --exclude-dir=node_modules \
  "${TARGETS[@]}" 2>/dev/null || true)

if [ -n "$HITS" ]; then
  echo "FAIL: STALE wiki/.../kahneman/... path references found:"
  echo "$HITS"
  exit 1
fi

echo "PASS: No stale Kahneman path references in public surfaces."
exit 0
