#!/usr/bin/env bash
# EXPECTED_BY: 11-02
# tests/phase-11/test_suggest_byte_copies_migrations.sh — BRWN-11: suggest
# byte-copies all four canonical scripts into .brownfield/migrations/ on the
# target vault (mode preserved; body post-op_hash-strip matches canonical).
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

for script in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
    assert_file_exists "$TMP_REPO/.brownfield/migrations/$script"
    if [ ! -x "$TMP_REPO/.brownfield/migrations/$script" ]; then
        echo "FAIL: copied migration script not executable: $script" >&2
        exit 1
    fi
done

assert_canonical_scripts_byte_identical "$TMP_REPO"

echo "PASS $NAME"; exit 0
