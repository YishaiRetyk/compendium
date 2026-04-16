#!/usr/bin/env bash
# test_privacy.sh — asserts PRIVACY.md explains tiers and points to AGENTS.md, without copying CI grep logic.
set -euo pipefail

FAIL=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAIL=1; }

ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

if [ ! -f PRIVACY.md ]; then
  fail "PRIVACY.md missing"
  exit 1
fi

grep -q 'local_only' PRIVACY.md   && pass "PRIVACY.md mentions local_only" || fail "PRIVACY.md missing local_only"
grep -q 'cloud_safe' PRIVACY.md   && pass "PRIVACY.md mentions cloud_safe" || fail "PRIVACY.md missing cloud_safe"
grep -qi 'AGENTS.md' PRIVACY.md   && pass "PRIVACY.md points to AGENTS.md" || fail "PRIVACY.md does not reference AGENTS.md"

# D-12: must NOT copy CI grep logic / raw CI snippets.
if grep -qiE '(\bgrep\b|CI gate config|::error)' PRIVACY.md; then
  fail "PRIVACY.md copies CI grep / gate-config logic (D-12 violation)"
else
  pass "PRIVACY.md does not copy CI grep logic"
fi

exit "$FAIL"
