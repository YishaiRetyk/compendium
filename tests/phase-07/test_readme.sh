#!/usr/bin/env bash
# test_readme.sh — asserts README.md structure, required links, and voice constraints.
set -euo pipefail

FAIL=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAIL=1; }

ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

# 1. README exists
if [ -f README.md ]; then pass "README.md exists"; else fail "README.md missing"; fi

# 2. Links to quickstart
if grep -q 'docs/quickstart.md' README.md; then
  pass "README links to docs/quickstart.md"
else
  fail "README does not link to docs/quickstart.md"
fi

# 3. At least 5 of 6 required sections
SECTION_COUNT=$(grep -cE '^## What this is|^## Who this is for|^## Repo shape|^## Prerequisites|^## First step|^## License' README.md || true)
if [ "$SECTION_COUNT" -ge 5 ]; then
  pass "README has $SECTION_COUNT/6 required sections (≥5)"
else
  fail "README has only $SECTION_COUNT/6 required sections (need ≥5)"
fi

# 4. <org>/<repo> placeholder (D-02)
if grep -q '<org>/<repo>' README.md; then
  pass "README uses <org>/<repo> placeholder"
else
  fail "README is missing <org>/<repo> placeholder"
fi

# 5. No RAG framing in the top pitch (D-10)
if grep -qiE 'why not RAG|vs RAG' README.md; then
  fail "README contains RAG framing (D-10 voice violation)"
else
  pass "README has no RAG framing"
fi

exit "$FAIL"
