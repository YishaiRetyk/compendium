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

# Stubs still pending future-phase populate carry the exact
# "Status: stub — populated in v1.1 Phase" marker. ci.md was populated in
# Phase 9 Plan 06; brownfield.md was populated in Phase 10 Plan 05; the final
# three stubs (schema-tour.md, privacy-model.md, examples.md) were populated in
# Phase 13.1 Plan 04 (all drop from the stub list — Phase 08-04 / 09-06
# precedent for relaxing prior-phase tests when a successor plan populates the
# stub). With every reference doc now authored, the stub list is empty.
STUB_FILES=()
STUBS_OK=0
for f in "${STUB_FILES[@]}"; do
  if grep -q 'Status: stub — populated in v1.1 Phase' "$f"; then
    STUBS_OK=$((STUBS_OK+1))
  else
    fail "$f missing 'Status: stub — populated in v1.1 Phase' marker"
  fi
done
if [ "${#STUB_FILES[@]}" -eq 0 ]; then pass "no reference stubs remain — all reference docs authored"; fi

# schema-tour.md / privacy-model.md / examples.md are NOT stubs (populated in Phase 13.1 Plan 04)
for f in docs/reference/schema-tour.md docs/reference/privacy-model.md docs/reference/examples.md; do
  if grep -q 'Status: stub' "$f"; then
    fail "$f contains 'Status: stub' (Phase 13.1 Plan 04 populated this file; must no longer be a stub)"
  else
    pass "$f is not marked as a stub"
  fi
done

# ci.md is NOT a stub (populated in Phase 9 Plan 06)
if grep -q 'Status: stub' docs/reference/ci.md; then
  fail "ci.md contains 'Status: stub' (Phase 9 Plan 06 populated this file; must no longer be a stub)"
else
  pass "ci.md is not marked as a stub"
fi

# brownfield.md is NOT a stub (populated in Phase 10 Plan 05)
if grep -q 'Status: stub' docs/reference/brownfield.md; then
  fail "brownfield.md contains 'Status: stub' (Phase 10 Plan 05 populated this file; must no longer be a stub)"
else
  pass "brownfield.md is not marked as a stub"
fi

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
