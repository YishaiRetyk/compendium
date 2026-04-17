#!/usr/bin/env bash
# tests/phase-10/test_claude_sync_byte_equal.sh
# Phase 10 Plan 04 — asserts CLAUDE.md is byte-equal to AGENTS.md (TMPL-10/D-03).
# Replicates at test-time the pre-commit-hook guarantee so CI catches drift
# without relying on hook execution. On failure, prints the regeneration recipe.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

agents="$REPO_ROOT/AGENTS.md"
claude="$REPO_ROOT/CLAUDE.md"
[ -f "$agents" ] || { echo "FAIL: AGENTS.md missing at $agents" >&2; exit 1; }
[ -f "$claude" ] || { echo "FAIL: CLAUDE.md missing at $claude" >&2; exit 1; }

if ! cmp -s "$agents" "$claude"; then
    echo "FAIL: CLAUDE.md drift detected (AGENTS.md != CLAUDE.md)" >&2
    echo "" >&2
    echo "Regenerate with:" >&2
    echo "  bash bin/sync-claude.sh && git add CLAUDE.md" >&2
    echo "" >&2
    echo "--- diff (first 20 lines) ---" >&2
    diff -u "$agents" "$claude" | head -20 >&2 || true
    exit 1
fi

echo "PASS: AGENTS.md == CLAUDE.md (byte-equal)"
