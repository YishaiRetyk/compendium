#!/usr/bin/env bash
# tests/phase-11/lib.sh -- Phase 11 shared test helpers.
# Sourced by tests/phase-11/test_*.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"
#
# Clones Phase 10's helper set with 10->11 rename + a new canonical-byte-equality
# helper (assert_canonical_scripts_byte_identical) used by Plan 11-02's byte-
# copy invariant tests.

# Repo root (run-from-anywhere-safe).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

# make_fixture_repo <fixture-name>  -> prints path to a fresh temp repo
# Copies tests/phase-11/fixtures/<fixture-name>/input/ into a mktemp dir,
# runs `git init -q -b main`, seeds one commit with the copied files, echoes
# the path.  Excludes per-fixture README.md files (they document the fixture,
# they are not part of the repo under test).
make_fixture_repo() {
    local fixture="$1"
    local src="$REPO_ROOT/tests/phase-11/fixtures/$fixture/input"
    if [ ! -d "$src" ]; then
        echo "ERROR: fixture not found: $src" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp -d -t phase11-fixture-XXXXXX)"
    # Copy all non-README content (README.md documents the fixture, not the repo under test).
    (cd "$src" && find . -type f ! -name README.md -print0) | while IFS= read -r -d '' f; do
        mkdir -p "$tmp/$(dirname "$f")"
        cp "$src/$f" "$tmp/$f"
    done
    (cd "$tmp" && git init -q -b main && git config user.email "fixture@example.com" && git config user.name "Fixture" && git add -A && git -c commit.gpgsign=false commit -q --allow-empty -m "fixture seed")
    echo "$tmp"
}

# assert_byte_equal <expected_file> <actual_file> [message]
# Byte-exact file comparison with regeneration-recipe on failure.  When the
# two files differ, prints a unified diff (first 50 lines) and exits 1.
assert_byte_equal() {
    local expected="$1" actual="$2" msg="${3:-files differ}"
    if ! cmp -s "$expected" "$actual"; then
        echo "ASSERT FAIL: $msg" >&2
        echo "--- diff (first 50 lines) ---" >&2
        diff -u "$expected" "$actual" | head -50 >&2 || true
        echo "" >&2
        echo "To regenerate expected/ fixtures after Plan 11 ships:" >&2
        echo "  bash bin/brownfield.sh suggest <fixture-input-dir>" >&2
        echo "  bash <fixture-input-dir>/.brownfield/migrations/<script> --apply" >&2
        echo "  cp <produced-file> tests/phase-11/fixtures/<name>/expected/<file>" >&2
        echo "See tests/phase-11/fixtures/README.md for the full regeneration recipe." >&2
        exit 1
    fi
}

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2
        return 1
    fi
}

# assert_file_exists <path> [message]
assert_file_exists() {
    local path="$1" msg="${2:-file does not exist}"
    if [ ! -f "$path" ]; then
        echo "ASSERT FAIL: $msg ($path)" >&2
        exit 1
    fi
}

# assert_grep <pattern> <file> [message]
assert_grep() {
    local pattern="$1" file="$2" msg="${3:-pattern not found}"
    if ! grep -q -- "$pattern" "$file"; then
        echo "ASSERT FAIL: $msg (pattern: $pattern, file: $file)" >&2
        exit 1
    fi
}

# assert_canonical_scripts_byte_identical <stage_root>
# Compares each of the four canonical migration scripts under
# schema/brownfield/migrations/ against its byte-copy under
# <stage_root>/.brownfield/migrations/.  The compare strips `# op_hash:` and
# `# op_hash_scope:` lines before comparing (per RESEARCH Q2: suggest prepends
# these at copy time; canonical scripts ship WITHOUT them).
#
# Usage: assert_canonical_scripts_byte_identical "$TMP_REPO"
assert_canonical_scripts_byte_identical() {
    local stage_root="$1"
    local script
    for script in 01-page-typing.sh 02-provenance-bootstrap.sh 03-cross-link-inference.sh 04-privacy-review.sh; do
        python3 - "$REPO_ROOT/schema/brownfield/migrations/$script" "$stage_root/.brownfield/migrations/$script" <<'PYEOF' || return 1
import sys, pathlib
canon = pathlib.Path(sys.argv[1]).read_bytes()
copy  = pathlib.Path(sys.argv[2]).read_bytes()
def strip(b):
    return b"\n".join(ln for ln in b.split(b"\n")
                      if not ln.startswith(b"# op_hash:")
                      and not ln.startswith(b"# op_hash_scope:"))
if strip(canon) != strip(copy):
    print(f"FAIL: canonical drift on {sys.argv[2].split('/')[-1]}", file=sys.stderr)
    sys.exit(1)
PYEOF
    done
    return 0
}

export -f make_fixture_repo assert_byte_equal assert_exit_code assert_file_exists assert_grep assert_canonical_scripts_byte_identical
