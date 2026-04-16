#!/usr/bin/env bash
# tests/phase-08/test_wizard_sync_claude.sh -- Open Q4 + WZRD-06 cross-cut:
# After wizard real-run (via --render-to), CLAUDE.md must be byte-identical
# to AGENTS.md (sync-claude contract preserved), and AGENTS.md must still
# be byte-identical to the canonical fixture (Plan 01/02 contract preserved).
# Also verifies the wizard source invokes sync-claude OR writes CLAUDE.md
# byte-identical to AGENTS.md (render-to case).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"
CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"
CANONICAL_RENDER="$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"

echo "TEST: AGENTS.md == CLAUDE.md byte-equal after wizard real-run (Open Q4)"

WORK="$(mktemp_repo)"
WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha \
    bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK" >/dev/null

assert_file_exists "$WORK/AGENTS.md"
assert_file_exists "$WORK/CLAUDE.md"

# AGENTS.md == CLAUDE.md (sync-claude invariant).
assert_byte_equal "$WORK/AGENTS.md" "$WORK/CLAUDE.md" \
    "CLAUDE.md must be byte-identical to AGENTS.md (sync-claude invariant)"

# AGENTS.md == canonical fixture (Plan 01/02 contract still holds).
assert_byte_equal "$CANONICAL_RENDER" "$WORK/AGENTS.md" \
    "rendered AGENTS.md must be byte-equal to canonical fixture (Plan 01/02 contract)"

# Verify wizard source invokes sync-claude OR writes CLAUDE.md via shutil.copyfile
# (either approach satisfies the byte-equal contract).
if ! grep -qE '(bash.*sync-claude\.sh|shutil\.copyfile.*CLAUDE\.md)' "$WIZARD"; then
    echo "ASSERT FAIL: wizard source neither invokes sync-claude.sh nor copies AGENTS.md to CLAUDE.md" >&2
    exit 1
fi

echo "PASS: CLAUDE.md byte-identical to AGENTS.md + canonical fixture contract preserved"
exit 0
