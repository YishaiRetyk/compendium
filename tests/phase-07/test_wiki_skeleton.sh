#!/usr/bin/env bash
# test_wiki_skeleton.sh — Phase 07 Plan 02
# Asserts wiki-cloud/ contains only index.md, log.md, and decisions/ (TMPL-05 skeleton).
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
  pass "wiki-cloud/ top level clean (index.md, log.md, decisions/ only)"
else
  fail "UNEXPECTED in wiki-cloud/: $UNEXPECTED"
fi

# index.md skeleton — ≤ 40 lines total (raised from 30 in Phase 11 to
# accommodate natural growth of the ## Decisions section; Phase 7 baseline
# was 3 DRs + skeleton prose, Phase 9.1 added 1, Phase 11 added 1).
LINES=$(wc -l < wiki-cloud/index.md)
if [ "$LINES" -le 40 ]; then
  pass "wiki-cloud/index.md is skeleton ($LINES lines ≤ 40)"
else
  fail "wiki-cloud/index.md too long ($LINES lines > 40)"
fi

echo
echo "test_wiki_skeleton: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
