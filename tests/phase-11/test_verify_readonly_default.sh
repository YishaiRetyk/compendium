#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_verify_readonly_default.sh — BRWN-17: `verify` is
# READ-ONLY by default; no --promote = no bootstrap_stage flips.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo pre-typed-vault)
trap 'rm -rf "$TMP"' EXIT

set +e
invoke_tool_compat brownfield verify --root "$TMP" >/dev/null 2>stderr.txt
ec=$?
set -e

if grep -q "not yet implemented" stderr.txt 2>/dev/null; then
    rm -f stderr.txt
    echo "FAIL: bin/brownfield.sh verify not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi
rm -f stderr.txt

dirty=$(cd "$TMP" && git status --porcelain -- 'wiki-cloud/')
if [ -n "$dirty" ]; then
    echo "FAIL: verify (no --promote) mutated wiki-cloud/ (read-only contract violated):" >&2
    echo "$dirty" >&2
    exit 1
fi

# No page should have been flipped from bootstrapped -> verified.
if grep -r -q '^bootstrap_stage: verified' "$TMP/wiki-cloud/"; then
    echo "FAIL: verify (no --promote) flipped bootstrap_stage to verified" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
