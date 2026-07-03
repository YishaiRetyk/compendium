#!/usr/bin/env bash
# Covers: SKILL-02 -- --check exits 0 clean, exits 1 on drift
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
cd "$REPO_ROOT"  # REVIEW WR-02: generator + restore trap write cwd-relative; pin to repo root
[ -f "$REPO_ROOT/bin/gen-skills.sh" ] || { echo "SKIP"; exit 1; }   # noqa: direct-bin (shim-file existence check)

# Always restore committed skill files on exit, even on early abort, so the working tree
# is never left drifted (idempotent cleanup).
trap 'bash "$REPO_ROOT/bin/gen-skills.sh" >/dev/null 2>&1 || true' EXIT   # noqa: direct-bin (live-repo state-dependent — mutates the real .claude/skills; the worktree oracle cannot see it)

# Ensure files generated
bash "$REPO_ROOT/bin/gen-skills.sh"   # noqa: direct-bin (live-repo state-dependent — mutates the real .claude/skills; the worktree oracle cannot see it)

# Clean check should exit 0 -- capture rc without tripping set -e.
bash "$REPO_ROOT/bin/gen-skills.sh" --check && rc=0 || rc=$?   # noqa: direct-bin (live-repo state-dependent — mutates the real .claude/skills; the worktree oracle cannot see it)
assert_exit_code 0 "$rc" "--check exits 0 on clean tree"

# Inject drift into one SKILL.md, then --check MUST exit 1.
echo "INJECTED DRIFT LINE" >> "$REPO_ROOT/.claude/skills/ingest/SKILL.md"
bash "$REPO_ROOT/bin/gen-skills.sh" --check >/dev/null 2>&1 && rc=0 || rc=$?   # noqa: direct-bin (live-repo state-dependent — mutates the real .claude/skills; the worktree oracle cannot see it)
assert_exit_code 1 "$rc" "--check exits 1 on drift"

# Explicit restore (trap is the backstop).
bash "$REPO_ROOT/bin/gen-skills.sh"   # noqa: direct-bin (live-repo state-dependent — mutates the real .claude/skills; the worktree oracle cannot see it)
echo "PASS: --check exits 0 clean, 1 on drift"
