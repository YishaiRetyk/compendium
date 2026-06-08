#!/usr/bin/env bash
# Covers: SKILL-02 -- SKILL.md files are tracked by git (not gitignored)
# Tests the .gitignore fix from Plan 00 Task 1.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Clean up the temp stub on ANY exit (REVIEWS.md MEDIUM: no stray .claude/skills/ingest/SKILL.md
# left in the real working tree if the test aborts early). Only remove the stub dir if it was
# created by THIS test (it does not exist before Plan 01 generates the real files); guard with a
# marker so we never delete the real generated tree after Plan 01.
STUB_CREATED=0
cleanup() {
    [ "$STUB_CREATED" -eq 1 ] && rm -f "$REPO_ROOT/.claude/skills/ingest/SKILL.md" 2>/dev/null || true
    [ "$STUB_CREATED" -eq 1 ] && rmdir "$REPO_ROOT/.claude/skills/ingest" "$REPO_ROOT/.claude/skills" 2>/dev/null || true
    return 0
}
trap cleanup EXIT

cd "$REPO_ROOT"
# Only create a stub if the file does not already exist (after Plan 01 it WILL exist and is real).
if [ ! -e ".claude/skills/ingest/SKILL.md" ]; then
    mkdir -p ".claude/skills/ingest"
    touch ".claude/skills/ingest/SKILL.md"
    STUB_CREATED=1
fi

# git check-ignore exits 0 if IGNORED, non-zero if NOT ignored (trackable). Capture rc WITHOUT
# tripping set -e (REVIEWS.md HIGH verified: a bare non-zero command aborts before rc=$? runs).
git check-ignore ".claude/skills/ingest/SKILL.md" >/dev/null 2>&1 && rc=0 || rc=$?
if [ "$rc" -eq 0 ]; then
    echo "FAIL: .claude/skills/ingest/SKILL.md is gitignored (check .gitignore negations)"
    exit 1
fi
echo "PASS: .claude/skills/ingest/SKILL.md is NOT gitignored (trackable)"
