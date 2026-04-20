#!/usr/bin/env bash
# EXPECTED_BY: 11-05
# tests/phase-11/test_docs_verify_section.sh — BRWN-19: the brownfield
# reference doc contains a populated `## verify subcommand` section
# (≥15 lines) and mentions --promote.
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
    /^## verify subcommand/ { flag=1; next }
    /^## / && flag { flag=0 }
    flag { n++ }
    END { print n+0 }
' "$DOC")

if [ "$count" -lt "15" ]; then
    echo "FAIL: '## verify subcommand' section has only $count lines (expected ≥15)" >&2
    exit 1
fi

# Extract the verify section and check for --promote reference
body=$(awk '
    /^## verify subcommand/ { flag=1; next }
    /^## / && flag { flag=0 }
    flag { print }
' "$DOC")

if ! echo "$body" | grep -q -- '--promote'; then
    echo "FAIL: '## verify subcommand' section does not mention --promote" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
