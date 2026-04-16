#!/usr/bin/env bash
# tests/phase-08/lib.sh -- Shared bash helpers for Phase 08 tests.
# Sourced by tests/phase-08/test_*.sh; do not execute directly.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Registry of tempdirs to clean on exit.
TEMP_DIRS=()

mktemp_repo() {
    local d
    d="$(mktemp -d)"
    TEMP_DIRS+=("$d")
    echo "$d"
}

cleanup_tempdirs() {
    local d
    for d in "${TEMP_DIRS[@]:-}"; do
        if [ -n "$d" ] && [ -d "$d" ]; then
            rm -rf "$d"
        fi
    done
}

assert_eq() {
    # assert_eq <expected> <actual> <message>
    local expected="$1" actual="$2" msg="${3:-}"
    if [ "$expected" != "$actual" ]; then
        echo "ASSERT FAIL: $msg (expected: $expected / got: $actual)" >&2
        exit 1
    fi
}

assert_grep() {
    # assert_grep <pattern> <file> <message>
    local pattern="$1" file="$2" msg="${3:-}"
    if ! grep -qE "$pattern" "$file"; then
        echo "ASSERT FAIL: $msg (pattern not found: $pattern in $file)" >&2
        exit 1
    fi
}

assert_no_grep() {
    # assert_no_grep <pattern> <file> <message>
    local pattern="$1" file="$2" msg="${3:-}"
    if grep -qE "$pattern" "$file"; then
        echo "ASSERT FAIL: $msg (pattern unexpectedly found: $pattern in $file)" >&2
        exit 1
    fi
}

assert_file_exists() {
    # assert_file_exists <path> [message]
    local path="$1" msg="${2:-file does not exist}"
    if [ ! -f "$path" ]; then
        echo "ASSERT FAIL: $msg ($path)" >&2
        exit 1
    fi
}

assert_byte_equal() {
    # assert_byte_equal <expected_file> <actual_file> [message]
    local expected="$1" actual="$2" msg="${3:-files differ}"
    if ! cmp -s "$expected" "$actual"; then
        echo "ASSERT FAIL: $msg" >&2
        echo "--- diff (first 50 lines) ---" >&2
        diff -u "$expected" "$actual" | head -50 >&2 || true
        exit 1
    fi
}

trap 'cleanup_tempdirs' EXIT INT TERM
