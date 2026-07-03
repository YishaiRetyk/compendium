#!/usr/bin/env bash
# tests/phase-10/test_lint_brownfield_category_help.sh
# Phase 10 Plan 04 — asserts `bin/lint.sh --help` lists `brownfield` in the
# --category enum, confirming the category is registered + visible to users.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

out="$(invoke_tool_compat lint --help 2>&1)"
echo "$out" | grep -q 'brownfield' \
    || { echo "FAIL: --help output missing 'brownfield' category" >&2; echo "$out" >&2; exit 1; }

echo "PASS: lint --help advertises brownfield category"
