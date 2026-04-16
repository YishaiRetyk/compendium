#!/usr/bin/env bash
# tests/phase-08/test_manual_setup_checklist.sh -- MANUAL-03 wizard-prompt checklist verification.
# Asserts a 6-item prompt checklist appears in Section 10 mapping 1:1 to wizard prompts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/docs/manual-setup.md"

assert_file_exists "$DOC" "docs/manual-setup.md must exist (MANUAL-03)"

# Exactly 6 checklist items matching '- [ ] **Prompt [1-6]'
CHECKLIST_COUNT=$(grep -cE '^- \[ \] \*\*Prompt [1-6]' "$DOC" || true)
if [ "$CHECKLIST_COUNT" -ne 6 ]; then
    echo "ASSERT FAIL: expected exactly 6 '- [ ] **Prompt [1-6]' checklist items, got $CHECKLIST_COUNT" >&2
    exit 1
fi

echo "PASS: manual-setup.md has exactly 6 wizard-prompt checklist items (MANUAL-03)"
exit 0
