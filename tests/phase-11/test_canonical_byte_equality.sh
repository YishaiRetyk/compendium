#!/usr/bin/env bash
# EXPECTED_BY: 11-02
# tests/phase-11/test_canonical_byte_equality.sh — BRWN-14: canonical
# scripts under schema/brownfield/migrations/ are byte-equal to the copies
# suggest places under .brownfield/migrations/ (modulo the prepended
# op_hash header lines).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP_REPO=$(make_fixture_repo small-vault-ambiguous)
trap 'rm -rf "$TMP_REPO"' EXIT

if ! bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP_REPO" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

assert_canonical_scripts_byte_identical "$TMP_REPO"

echo "PASS $NAME"; exit 0
