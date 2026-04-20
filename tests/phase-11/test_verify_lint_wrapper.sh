#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_verify_lint_wrapper.sh — BRWN-17: `verify` wraps
# `bin/lint.sh --ci` with the brownfield-relevant categories
# (yaml,provenance,orphan,crossref,brownfield — NOT privacy).
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

set +e
stdout=$(bash "$REPO_ROOT/bin/brownfield.sh" verify --root "$TMP" 2>&1)
ec=$?
set -e

if echo "$stdout" | grep -q "not yet implemented"; then
    echo "FAIL: bin/brownfield.sh verify not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi

# Stdout or log should indicate lint was invoked (either `lint --ci` or a
# summary derived from lint output). Also must reference the scoped
# categories.
if ! echo "$stdout" | grep -qE 'lint --ci|yaml,provenance,orphan,crossref,brownfield|Phase-11 verify'; then
    echo "FAIL: verify output does not reference lint --ci or the scoped categories" >&2
    echo "$stdout" >&2
    exit 1
fi

# Must NOT include the privacy category in the wrapped call.
if echo "$stdout" | grep -qE 'lint --ci.*--category[^\s]*privacy|--category[^\s]*privacy.*lint --ci'; then
    echo "FAIL: verify wrapped lint with privacy category (should be out-of-scope)" >&2
    echo "$stdout" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
