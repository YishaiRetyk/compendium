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

TOTAL=$((PASS + FAIL))
echo ""
echo "requirements_sync: ${PASS}/${TOTAL}"
if [ "$FAIL" -gt 0 ]; then
    echo "Failed tests: ${FAILED[*]}" >&2
    exit 1
fi
exit 0
