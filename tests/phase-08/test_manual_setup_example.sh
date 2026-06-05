#!/usr/bin/env bash
# tests/phase-08/test_manual_setup_example.sh -- MANUAL-02 minimal-diff example verification.
# Asserts the personal-knowledge (D-10) example appears in diff snippets; zero Kahneman
# tokens (NEUT-02/03 preservation); at least 4 triple-backtick-diff fences for Sections 2/3/4/5.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/docs/manual-setup.md"

assert_file_exists "$DOC" "docs/manual-setup.md must exist (MANUAL-02)"

# Minimal-diff example must use the neutral D-10 domain
assert_grep 'personal-knowledge' "$DOC" "manual-setup.md must use personal-knowledge as example (D-10)"

# NEUT-02/03: zero Kahneman tokens
if grep -qi 'kahneman' "$DOC"; then
    echo "ASSERT FAIL: manual-setup.md contains 'kahneman' token (NEUT-02/03 regression)" >&2
    exit 1
fi

# At least 2 diff-fence openers (triple-backtick + "diff") — one per Section 2/3.
# Post-Phase-16 (reference extraction, CR-01): Sections 4 (Privacy) and 5 (Decay) no longer
# carry a minimal-diff (they are "File to edit: None" — privacy structural per §13, decay not
# rendered into the spec), so the diff-fence count dropped from 4 to 2.
# Use a variable to hold the pattern so bash does not try to command-substitute the backticks.
DIFF_FENCE_PATTERN='^```diff$'
DIFF_FENCE_COUNT=$(grep -cE "$DIFF_FENCE_PATTERN" "$DOC" || true)
if [ "$DIFF_FENCE_COUNT" -lt 2 ]; then
    echo "ASSERT FAIL: expected >=2 diff-fence openers (one per Section 2/3), got $DIFF_FENCE_COUNT" >&2
    exit 1
fi

echo "PASS: manual-setup.md uses personal-knowledge domain, zero Kahneman tokens, has $DIFF_FENCE_COUNT diff fences"
exit 0
