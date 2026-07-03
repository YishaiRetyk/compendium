#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_03_advisory_only.sh — D-06: 03-cross-link-inference.sh
# is advisory-only. It writes cross-link-candidates.yaml + REPORT.md section;
# it never mutates vault pages; --apply has no effect (exit non-zero or no-op).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo small-vault-ambiguous)
trap 'rm -rf "$TMP"' EXIT

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

if ! bash "$TMP/.brownfield/migrations/03-cross-link-inference.sh" >/dev/null 2>&1; then
    echo "FAIL: 03-cross-link-inference.sh not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

assert_file_exists "$TMP/.brownfield/cross-link-candidates.yaml"

REPORT="$TMP/.brownfield/REPORT.md"
assert_file_exists "$REPORT"
assert_grep "^## Cross-link candidates" "$REPORT"

# NO vault mutations
dirty=$(cd "$TMP" && git status --porcelain -- 'wiki-cloud/')
if [ -n "$dirty" ]; then
    echo "FAIL: 03 mutated wiki-cloud/ (advisory-only contract violated):" >&2
    echo "$dirty" >&2
    exit 1
fi

# 03 --apply should exit non-zero OR no-op. Non-zero is the preferred fail-
# loud behavior (no --apply in usage). We accept either.
set +e
bash "$TMP/.brownfield/migrations/03-cross-link-inference.sh" --apply >/dev/null 2>&1
ec=$?
set -e
dirty=$(cd "$TMP" && git status --porcelain -- 'wiki-cloud/')
if [ -n "$dirty" ]; then
    echo "FAIL: 03 --apply mutated wiki-cloud/ (advisory-only contract violated):" >&2
    echo "$dirty" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
