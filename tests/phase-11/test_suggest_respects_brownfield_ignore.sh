#!/usr/bin/env bash
# EXPECTED_BY: 11-02
# tests/phase-11/test_suggest_respects_brownfield_ignore.sh — REVIEWS item 3.
# Using repo-root-shape-vault (with docs/, schema/, examples/, AGENTS.md, etc.
# at the vault root + a .brownfield-ignore), assert suggest's scan scope
# respects .brownfield-ignore: ONLY wiki/concepts/foo.md appears in
# page-typing-candidates.yaml; no control-plane files leak in.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP_REPO=$(make_fixture_repo repo-root-shape-vault)
trap 'rm -rf "$TMP_REPO"' EXIT

if ! invoke_tool_compat brownfield suggest --root "$TMP_REPO" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

CANDS="$TMP_REPO/.brownfield/page-typing-candidates.yaml"
assert_file_exists "$CANDS"

# Must find exactly ONE wiki/concepts/foo.md entry
count=$(grep -cE 'path:[[:space:]]*wiki/concepts/foo\.md' "$CANDS" || true)
if [ "$count" != "1" ]; then
    echo "FAIL: expected exactly 1 wiki/concepts/foo.md entry in candidates, got $count" >&2
    exit 1
fi

# Must NOT contain any control-plane paths
for forbidden in "AGENTS.md" "CLAUDE.md" "README.md" "docs/" "schema/" "examples/" ".github/"; do
    if grep -qE "path:[[:space:]]*.*${forbidden}" "$CANDS"; then
        echo "FAIL: $forbidden appeared in candidates despite .brownfield-ignore" >&2
        exit 1
    fi
done

echo "PASS $NAME"; exit 0
