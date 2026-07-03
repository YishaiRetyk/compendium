#!/usr/bin/env bash
# Plan 10-02 Task 2 Test 5: D-18 'unknown' framing contract.
# Asserts:
#   - 'Needs human judgment' section contains a line for vault/musings.md
#   - That line ends with `?` (question-framed prose; never pre-fills a type suggestion)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

tmp=$(make_fixture_repo scan-vault-basic)
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

invoke_tool_compat brownfield scan --root "$tmp" >/dev/null 2>&1
report="$tmp/.brownfield/REPORT.md"

# Extract the 'Needs human judgment' section content (lines after the heading
# until the next '## ' or '---' footer).
section=$(awk '
    /^## Needs human judgment$/ {in_sec=1; next}
    in_sec && /^## / {in_sec=0}
    in_sec && /^---$/ {in_sec=0}
    in_sec {print}
' "$report")

if [ -z "$section" ]; then
    echo "FAIL: 'Needs human judgment' section is empty" >&2
    cat "$report" >&2
    exit 1
fi

# vault/musings.md must appear in the section.
echo "$section" | grep -q "vault/musings.md" \
    || { echo "FAIL: vault/musings.md not in 'Needs human judgment'" >&2; echo "$section" >&2; exit 1; }

# The line for vault/musings.md must end with '?' (question-framed per D-18).
musings_line=$(echo "$section" | grep "vault/musings.md" | head -1)
if [[ "$musings_line" != *\? ]]; then
    echo "FAIL: musings.md judgment line does not end with '?'" >&2
    echo "Got: $musings_line" >&2
    exit 1
fi

echo "PASS: D-18 unknown framing (question-ended)"
