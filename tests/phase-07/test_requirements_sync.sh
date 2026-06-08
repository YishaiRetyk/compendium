#!/usr/bin/env bash
# tests/phase-07/test_requirements_sync.sh -- Behavior tests for bin/requirements-sync.sh.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/bin/requirements-sync.sh"
FIXTURES="$REPO_ROOT/tests/phase-07/fixtures/requirements-sync"

PASS=0
FAIL=0
FAILED=()

_pass() { echo "PASS $1"; PASS=$((PASS + 1)); }
_fail() { echo "FAIL $1: $2"; FAIL=$((FAIL + 1)); FAILED+=("$1"); }

# --- Test 1: clean advisory ---
t1_clean_advisory() {
    local tmp out rc
    tmp=$(mktemp -d)
    cp "$FIXTURES/REQUIREMENTS.md" "$tmp/REQUIREMENTS.md"
    cp "$FIXTURES/07-VERIFICATION.md" "$tmp/07-VERIFICATION.md"
    out=$(bash "$SCRIPT" --root "$tmp" 2>/dev/null); rc=$?
    if [ "$rc" -ne 0 ]; then _fail t1_clean_advisory "expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    if ! echo "$out" | grep -qE 'REQ-ID.*REQUIREMENTS\.md.*VERIFICATION\.md.*Drift'; then
        _fail t1_clean_advisory "missing header row"; rm -rf "$tmp"; return
    fi
    if echo "$out" | grep -qE '\| *DRIFT *\|'; then
        _fail t1_clean_advisory "unexpected DRIFT in clean fixture"; rm -rf "$tmp"; return
    fi
    _pass t1_clean_advisory
    rm -rf "$tmp"
}

# --- Test 2: drift advisory ---
t2_drift_advisory() {
    local tmp out rc
    tmp=$(mktemp -d)
    cp "$FIXTURES/REQUIREMENTS.md" "$tmp/REQUIREMENTS.md"
    cp "$FIXTURES/07-drift-VERIFICATION.md" "$tmp/07-VERIFICATION.md"
    out=$(bash "$SCRIPT" --root "$tmp" 2>/dev/null); rc=$?
    if [ "$rc" -ne 0 ]; then _fail t2_drift_advisory "expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    if ! echo "$out" | grep -q 'DRIFT'; then
        _fail t2_drift_advisory "expected DRIFT substring in output"; rm -rf "$tmp"; return
    fi
    _pass t2_drift_advisory
    rm -rf "$tmp"
}

# --- Test 3: drift strict ---
t3_drift_strict() {
    local tmp rc
    tmp=$(mktemp -d)
    cp "$FIXTURES/REQUIREMENTS.md" "$tmp/REQUIREMENTS.md"
    cp "$FIXTURES/07-drift-VERIFICATION.md" "$tmp/07-VERIFICATION.md"
    bash "$SCRIPT" --root "$tmp" --strict >/dev/null 2>&1; rc=$?
    if [ "$rc" -ne 2 ]; then _fail t3_drift_strict "expected exit 2, got $rc"; rm -rf "$tmp"; return; fi
    _pass t3_drift_strict
    rm -rf "$tmp"
}

# --- Test 4: JSON format ---
t4_json_format() {
    local tmp out rc
    tmp=$(mktemp -d)
    cp "$FIXTURES/REQUIREMENTS.md" "$tmp/REQUIREMENTS.md"
    cp "$FIXTURES/07-VERIFICATION.md" "$tmp/07-VERIFICATION.md"
    out=$(bash "$SCRIPT" --root "$tmp" --format json 2>/dev/null); rc=$?
    if [ "$rc" -ne 0 ]; then _fail t4_json_format "expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    if ! echo "$out" | python3 -c 'import json,sys
a=json.load(sys.stdin)
assert isinstance(a,list), "not a list"
for x in a:
    for k in ("req_id","requirements_md","verification_md","drift","note"):
        assert k in x, f"missing key {k}"
' 2>/dev/null; then
        _fail t4_json_format "JSON schema validation failed"; rm -rf "$tmp"; return
    fi
    _pass t4_json_format
    rm -rf "$tmp"
}

# --- Test 5: phase filter ---
t5_phase_filter() {
    local tmp out rc
    tmp=$(mktemp -d)
    cp "$FIXTURES/REQUIREMENTS.md" "$tmp/REQUIREMENTS.md"
    cp "$FIXTURES/07-VERIFICATION.md" "$tmp/07-VERIFICATION.md"
    out=$(bash "$SCRIPT" --root "$tmp" --phase 7 2>/dev/null); rc=$?
    if [ "$rc" -ne 0 ]; then _fail t5_phase_filter "expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    if echo "$out" | grep -q 'FOO-01'; then
        _fail t5_phase_filter "FOO-01 (Phase 8) should be filtered out"; rm -rf "$tmp"; return
    fi
    if ! echo "$out" | grep -q 'TMPL-01'; then
        _fail t5_phase_filter "TMPL-01 (Phase 7) should be present"; rm -rf "$tmp"; return
    fi
    _pass t5_phase_filter
    rm -rf "$tmp"
}

# --- Test 6: missing VERIFICATION.md ---
t6_missing_verification() {
    local tmp out rc
    tmp=$(mktemp -d)
    cp "$FIXTURES/REQUIREMENTS.md" "$tmp/REQUIREMENTS.md"
    # No VERIFICATION.md file at all
    out=$(bash "$SCRIPT" --root "$tmp" 2>/dev/null); rc=$?
    if [ "$rc" -ne 0 ]; then _fail t6_missing_verification "expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    if ! echo "$out" | grep -qi 'Phase not yet run'; then
        _fail t6_missing_verification "expected 'OK - Phase not yet run' note"; rm -rf "$tmp"; return
    fi
    if echo "$out" | grep -qE '\| *DRIFT *\|'; then
        _fail t6_missing_verification "missing VERIFICATION must not be drift"; rm -rf "$tmp"; return
    fi
    _pass t6_missing_verification
    rm -rf "$tmp"
}

# --- Test 7: decimal phase filter and punctuated status ---
t7_decimal_phase_filter() {
    local tmp out rc
    tmp=$(mktemp -d)
    cat > "$tmp/REQUIREMENTS.md" <<'EOF'
# Requirements

| Requirement | Phase | Status |
|-------------|-------|--------|
| BOUND-01 | Phase 12.1 | Pending |
| NEUT-08 | Phase 7 | Deferred (partial - infrastructure shipped) |
EOF
    out=$(bash "$SCRIPT" --root "$tmp" --phase 12.1 2>/dev/null); rc=$?
    if [ "$rc" -ne 0 ]; then _fail t7_decimal_phase_filter "expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    if ! echo "$out" | grep -q 'BOUND-01'; then
        _fail t7_decimal_phase_filter "BOUND-01 (Phase 12.1) should be present"; rm -rf "$tmp"; return
    fi
    if echo "$out" | grep -q 'NEUT-08'; then
        _fail t7_decimal_phase_filter "NEUT-08 (Phase 7) should be filtered out"; rm -rf "$tmp"; return
    fi
    out=$(bash "$SCRIPT" --root "$tmp" 2>/dev/null); rc=$?
    if [ "$rc" -ne 0 ]; then _fail t7_decimal_phase_filter "expected unfiltered exit 0, got $rc"; rm -rf "$tmp"; return; fi
    if ! echo "$out" | grep -q 'Deferred (partial - infrastructure shipped)'; then
        _fail t7_decimal_phase_filter "punctuated status should be preserved"; rm -rf "$tmp"; return
    fi
    _pass t7_decimal_phase_filter
    rm -rf "$tmp"
}

# --- Test 8: --require-complete fails when in-scope REQ-IDs are Pending ---
t8_require_complete_fails_on_pending() {
    local tmp out rc
    tmp=$(mktemp -d)
    # Existing fixture has TMPL-01, TMPL-03, NEUT-01, DEBT-03, FOO-01 as Pending
    cp "$FIXTURES/REQUIREMENTS.md" "$tmp/REQUIREMENTS.md"
    cp "$FIXTURES/07-VERIFICATION.md" "$tmp/07-VERIFICATION.md"
    out=$(bash "$SCRIPT" --root "$tmp" --require-complete 2>/dev/null); rc=$?
    if [ "$rc" -ne 2 ]; then _fail t8_require_complete_fails_on_pending "expected exit 2, got $rc"; rm -rf "$tmp"; return; fi
    if ! echo "$out" | grep -q 'require-complete'; then
        _fail t8_require_complete_fails_on_pending "missing require-complete summary line"; rm -rf "$tmp"; return
    fi
    if ! echo "$out" | grep -q 'in-scope REQ-IDs are NOT Complete'; then
        _fail t8_require_complete_fails_on_pending "missing 'NOT Complete' summary"; rm -rf "$tmp"; return
    fi
    _pass t8_require_complete_fails_on_pending
    rm -rf "$tmp"
}

# --- Test 9: --require-complete passes when all in-scope REQ-IDs are Complete ---
t9_require_complete_passes_when_all_complete() {
    local tmp out rc
    tmp=$(mktemp -d)
    cat > "$tmp/REQUIREMENTS.md" <<'EOF'
# Fixture REQUIREMENTS

## Traceability
| Requirement | Phase | Status |
|-------------|-------|--------|
| TMPL-01 | Phase 7 | Complete |
| TMPL-02 | Phase 7 | Complete |
| NEUT-01 | Phase 7 | Complete |
EOF
    out=$(bash "$SCRIPT" --root "$tmp" --require-complete 2>/dev/null); rc=$?
    if [ "$rc" -ne 0 ]; then _fail t9_require_complete_passes_when_all_complete "expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    if ! echo "$out" | grep -q 'all 3 in-scope REQ-IDs are Complete'; then
        _fail t9_require_complete_passes_when_all_complete "missing 'all 3 ... Complete' summary"; rm -rf "$tmp"; return
    fi
    _pass t9_require_complete_passes_when_all_complete
    rm -rf "$tmp"
}

# --- Test 10: --require-complete composes with --phase ---
t10_require_complete_phase_scoped() {
    local tmp rc
    tmp=$(mktemp -d)
    cat > "$tmp/REQUIREMENTS.md" <<'EOF'
# Fixture REQUIREMENTS

## Traceability
| Requirement | Phase | Status |
|-------------|-------|--------|
| TMPL-01 | Phase 7 | Complete |
| TMPL-02 | Phase 7 | Complete |
| FOO-01  | Phase 8 | Pending |
EOF
    # Phase 7 (all Complete) -> exit 0
    bash "$SCRIPT" --root "$tmp" --require-complete --phase 7 >/dev/null 2>&1; rc=$?
    if [ "$rc" -ne 0 ]; then _fail t10_require_complete_phase_scoped "Phase 7 expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    # Phase 8 (Pending) -> exit 2
    bash "$SCRIPT" --root "$tmp" --require-complete --phase 8 >/dev/null 2>&1; rc=$?
    if [ "$rc" -ne 2 ]; then _fail t10_require_complete_phase_scoped "Phase 8 expected exit 2, got $rc"; rm -rf "$tmp"; return; fi
    # Without --require-complete, Phase 8 Pending exits 0 (advisory)
    bash "$SCRIPT" --root "$tmp" --phase 8 >/dev/null 2>&1; rc=$?
    if [ "$rc" -ne 0 ]; then _fail t10_require_complete_phase_scoped "Phase 8 advisory expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    _pass t10_require_complete_phase_scoped
    rm -rf "$tmp"
}

# --- Test 11: --strict default unchanged (drift-only, completion ignored) ---
t11_strict_does_not_check_completion() {
    local tmp rc
    tmp=$(mktemp -d)
    # All Pending in REQUIREMENTS.md and VERIFICATION.md -> 0 drift, but incomplete
    cat > "$tmp/REQUIREMENTS.md" <<'EOF'
# Fixture REQUIREMENTS

## Traceability
| Requirement | Phase | Status |
|-------------|-------|--------|
| TMPL-01 | Phase 7 | Pending |
EOF
    cat > "$tmp/07-VERIFICATION.md" <<'EOF'
# Phase 7 VERIFICATION
- TMPL-01: Pending
EOF
    bash "$SCRIPT" --root "$tmp" --strict >/dev/null 2>&1; rc=$?
    if [ "$rc" -ne 0 ]; then _fail t11_strict_does_not_check_completion "--strict alone with Pending+no-drift expected exit 0, got $rc"; rm -rf "$tmp"; return; fi
    bash "$SCRIPT" --root "$tmp" --require-complete >/dev/null 2>&1; rc=$?
    if [ "$rc" -ne 2 ]; then _fail t11_strict_does_not_check_completion "--require-complete alone with Pending expected exit 2, got $rc"; rm -rf "$tmp"; return; fi
    _pass t11_strict_does_not_check_completion
    rm -rf "$tmp"
}

# Execute tests
if [ ! -x "$SCRIPT" ] && [ ! -f "$SCRIPT" ]; then
    echo "FAIL setup: bin/requirements-sync.sh not found at $SCRIPT"
    exit 1
fi

t1_clean_advisory
t2_drift_advisory
t3_drift_strict
t4_json_format
t5_phase_filter
t6_missing_verification
t7_decimal_phase_filter
t8_require_complete_fails_on_pending
t9_require_complete_passes_when_all_complete
t10_require_complete_phase_scoped
t11_strict_does_not_check_completion

TOTAL=$((PASS + FAIL))
echo ""
echo "requirements_sync: ${PASS}/${TOTAL}"
if [ "$FAIL" -gt 0 ]; then
    echo "Failed tests: ${FAILED[*]}" >&2
    exit 1
fi
exit 0
