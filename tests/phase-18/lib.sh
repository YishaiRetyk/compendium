# tests/phase-18/lib.sh -- Phase 18 test helpers.
# Source this from tests/phase-18/test_*.sh:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib.sh"
#
# NOTE: Only the two helpers actually used by the phase-18 suite are included.
# Phase-18 tests run against the real repo tree (not bare-repo fixtures), so the
# phase-15 make_bare_repo / cleanup_fixture_repo / write_page helpers are dead
# code here and are intentionally omitted (REVIEWS.md LOW).

# Repo root (run-from-anywhere-safe). Lets tests invoke $REPO_ROOT/bin/...
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # Phase 24 Plan 05: the frozen parity seam

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $desc (expected exit=$expected, got $actual)" >&2
        return 1
    fi
}

export -f assert_exit_code
