#!/usr/bin/env bash
# EXPECTED_BY: 11-01
# tests/phase-11/test_migration_script_names.sh — D-07 rename lock (BRWN-12).
# Assert the four canonical migration scripts exist with exact names, and
# that no 04-privacy-classification.sh (the pre-rename name) lingers.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

CANON_DIR="$REPO_ROOT/schema/brownfield/migrations"

# Assert exactly 4 .sh files
count=$(find "$CANON_DIR" -maxdepth 1 -name '*.sh' -type f | wc -l)
if [ "$count" != "4" ]; then
    echo "FAIL: expected exactly 4 .sh files in $CANON_DIR, found $count" >&2
    exit 1
fi

# Assert each exact name exists
for name in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
    assert_file_exists "$CANON_DIR/$name" "missing canonical script: $name"
done

# Assert the pre-rename name is absent
if [ -e "$CANON_DIR/04-privacy-classification.sh" ]; then
    echo "FAIL: pre-rename 04-privacy-classification.sh found under $CANON_DIR (D-07 rename not applied)" >&2
    exit 1
fi

# Also assert it doesn't lurk inside any .brownfield/migrations/ in the repo.
STRAY=$(find "$REPO_ROOT" -path '*/.brownfield/migrations/04-privacy-classification.sh' 2>/dev/null || true)
if [ -n "$STRAY" ]; then
    echo "FAIL: stray 04-privacy-classification.sh files found:" >&2
    echo "$STRAY" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
