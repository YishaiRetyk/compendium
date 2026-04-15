#!/usr/bin/env bash
# test_wiki_skeleton.sh — Phase 07 Plan 02
# Asserts wiki/ contains only index.md, log.md, and decisions/ (TMPL-05 skeleton).
set -euo pipefail

PASS=0
FAIL=0
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

UNEXPECTED=$(find wiki -mindepth 1 -maxdepth 1 ! -name 'index.md' ! -name 'log.md' ! -name 'decisions' -print)
if [ -z "$UNEXPECTED" ]; then
  pass "wiki/ top level clean (index.md, log.md, decisions/ only)"
else
  fail "UNEXPECTED in wiki/: $UNEXPECTED"
fi

# index.md skeleton — ≤ 30 lines total.
LINES=$(wc -l < wiki/index.md)
if [ "$LINES" -le 30 ]; then
  pass "wiki/index.md is skeleton ($LINES lines ≤ 30)"
else
  fail "wiki/index.md too long ($LINES lines > 30)"
fi

echo
echo "test_wiki_skeleton: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
