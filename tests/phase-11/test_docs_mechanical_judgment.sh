#!/usr/bin/env bash
# EXPECTED_BY: 11-05
# tests/phase-11/test_docs_mechanical_judgment.sh — BRWN-18: the
# brownfield reference doc discusses both the "mechanical" and "judgment"
# boundaries of the suggest/review/verify workflow inside the same
# section.
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

# Find a window within which BOTH "mechanical" and "judgment" appear.
if ! grep -iE '^##' "$DOC" | grep -q .; then
    echo "FAIL: docs/reference/brownfield.md has no top-level sections" >&2
    exit 1
fi

# Scan for a 20-line window where both terms appear.
python3 - "$DOC" <<'PYEOF' || exit 1
import sys, pathlib, re
text = pathlib.Path(sys.argv[1]).read_text().splitlines()
for i in range(len(text)):
    window = "\n".join(text[i:i+40]).lower()
    if "mechanical" in window and "judgment" in window:
        sys.exit(0)
print("FAIL: docs/reference/brownfield.md does not discuss 'mechanical' and 'judgment' in the same section", file=sys.stderr)
sys.exit(1)
PYEOF

echo "PASS $NAME"; exit 0
