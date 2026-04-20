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

if ! bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

if ! bash "$TMP/.brownfield/migrations/04-privacy-review.sh" >/dev/null 2>&1; then
    echo "FAIL: 04-privacy-review.sh not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

FINDINGS="$TMP/.brownfield/privacy-findings.yaml"
assert_file_exists "$FINDINGS"

# Expect findings for each of the fixture's PII patterns (at least one each)
for pattern in 'jdoe@acme.com' '212-555-0199' '123-45-6789'; do
    if ! grep -q "$pattern" "$FINDINGS"; then
        echo "FAIL: privacy-findings.yaml missing expected pattern: $pattern" >&2
        exit 1
    fi
done

REPORT="$TMP/.brownfield/REPORT.md"
assert_file_exists "$REPORT"
assert_grep "^## Privacy review" "$REPORT"

dirty=$(cd "$TMP" && git status --porcelain -- 'wiki/')
if [ -n "$dirty" ]; then
    echo "FAIL: 04 mutated wiki/ (advisory-only contract violated):" >&2
    echo "$dirty" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
