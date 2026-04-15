#!/usr/bin/env bash
# test_sync_claude_hook_roundtrip.sh -- Phase 07 Plan 03 (REVIEWS.md HIGH #2)
# Asserts: after mutating CLAUDE.md and invoking the pre-commit hook,
# CLAUDE.md is restored to byte-identical with AGENTS.md (hook path correctness).
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

# Snapshot the canonical state
cp AGENTS.md /tmp/agents.bak
cp CLAUDE.md /tmp/claude.bak

restore() {
  cp /tmp/agents.bak AGENTS.md
  cp /tmp/claude.bak CLAUDE.md
  rm -f /tmp/agents.bak /tmp/claude.bak
}

# Introduce drift
printf '\n# drift marker\n' >> CLAUDE.md
if cmp -s AGENTS.md CLAUDE.md; then
  echo "FAIL: drift injection did not take effect"
  restore
  exit 1
fi

# Run the hook (expected: exits non-zero, but auto-syncs CLAUDE.md as a side effect).
# We must NOT let `git add` inside the hook interfere with the user's actual index.
# So we run the hook in a subshell with GIT_INDEX_FILE pointed at a throwaway index.
TMP_INDEX=$(mktemp)
trap 'rm -f "$TMP_INDEX"' EXIT
# Seed the throwaway index from HEAD so `git add` has a valid index to write to.
GIT_INDEX_FILE="$TMP_INDEX" git read-tree HEAD 2>/dev/null || true
GIT_INDEX_FILE="$TMP_INDEX" bash .githooks/pre-commit >/dev/null 2>&1 || true

# After hook run, CLAUDE.md MUST be byte-identical to AGENTS.md
if ! cmp -s AGENTS.md CLAUDE.md; then
  echo "FAIL: after hook path, CLAUDE.md still differs from AGENTS.md"
  diff AGENTS.md CLAUDE.md | head -20
  restore
  exit 1
fi

restore
echo "PASS: hook-path roundtrip produces byte-identical CLAUDE.md"
exit 0
