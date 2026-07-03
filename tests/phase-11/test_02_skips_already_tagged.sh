#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_02_skips_already_tagged.sh — BRWN-15 + D-05: 02 skips
# bullets that already carry [epistemic:: sourced] or [epistemic:: inferred]
# (no double-tagging).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo already-tagged-vault)
trap 'rm -rf "$TMP"' EXIT

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

if ! bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 02-provenance-bootstrap.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

# No double-tagging: no line should have two epistemic markers
if grep -rnE '\[epistemic::.*\].*\[epistemic::' "$TMP/wiki-cloud/" 2>/dev/null; then
    echo "FAIL: double-tagging detected (02 re-processed already-tagged bullets)" >&2
    exit 1
fi

# The fixture's pages shouldn't have changed at all (all bullets were
# already tagged).
dirty=$(cd "$TMP" && git status --porcelain -- 'wiki-cloud/')
if [ -n "$dirty" ]; then
    echo "FAIL: already-tagged-vault was mutated by 02 --apply (should be no-op):" >&2
    echo "$dirty" >&2
    (cd "$TMP" && git diff -- 'wiki-cloud/') >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
