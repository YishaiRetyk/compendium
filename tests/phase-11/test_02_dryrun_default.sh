#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_02_dryrun_default.sh — BRWN-13: 02-provenance-
# bootstrap.sh defaults to dry-run (no flags = no mutations).
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

if ! bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" >/dev/null 2>&1; then
    echo "FAIL: 02-provenance-bootstrap.sh not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

dirty=$(cd "$TMP" && git status --porcelain -- 'wiki/')
if [ -n "$dirty" ]; then
    echo "FAIL: 02 dry-run mutated wiki/:" >&2
    echo "$dirty" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
