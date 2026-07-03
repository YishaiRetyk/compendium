#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_applied_log_advisory_schema.sh — BRWN-14: advisory
# applied.log blocks (03, 04) have mutations: none + report_section field +
# per-script summary fields.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo privacy-sensitive-vault)
trap 'rm -rf "$TMP"' EXIT

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

if ! bash "$TMP/.brownfield/migrations/04-privacy-review.sh" >/dev/null 2>&1; then
    echo "FAIL: 04-privacy-review.sh not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

LOG="$TMP/.brownfield/applied.log"
assert_file_exists "$LOG"

assert_grep "^## 04-privacy-review.sh @ " "$LOG" "04 header missing"
assert_grep "^mode: advisory" "$LOG" "04 mode missing"
assert_grep "^mutations: none" "$LOG" "04 mutations field missing"
assert_grep "^report_section: REPORT.md#privacy-review" "$LOG" "04 report_section missing"
assert_grep "pages_scanned:" "$LOG" "04 summary missing pages_scanned"
assert_grep "^- findings:" "$LOG" "04 summary missing findings"
assert_grep "high_risk_findings:" "$LOG" "04 summary missing high_risk_findings"

if ! bash "$TMP/.brownfield/migrations/03-cross-link-inference.sh" >/dev/null 2>&1; then
    echo "FAIL: 03-cross-link-inference.sh not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

assert_grep "^## 03-cross-link-inference.sh @ " "$LOG" "03 header missing"
assert_grep "^report_section: REPORT.md#cross-link-candidates" "$LOG" "03 report_section missing"
assert_grep "^- candidates:" "$LOG" "03 summary missing candidates"
assert_grep "already_linked:" "$LOG" "03 summary missing already_linked"

echo "PASS $NAME"; exit 0
