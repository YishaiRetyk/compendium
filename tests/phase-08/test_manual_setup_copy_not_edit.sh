#!/usr/bin/env bash
# tests/phase-08/test_manual_setup_copy_not_edit.sh -- review concern #3 verification.
# Asserts the manual-setup.md pre-step copies schema/AGENTS.template.md → AGENTS.md
# (NOT edit-in-place), and all "File to edit:" lines point at AGENTS.md (never at the
# source template).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/docs/manual-setup.md"

assert_file_exists "$DOC" "docs/manual-setup.md must exist"

# Pre-step must show either `cp schema/AGENTS.template.md AGENTS.md` OR the `sed ... schema/AGENTS.template.md > AGENTS.md` one-shot pipeline.
if ! grep -qE 'cp schema/AGENTS\.template\.md AGENTS\.md' "$DOC" \
   && ! grep -qE 'sed .+ schema/AGENTS\.template\.md > AGENTS\.md' "$DOC"; then
    echo "ASSERT FAIL: manual-setup.md pre-step must either 'cp schema/AGENTS.template.md AGENTS.md' or run a sed pipeline writing to AGENTS.md (review concern #3: copy-not-edit)" >&2
    exit 1
fi

# No "File to edit:" line may reference the template directly — users must NEVER be
# instructed to mutate schema/AGENTS.template.md in place.
if grep -qE '^\*\*File to edit:\*\*[[:space:]]*`?schema/AGENTS\.template\.md' "$DOC"; then
    echo "ASSERT FAIL: manual-setup.md has a 'File to edit:' line pointing at schema/AGENTS.template.md (review concern #3 violation: template must stay pristine)" >&2
    grep -nE '^\*\*File to edit:\*\*[[:space:]]*`?schema/AGENTS\.template\.md' "$DOC" >&2
    exit 1
fi

# At least 2 "File to edit:" lines must reference AGENTS.md (Sections 2 PRIMARY_DOMAIN + 3 AGENT_FILENAME).
# Post-Phase-16 (reference extraction, CR-01): Sections 4 (Privacy) and 5 (Decay) no longer edit
# AGENTS.md — privacy is structural (§13) and the decay profile is recorded only in
# .wizard-answers.yaml + the decision record, so the template-substitution sections shrank to 2.
AGENTS_EDIT_COUNT=$(grep -cE '^\*\*File to edit:\*\*[[:space:]]*`?AGENTS\.md' "$DOC" || true)
if [ "$AGENTS_EDIT_COUNT" -lt 2 ]; then
    echo "ASSERT FAIL: expected >=2 'File to edit: AGENTS.md' lines (Sections 2/3), got $AGENTS_EDIT_COUNT" >&2
    exit 1
fi

echo "PASS: manual-setup.md uses copy-not-edit flow; $AGENTS_EDIT_COUNT 'File to edit: AGENTS.md' lines; zero template-edit-in-place instructions (review concern #3)"
exit 0
