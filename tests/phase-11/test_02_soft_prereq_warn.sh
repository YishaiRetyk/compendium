#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_02_soft_prereq_warn.sh — D-12 soft state-based prereq:
# when majority of bootstrapped pages still have empty type:, 02 prints a
# WARN to stderr and continues (exit 0).
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

set +e
stderr=$(bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" --apply 2>&1 >/dev/null)
ec=$?
set -e

if echo "$stderr" | grep -q "not yet implemented"; then
    echo "FAIL: 02-provenance-bootstrap.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

if [ "$ec" != "0" ]; then
    echo "FAIL: 02 --apply exited non-zero on soft-prereq WARN (must be exit 0 per D-12)" >&2
    echo "$stderr" >&2
    exit 1
fi

EXPECTED="WARN:"
if ! echo "$stderr" | grep -q "$EXPECTED"; then
    echo "FAIL: 02 did not emit WARN on stderr for majority-untyped vault" >&2
    echo "$stderr" >&2
    exit 1
fi

EXPECTED_PHRASE="bootstrapped pages still have empty type:. 02-provenance-bootstrap works best after page typing review or on pages with existing valid type. Proceeding anyway."
if ! echo "$stderr" | grep -qF "$EXPECTED_PHRASE"; then
    echo "FAIL: 02 WARN phrase did not match verbatim CONTEXT.md wording" >&2
    echo "--- got stderr ---" >&2
    echo "$stderr" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
