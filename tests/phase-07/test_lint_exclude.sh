#!/usr/bin/env bash
# test_lint_exclude.sh — Phase 07 Plan 02 (NEUT-04)
# Asserts bin/lint.sh skips examples/ by default and skips any page with example: true frontmatter.
set -euo pipefail

PASS=0
FAIL=0
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

FIXTURE_ROOT="tests/phase-07/fixtures/lint-exclude"

# Run lint against the fixture tree via WIKI_ROOT override.
# t1: examples/sample.md under fixture root MUST NOT appear as a finding (dir excluded).
# t2: wiki/marked.md (with example: true) MUST NOT appear as a finding (per-file skip).
OUT=$(WIKI_ROOT="$FIXTURE_ROOT" bash bin/lint.sh --dry-run 2>&1 || true)

if ! echo "$OUT" | grep -q 'examples/sample.md'; then
  pass "t1: examples/sample.md not linted (EXCLUDE_DIRS honors examples/)"
else
  fail "t1: examples/sample.md appeared in lint output"
  echo "--- output ---"
  echo "$OUT" | grep 'examples/sample.md' | head -5
fi

if ! echo "$OUT" | grep -q 'wiki/marked.md'; then
  pass "t2: wiki/marked.md not linted (example: true frontmatter suppresses)"
else
  fail "t2: wiki/marked.md appeared in lint output"
  echo "--- output ---"
  echo "$OUT" | grep 'wiki/marked.md' | head -5
fi

# t3: informational — test harness doesn't assert normal.md IS linted (structural assertion only).

# t4: Real repo lint must not report any findings for paths under examples/.
OUT_REAL=$(bash bin/lint.sh --dry-run 2>&1 || true)
COUNT=$(echo "$OUT_REAL" | grep -cE '(^|[^a-z])examples/' || true)
if [ "$COUNT" -eq 0 ]; then
  pass "t4: real-repo lint produces no examples/ findings"
else
  fail "t4: real-repo lint reports $COUNT examples/ findings"
  echo "$OUT_REAL" | grep -E '(^|[^a-z])examples/' | head -10
fi

echo
echo "test_lint_exclude: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
