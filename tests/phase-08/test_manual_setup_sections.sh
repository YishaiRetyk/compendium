#!/usr/bin/env bash
# tests/phase-08/test_manual_setup_sections.sh -- MANUAL-01 structural verification.
# Asserts docs/manual-setup.md contains the 13-section D-07 structure and cites
# each placeholder's line number in schema/AGENTS.template.md.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/docs/manual-setup.md"

assert_file_exists "$DOC" "docs/manual-setup.md must exist (MANUAL-01)"

# At least 13 Section headings per revised D-07 layout (Sections 1-13)
SECTION_COUNT=$(grep -cE '^## Section [0-9]+' "$DOC" || true)
if [ "$SECTION_COUNT" -lt 13 ]; then
    echo "ASSERT FAIL: expected >=13 '## Section N' headings, got $SECTION_COUNT" >&2
    exit 1
fi

# Each placeholder-site line citation must be present (Sections 2/3/4/5).
for line_num in 588 32 589 848; do
    assert_grep "line $line_num" "$DOC" "manual-setup.md must cite line $line_num"
done

echo "PASS: manual-setup.md has >=13 Section headings and cites all 4 placeholder line numbers"
exit 0
