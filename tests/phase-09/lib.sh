#!/usr/bin/env bash
# tests/phase-09/lib.sh -- Phase 9 shared test helpers.
# Source this from tests/phase-09/test_*.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"

# Repo root (run-from-anywhere-safe).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

# make_fixture_repo <fixture-name>  -> prints path to a fresh temp repo
# Copies tests/phase-09/fixtures/<fixture-name>/ into a mktemp dir,
# runs `git init -q`, seeds one commit with the copied files, echoes the path.
make_fixture_repo() {
    local fixture="$1"
    local src="$REPO_ROOT/tests/phase-09/fixtures/$fixture"
    if [ ! -d "$src" ]; then
        echo "ERROR: fixture not found: $src" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp -d -t phase09-fixture-XXXXXX)"
    # Copy all non-README content (README.md is documentation of the fixture, not part of the repo under test)
    (cd "$src" && find . -type f ! -name README.md -print0) | while IFS= read -r -d '' f; do
        mkdir -p "$tmp/$(dirname "$f")"
        cp "$src/$f" "$tmp/$f"
    done
    (cd "$tmp" && git init -q -b main && git config user.email "fixture@example.com" && git config user.name "Fixture" && git add -A && git -c commit.gpgsign=false commit -q --allow-empty -m "fixture seed")
    echo "$tmp"
}

# setup_git_author <repo-path> <name> <email>
# Adds one commit as that author (for multi-author fixtures).
# Uses a UNIQUE per-call filename (email-sanitized + nanoseconds + RANDOM) to
# avoid the collision Codex LOW flagged with the prior `.ts` scheme.
setup_git_author() {
    local repo="$1" name="$2" email="$3"
    local email_slug
    email_slug="$(printf '%s' "$email" | tr '[:upper:]@.+' 'a-z___')"
    # Nanoseconds + RANDOM makes collision in a tight loop effectively impossible.
    local stamp=".author-${email_slug}-$(date +%s%N 2>/dev/null || date +%s)-${RANDOM}.seed"
    (cd "$repo" && git config user.name "$name" && git config user.email "$email" \
        && printf '%s\n' "$email" > "$stamp" \
        && git add "$stamp" \
        && git -c commit.gpgsign=false commit -q -m "author: $name" --author="$name <$email>")
}

# seed_origin_main_ref <repo-path>
# Stages a canonical `refs/remotes/origin/main` ref pointing at the current
# `main` branch so Plan 09-03's --strict tests can exercise
# `git diff --name-status origin/main...HEAD` without each test reinventing
# branch/remote setup (Codex MEDIUM review concern).
#
# Usage (inside a test, after make_fixture_repo and any branch setup):
#   seed_origin_main_ref "$FIXTURE"
#   # Now `git diff --name-status origin/main...HEAD` works inside $FIXTURE.
#
# Assumes the caller has already set up a `main` branch (make_fixture_repo's
# `git init -b main` above establishes this). If the repo's primary branch has
# been renamed, the helper defers to `refs/heads/main` first, then falls back
# to the current HEAD branch name.
seed_origin_main_ref() {
    local repo="$1"
    if [ ! -d "$repo/.git" ]; then
        echo "ERROR: seed_origin_main_ref: $repo is not a git repo" >&2
        return 1
    fi
    local primary
    # Prefer refs/heads/main; fall back to current branch name
    if (cd "$repo" && git show-ref --verify --quiet refs/heads/main); then
        primary="refs/heads/main"
    else
        local cur
        cur="$(cd "$repo" && git symbolic-ref --short HEAD 2>/dev/null || echo main)"
        primary="refs/heads/$cur"
    fi
    (cd "$repo" && git update-ref refs/remotes/origin/main "$primary" \
        && git update-ref refs/remotes/origin/HEAD "$primary")
}

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2
        return 1
    fi
}

# assert_json_has_finding <json-file> <category> <severity>
# Uses python3 to parse. Exits 0 if matching finding exists, 1 otherwise.
assert_json_has_finding() {
    local json="$1" cat="$2" sev="$3"
    python3 - "$json" "$cat" "$sev" <<'PYEOF'
import json, sys
f = sys.argv[1]; cat = sys.argv[2]; sev = sys.argv[3]
data = json.load(open(f))
for item in data:
    if item.get('category') == cat and item.get('severity') == sev:
        sys.exit(0)
print(f"FAIL: no finding with category={cat} severity={sev} in {f}", file=sys.stderr)
print(f"Findings present: {[(i.get('severity'),i.get('category')) for i in data]}", file=sys.stderr)
sys.exit(1)
PYEOF
}

# cleanup_fixture_repo <path>  -- safe rm -rf of a mktemp dir
cleanup_fixture_repo() {
    local path="$1"
    if [ -n "$path" ] && [ -d "$path" ] && [[ "$path" == /tmp/* ]]; then
        rm -rf "$path"
    fi
}

export -f make_fixture_repo setup_git_author seed_origin_main_ref assert_exit_code assert_json_has_finding cleanup_fixture_repo
