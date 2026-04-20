#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_verify_stale_artifact_warn.sh — REVIEWS item 9:
# verify WARNs on stderr when source_script_hash recorded in a candidate
# artifact's metadata header no longer matches the current script body's
# sha256; exit 0 (WARN, not error).
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

# Simulate drift: append an extra line to the byte-copy under .brownfield/.
# This changes the script body's sha256 so it no longer matches
# source_script_hash recorded in the candidate metadata header.
echo "# drift-simulation-comment" >> "$TMP/.brownfield/migrations/01-page-typing.sh"

set +e
bash "$REPO_ROOT/bin/brownfield.sh" verify --root "$TMP" >/dev/null 2>stderr.txt
ec=$?
set -e

if grep -q "not yet implemented" stderr.txt 2>/dev/null; then
    rm -f stderr.txt
    echo "FAIL: bin/brownfield.sh verify not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi

if ! grep -qiE 'stale candidate artifact|source_script_hash.*mismatch' stderr.txt; then
    echo "FAIL: verify did not WARN about stale candidate artifact on hash drift" >&2
    cat stderr.txt >&2
    rm -f stderr.txt
    exit 1
fi

if [ "$ec" != "0" ]; then
    echo "FAIL: verify exited non-zero on stale-artifact WARN (expected exit 0 — advisory)" >&2
    cat stderr.txt >&2
    rm -f stderr.txt
    exit 1
fi

rm -f stderr.txt
echo "PASS $NAME"; exit 0
