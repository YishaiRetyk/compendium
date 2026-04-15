#!/usr/bin/env bash
# test_kahneman_readme.sh — Phase 07 Plan 02
# Asserts examples/kahneman/README.md conforms to NEUT-05 requirements
# and wiki/decisions/dr-2026-04-15-kahneman-to-examples.md conforms to AGENTS.md §4.6 canonical schema.
set -euo pipefail

PASS=0
FAIL=0
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

README=examples/kahneman/README.md

# README existence + required sections.
if [ -f "$README" ]; then pass "README exists"; else fail "README missing"; exit 1; fi

for s in \
  "## What this cluster demonstrates" \
  "## Why it is preserved" \
  "## How to read it" \
  "## Which AGENTS.md sections it illustrates" \
  "## Do not edit"; do
  if grep -qF "$s" "$README"; then pass "README has section: $s"; else fail "README missing section: $s"; fi
done

if grep -q '^example: true' "$README"; then pass "README frontmatter example: true"; else fail "README missing example: true"; fi
if grep -q '^privacy: cloud_safe' "$README"; then pass "README frontmatter privacy: cloud_safe"; else fail "README missing privacy: cloud_safe"; fi

# Decision record canonical schema.
DR=wiki/decisions/dr-2026-04-15-kahneman-to-examples.md
if [ -f "$DR" ]; then pass "decision record exists"; else fail "decision record missing"; exit 1; fi

for k in '^type: decision' '^status: active' '^trigger_type: schema-update' '^epistemic_status: sourced' '^created_at: 2026-04-15' '^updated_at: 2026-04-15' '^affected_pages:'; do
  if grep -q "$k" "$DR"; then pass "DR has: $k"; else fail "DR missing: $k"; fi
done

# Forbidden non-canonical fields.
if grep -q '^date:' "$DR"; then fail "DR has forbidden 'date:' field"; else pass "DR has no forbidden 'date:' field"; fi
if grep -q '^class:' "$DR"; then fail "DR has forbidden 'class:' field"; else pass "DR has no forbidden 'class:' field"; fi

# All 7 required body sections.
for s in '## TL;DR' '## Decision' '## Why' '## Alternatives Considered' '## Consequences' '## Affected Pages' '## Sources'; do
  if grep -qF "$s" "$DR"; then pass "DR has section: $s"; else fail "DR missing section: $s"; fi
done

echo
echo "test_kahneman_readme: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
