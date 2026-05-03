#!/usr/bin/env bash
# tests/phase-12.2/lib.sh -- Phase 12.2 test helpers (subset of tests/phase-09/lib.sh; staged-mode is origin-independent per D-19, so the origin/main-ref seeding helper is intentionally omitted).
# Source this from tests/phase-12.2/test_*.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"

set -euo pipefail

# Repo root (run-from-anywhere-safe).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# make_bare_repo  -> prints path to a fresh temp repo seeded with one empty commit.
# Phase 12.2 substitutes phase-09's make_fixture_repo with this simpler helper:
# tests build their fixture page-shape inline via write_page (no fixtures/ dir needed).
make_bare_repo() {
    local tmp
    tmp="$(mktemp -d -t phase12-2-XXXXXX)"
    (cd "$tmp" && git init -q -b main && \
        git config user.email "fixture@example.com" && \
        git config user.name "Fixture" && \
        git -c commit.gpgsign=false commit -q --allow-empty -m "seed")
    echo "$tmp"
}

# setup_git_author <repo-path> <name> <email>
# Adds one commit as that author (for multi-author fixtures).
# Uses a UNIQUE per-call filename (email-sanitized + nanoseconds + RANDOM) to
# avoid collisions in tight loops.
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

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2
        return 1
    fi
}

# cleanup_fixture_repo <path>  -- safe rm -rf of a mktemp dir
cleanup_fixture_repo() {
    local path="$1"
    if [ -n "$path" ] && [ -d "$path" ] && [[ "$path" == /tmp/* ]]; then
        rm -rf "$path"
    fi
}

# write_page <repo> <relpath>
# Reads body from stdin (heredoc), creates parent dirs, writes to "$repo/$relpath".
# Tests use this to build fixture wiki pages inline without needing a fixtures/ dir.
write_page() {
    local repo="$1" relpath="$2"
    local dir="$repo/$(dirname "$relpath")"
    mkdir -p "$dir"
    # Body is read from stdin (heredoc).
    cat > "$repo/$relpath"
}

export -f make_bare_repo setup_git_author assert_exit_code cleanup_fixture_repo write_page
