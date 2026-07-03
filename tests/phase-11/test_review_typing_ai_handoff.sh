#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_review_typing_ai_handoff.sh — BRWN-22: large-batch
# (≥20 clusters) review-typing writes an AI-handoff prompt to
# .brownfield/review-typing-prompt.md rather than blocking on TTY input.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo large-vault-ambiguous)
trap 'rm -rf "$TMP"' EXIT

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

# No stdin — force the AI-handoff path via cluster-count threshold.
if ! invoke_tool_compat brownfield review-typing --root "$TMP" </dev/null >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh review-typing not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi

PROMPT="$TMP/.brownfield/review-typing-prompt.md"
assert_file_exists "$PROMPT"

assert_grep "Edit ONLY the decisions manifest. Do not modify vault pages." "$PROMPT" \
    "AI-handoff directive phrase missing from prompt"
assert_grep "bash .brownfield/migrations/01-page-typing.sh --apply" "$PROMPT" \
    "run-command missing from prompt"

echo "PASS $NAME"; exit 0
