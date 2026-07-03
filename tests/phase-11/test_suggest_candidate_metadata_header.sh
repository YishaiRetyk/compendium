#!/usr/bin/env bash
# EXPECTED_BY: 11-02
# tests/phase-11/test_suggest_candidate_metadata_header.sh — BRWN-11 + D-09:
# suggest writes the metadata header (schema_version, tool_version,
# generated_at, vault_root, source_script_hash) at the top of each
# .brownfield/*.yaml candidate artifact.
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

if ! invoke_tool_compat brownfield suggest --root "$TMP_REPO" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

for yaml in page-typing-candidates.yaml page-typing-decisions.yaml \
            provenance-bootstrap-report.yaml cross-link-candidates.yaml \
            privacy-findings.yaml; do
    path="$TMP_REPO/.brownfield/$yaml"
    assert_file_exists "$path"
    head_block=$(head -7 "$path")
    for expected in \
        "schema_version: 1" \
        "tool_version: 1.1.0" \
        "generated_at:" \
        "vault_root:" \
        "source_script_hash: sha256:"; do
        if ! grep -q -- "$expected" <(echo "$head_block"); then
            echo "FAIL: metadata header on $yaml missing field: $expected" >&2
            echo "--- head -7 ---" >&2
            echo "$head_block" >&2
            exit 1
        fi
    done
done

echo "PASS $NAME"; exit 0
