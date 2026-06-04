#!/usr/bin/env bash
# tests/phase-08/test_manual_setup_file_list.sh -- MANUAL-05 file-touch list verification.
# Asserts Section 12 enumerates all 5 files the wizard writes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/docs/manual-setup.md"

assert_file_exists "$DOC" "docs/manual-setup.md must exist (MANUAL-05)"

# All 5 wizard-written files must be mentioned
for pattern in 'AGENTS\.md' 'CLAUDE\.md' '\.wizard-answers\.yaml' 'wiki-cloud/decisions/' 'wiki-cloud/index\.md'; do
    if ! grep -qE "$pattern" "$DOC"; then
        echo "ASSERT FAIL: manual-setup.md missing file-touch entry matching '$pattern'" >&2
        exit 1
    fi
done

echo "PASS: manual-setup.md lists all 5 wizard-touched files (AGENTS.md, CLAUDE.md, .wizard-answers.yaml, wiki-cloud/decisions/, wiki-cloud/index.md) (MANUAL-05)"
exit 0
