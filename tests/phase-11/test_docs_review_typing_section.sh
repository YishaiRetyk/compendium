#!/usr/bin/env bash
# EXPECTED_BY: 11-05
# tests/phase-11/test_docs_review_typing_section.sh — BRWN-19: the
# brownfield reference doc contains a populated
# `## review-typing subcommand` section (≥15 lines).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

DOC="$REPO_ROOT/docs/reference/brownfield.md"
assert_file_exists "$DOC"

count=$(awk '
    /^## review-typing subcommand/ { flag=1; next }
    /^## / && flag { flag=0 }
    flag { n++ }
    END { print n+0 }
' "$DOC")

if [ "$count" -lt "15" ]; then
    echo "FAIL: '## review-typing subcommand' section has only $count lines (expected ≥15)" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
