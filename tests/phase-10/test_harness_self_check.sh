#!/usr/bin/env bash
# tests/phase-10/test_harness_self_check.sh
# Wave-1 smoke test: asserts the harness helpers themselves behave correctly
# (REPO_ROOT resolution, assert_byte_equal on identical files, make_fixture_repo).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# 1. REPO_ROOT resolves to a git repo (accepts both .git directory and .git file-
#    pointer used by git worktrees, where .git is a file containing 'gitdir: ...'
#    rather than a directory).
[ -e "$REPO_ROOT/.git" ] || { echo "FAIL: REPO_ROOT did not resolve to a git repo root" >&2; exit 1; }

# 2. assert_byte_equal passes on identical files
tmp1=$(mktemp); tmp2=$(mktemp)
printf 'x\n' > "$tmp1"; printf 'x\n' > "$tmp2"
if ! ( assert_byte_equal "$tmp1" "$tmp2" "identical should match" ) 2>/dev/null; then
    echo "FAIL: assert_byte_equal reported difference on identical files" >&2
    rm -f "$tmp1" "$tmp2"
    exit 1
fi
rm -f "$tmp1" "$tmp2"

# 3. make_fixture_repo spawns a working temp repo from a known-good fixture
tmp=$(make_fixture_repo clean-frontmatter)
[ -f "$tmp/input/page.md" ] || { echo "FAIL: make_fixture_repo did not copy input/page.md" >&2; rm -rf "$tmp"; exit 1; }
[ -d "$tmp/.git" ] || { echo "FAIL: make_fixture_repo did not git-init" >&2; rm -rf "$tmp"; exit 1; }
rm -rf "$tmp"

echo "OK: harness self-check passed"
