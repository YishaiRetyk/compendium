#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_01_dryrun_default.sh — BRWN-13: 01-page-typing.sh
# defaults to dry-run (no flags = no mutation); vault git status stays clean.
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

if ! bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

# No flags = dry-run by default
if ! bash "$TMP/.brownfield/migrations/01-page-typing.sh" >/dev/null 2>&1; then
    echo "FAIL: 01-page-typing.sh (no flags) not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

# Vault wiki-cloud/ must be untouched
dirty=$(cd "$TMP" && git status --porcelain -- 'wiki-cloud/')
if [ -n "$dirty" ]; then
    echo "FAIL: 01-page-typing.sh dry-run mutated wiki-cloud/:" >&2
    echo "$dirty" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
