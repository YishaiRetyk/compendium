#!/usr/bin/env bash
# test_license.sh — asserts LICENSE is MIT boilerplate.
set -euo pipefail

FAIL=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAIL=1; }

ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

if [ ! -f LICENSE ]; then
  fail "LICENSE missing"
  exit 1
fi

grep -q 'MIT License' LICENSE        && pass "LICENSE has 'MIT License'"        || fail "LICENSE missing 'MIT License'"
grep -q 'Permission is hereby granted' LICENSE && pass "LICENSE has permission clause" || fail "LICENSE missing permission clause"
grep -q 'WITHOUT WARRANTY' LICENSE   && pass "LICENSE has warranty disclaimer" || fail "LICENSE missing warranty disclaimer"

exit "$FAIL"
