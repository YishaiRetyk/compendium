#!/usr/bin/env bash
# test_reference_stubs.sh — asserts 5 reference stubs + full release runbook.
set -euo pipefail

FAIL=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAIL=1; }

ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

# All 7 reference files exist
for f in docs/reference/index.md docs/reference/schema-tour.md docs/reference/brownfield.md docs/reference/privacy-model.md docs/reference/ci.md docs/reference/examples.md docs/reference/release.md; do
  if [ -f "$f" ]; then pass "$f exists"; else fail "$f missing"; fi
done

# 5 stubs carry the exact "Status: stub — populated in v1.1 Phase" marker
STUBS_OK=0
for f in docs/reference/schema-tour.md docs/reference/brownfield.md docs/reference/privacy-model.md docs/reference/ci.md docs/reference/examples.md; do
  if grep -q 'Status: stub — populated in v1.1 Phase' "$f"; then
    STUBS_OK=$((STUBS_OK+1))
  else
    fail "$f missing 'Status: stub — populated in v1.1 Phase' marker"
  fi
done
if [ "$STUBS_OK" -eq 5 ]; then pass "all 5 reference stubs carry stub marker"; fi

# release.md is NOT a stub
if grep -q 'Status: stub' docs/reference/release.md; then
  fail "release.md contains 'Status: stub' (must be the full runbook, not a stub)"
else
  pass "release.md is not marked as a stub"
fi

# release.md required content
for token in -- '--dry-run' '--apply' 'check-neutrality.sh' 'Prerequisites' 'Rollback'; do
  [ "$token" = "--" ] && continue
  if grep -q -- "$token" docs/reference/release.md; then
    pass "release.md contains $token"
  else
    fail "release.md missing $token"
  fi
done

# brownfield.md mentions ruamel.yaml (ROADMAP Phase 10 note)
if grep -q 'ruamel' docs/reference/brownfield.md; then
  pass "brownfield.md mentions ruamel.yaml prerequisite"
else
  fail "brownfield.md missing ruamel.yaml mention"
fi

exit "$FAIL"
