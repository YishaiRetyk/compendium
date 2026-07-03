#!/usr/bin/env bash
# tests/phase-15/lib.sh -- Phase 15 test helpers.
# The four core helpers (make_bare_repo, assert_exit_code, cleanup_fixture_repo,
# write_page) are copied VERBATIM from tests/phase-13/lib.sh (mktemp prefix
# bumped to phase15-). The three verifier helpers are NOT included here --
# Phase 15 tests do not need the audit-specific verifier stubs.
#
# Source this from tests/phase-15/test_*.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"

set -euo pipefail

# Repo root (run-from-anywhere-safe). Lets tests invoke $REPO_ROOT/bin/...
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

# make_bare_repo  -> prints path to a fresh temp repo seeded with one empty commit.
# Tests build their fixture page-shape inline via write_page (no fixtures/ dir needed).
make_bare_repo() {
    local tmp
    tmp="$(mktemp -d -t phase15-XXXXXX)"
    (cd "$tmp" && git init -q -b main && \
        git config user.email "fixture@example.com" && \
        git config user.name "Fixture" && \
        git -c commit.gpgsign=false commit -q --allow-empty -m "seed")
    echo "$tmp"
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
# Used to build fixtures inline: wiki-cloud/ and wiki-local/ pages.
write_page() {
    local repo="$1" relpath="$2"
    local dir="$repo/$(dirname "$relpath")"
    mkdir -p "$dir"
    # Body is read from stdin (heredoc).
    cat > "$repo/$relpath"
}

export -f make_bare_repo assert_exit_code cleanup_fixture_repo write_page
