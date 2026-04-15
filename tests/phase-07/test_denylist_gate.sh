#!/usr/bin/env bash
# test_denylist_gate.sh -- Phase 07 Plan 05 (NEUT-08).
# Asserts: personal leak detected (N3), JSON output (N7).
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

FIX_DIR="tests/phase-07/fixtures/neutrality"
SCRIPT="bin/check-neutrality.sh"

PASS=0
FAIL=0
report() {
  if [ "$2" -eq 0 ]; then echo "PASS $1"; PASS=$((PASS+1));
  else echo "FAIL $1"; FAIL=$((FAIL+1)); fi
}

# N3: personal leak in docs/reference/ci.md -> exit 2
set +e
OUT=$(bash "$SCRIPT" --root "$FIX_DIR/leak-personal" --denylist "$FIX_DIR/leak-personal/denylist.txt" 2>&1)
RC=$?
set -e
if [ "$RC" -eq 2 ] && echo "$OUT" | grep -q 'personal-term-xyz'; then
  report N3_leak_personal 0
else
  report N3_leak_personal 1
fi

# N7: JSON format
set +e
JSON=$(bash "$SCRIPT" --format json --root "$FIX_DIR/leak-kahneman" --denylist "$FIX_DIR/leak-kahneman/denylist.txt" 2>/dev/null)
set -e
if echo "$JSON" | python3 -c 'import json,sys; a=json.load(sys.stdin); assert isinstance(a,list); assert len(a)>=1; assert {"path","line","term"}<=set(a[0])' 2>/dev/null; then
  report N7_json_format 0
else
  report N7_json_format 1
fi

echo ""
echo "test_denylist_gate: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
