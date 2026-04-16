#!/usr/bin/env bash
# test_gitignore.sh — asserts .gitignore covers all four required categories.
set -euo pipefail

FAIL=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAIL=1; }

ROOT="${ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
cd "$ROOT"

if [ ! -f .gitignore ]; then
  fail ".gitignore missing"
  exit 1
fi

check() {
  local pat="$1" label="$2"
  if grep -q "$pat" .gitignore; then pass "$label"; else fail "$label"; fi
}

check '^\.obsidian/workspace' ".gitignore: .obsidian/workspace*"
check '^\.obsidian/cache'     ".gitignore: .obsidian/cache"
check '^\.trash/'             ".gitignore: .trash/"
check '^\.brownfield/'        ".gitignore: .brownfield/"
# Note: .planning/ is intentionally NOT ignored. bin/release.sh ALLOWLIST
# staging is the single source of truth for keeping .planning/ out of the
# public template; see .planning/notes/2026-04-16-planning-dir-git-asymmetry.md.
# Regression against that invariant is caught by test_release_allowlist.sh.
check '^\.DS_Store'           ".gitignore: .DS_Store"
check '^Thumbs\.db'           ".gitignore: Thumbs.db"
check '^\*\.swp'              ".gitignore: *.swp"
check '^\.idea/'              ".gitignore: .idea/"
check '^\.vscode/'            ".gitignore: .vscode/"

exit "$FAIL"
