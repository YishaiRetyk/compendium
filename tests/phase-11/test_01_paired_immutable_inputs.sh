#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_01_paired_immutable_inputs.sh — REVIEWS item 2 (half 2
# of the paired contract): candidates.yaml is REQUIRED — 01 --apply without
# it must fail loudly with a clear error mentioning the missing file.
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

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

# Approve everything
DECFILE="$TMP/.brownfield/page-typing-decisions.yaml"
sed -i 's/^\([[:space:]]*\)decision:[[:space:]]*pending/\1decision: approve/g' "$DECFILE"

# Delete the candidates input
rm -f "$TMP/.brownfield/page-typing-candidates.yaml"

# Run 01 --apply — must fail with a clear error
set +e
stderr=$(bash "$TMP/.brownfield/migrations/01-page-typing.sh" --apply 2>&1 >/dev/null)
ec=$?
set -e

if [ "$ec" = "0" ]; then
    echo "FAIL: 01-page-typing.sh --apply succeeded without candidates.yaml (expected non-zero exit)" >&2
    exit 1
fi

# Stderr should clearly mention the missing candidates file or the paired-inputs contract.
if ! echo "$stderr" | grep -qiE 'page-typing-candidates\.yaml|candidates.yaml not found|paired inputs'; then
    # Tolerate the Wave-0 stub message so this test still FAILs clearly RED
    if ! echo "$stderr" | grep -qi 'not yet implemented'; then
        echo "FAIL: 01 --apply failure did not mention candidates.yaml or paired-inputs:" >&2
        echo "$stderr" >&2
        exit 1
    fi
    # Wave-0 stub hits first — that's acceptable RED. Fall-through to FAIL.
    echo "FAIL: 01 --apply hit the Wave-0 stub (not yet implemented — Plan 11-03 pending)" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
