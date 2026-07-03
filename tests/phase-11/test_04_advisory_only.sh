#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_04_advisory_only.sh — D-06 + Q7: 04-privacy-review.sh
# writes privacy-findings.yaml + REPORT.md section; no vault mutations.
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

FINDINGS="$TMP/.brownfield/privacy-findings.yaml"
assert_file_exists "$FINDINGS"

# Expect findings for each of the fixture's PII patterns.  SSN values are
# redacted to '[redacted-SSN]' per the plan's design policy (must_haves
# line 29 + threat model T-11-03 + Plan 11-02 suggest implementation); raw
# SSN MUST NOT leak even into the gitignored .brownfield/ directory because
# it is the most-sensitive pattern class.  Email and phone are retained raw
# (review item 12 — operator triage need).
for pattern in 'jdoe@acme.com' '212-555-0199' 'pattern_type: ssn' '\[redacted-SSN\]'; do
    if ! grep -qE "$pattern" "$FINDINGS"; then
        echo "FAIL: privacy-findings.yaml missing expected pattern: $pattern" >&2
        exit 1
    fi
done
# Extra guard: raw SSN '123-45-6789' MUST NOT appear in findings.yaml.
if grep -qE '123-45-6789' "$FINDINGS"; then
    echo "FAIL: raw SSN '123-45-6789' leaked into privacy-findings.yaml (must be redacted)" >&2
    exit 1
fi

REPORT="$TMP/.brownfield/REPORT.md"
assert_file_exists "$REPORT"
assert_grep "^## Privacy review" "$REPORT"

dirty=$(cd "$TMP" && git status --porcelain -- 'wiki-cloud/')
if [ -n "$dirty" ]; then
    echo "FAIL: 04 mutated wiki-cloud/ (advisory-only contract violated):" >&2
    echo "$dirty" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
