#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_02_no_magic_strings.sh — BRWN-15: 02 uses ONLY
# [epistemic:: inferred] — never [prov:bootstrap], [epistemic:: imported],
# or [epistemic:: bootstrapped].
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

if ! bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 02-provenance-bootstrap.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

if grep -rnE '\[prov:bootstrap\]|\[epistemic:: imported\]|\[epistemic:: bootstrapped\]' "$TMP/wiki/" 2>/dev/null; then
    echo "FAIL: forbidden magic strings introduced by 02 (BRWN-15 contract violated)" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
