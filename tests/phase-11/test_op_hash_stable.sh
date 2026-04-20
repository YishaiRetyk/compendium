#!/usr/bin/env bash
# EXPECTED_BY: 11-02
# tests/phase-11/test_op_hash_stable.sh — D-10: op_hash depends on canonical
# script body + data-schema-version only, NOT on vault content. Hashes
# computed across two different vaults must match for the same script.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP1=$(make_fixture_repo small-vault-ambiguous)
TMP2=$(make_fixture_repo large-vault-ambiguous)
trap 'rm -rf "$TMP1" "$TMP2"' EXIT

if ! bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP1" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi
bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP2" >/dev/null 2>&1

for script in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
    h1=$(grep -E '^# op_hash: sha256:[0-9a-f]{64}$' "$TMP1/.brownfield/migrations/$script" | head -1 | awk '{print $3}')
    h2=$(grep -E '^# op_hash: sha256:[0-9a-f]{64}$' "$TMP2/.brownfield/migrations/$script" | head -1 | awk '{print $3}')
    if [ -z "$h1" ] || [ -z "$h2" ]; then
        echo "FAIL: missing op_hash on $script (h1='$h1', h2='$h2')" >&2
        exit 1
    fi
    if [ "$h1" != "$h2" ]; then
        echo "FAIL: op_hash differs between vaults for $script: $h1 vs $h2" >&2
        exit 1
    fi
done

echo "PASS $NAME"; exit 0
