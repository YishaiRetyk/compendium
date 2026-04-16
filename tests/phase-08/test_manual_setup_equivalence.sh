#!/usr/bin/env bash
# tests/phase-08/test_manual_setup_equivalence.sh -- MANUAL-04 equivalence statement verification.
# Asserts Section 11 contains the literal 'byte-identical end state' claim and references
# the CI parity test (either setup-parity.yml or test_canonical_byte_equality.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/docs/manual-setup.md"

assert_file_exists "$DOC" "docs/manual-setup.md must exist (MANUAL-04)"

# Literal equivalence phrase
assert_grep 'byte-identical end state' "$DOC" "MANUAL-04 statement 'byte-identical end state' must be present"

# Reference to the CI enforcement mechanism
if ! grep -q 'setup-parity\.yml' "$DOC" && ! grep -q 'test_canonical_byte_equality' "$DOC"; then
    echo "ASSERT FAIL: manual-setup.md must reference either setup-parity.yml or test_canonical_byte_equality (CI enforcement of MANUAL-04)" >&2
    exit 1
fi

echo "PASS: manual-setup.md states byte-identical equivalence and cites CI enforcement (MANUAL-04)"
exit 0
