#!/usr/bin/env bash
# EXPECTED_BY: 11-05
# tests/phase-11/test_docs_rollback_git_reset_recipe.sh — BRWN-19:
# docs/reference/brownfield.md documents `git reset` as the canonical undo
# path. Asserts a `git reset --hard` recipe appears within ~30 lines of the
# `## Rollback` heading. Phase-10 test_brownfield_docs_populated.sh only
# verifies the heading exists; this test verifies the recipe content.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
NAME="$(basename "${BASH_SOURCE[0]}")"

DOC="$REPO_ROOT/docs/reference/brownfield.md"
assert_file_exists "$DOC"

python3 - "$DOC" <<'PYEOF' || exit 1
import sys, pathlib
text = pathlib.Path(sys.argv[1]).read_text().splitlines()
rollback_idx = None
for i, line in enumerate(text):
    if line.startswith("## Rollback"):
        rollback_idx = i
        break
if rollback_idx is None:
    print("FAIL: docs/reference/brownfield.md missing '## Rollback' heading", file=sys.stderr)
    sys.exit(1)
window = "\n".join(text[rollback_idx:rollback_idx+40])
if "git reset --hard" not in window:
    print("FAIL: '## Rollback' section does not contain 'git reset --hard' recipe within 40 lines", file=sys.stderr)
    sys.exit(1)
sys.exit(0)
PYEOF

echo "PASS $NAME"; exit 0
