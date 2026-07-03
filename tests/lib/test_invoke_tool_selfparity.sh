#!/usr/bin/env bash
# Seam self-test (Pitfall 3 / D-13 baseline attribution): under WIKI_IMPL=bash, the seam's
# captured channels are byte-identical (un-normalized) to a DIRECT call of the same oracle
# script with the same pinned env — the seam must not alter bytes.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }

check_selfparity() {
    local tool="$1"; shift
    WIKI_IMPL=bash invoke_tool "$tool" "$@"
    local s_out="$IT_STDOUT" s_err="$IT_STDERR" s_rc="$IT_EXIT"
    local d_out d_err d_rc
    d_out="$(mktemp)"; d_err="$(mktemp)"
    if LC_ALL=C TZ=UTC PYTHONPATH="$(_oracle_exec_root)/src${PYTHONPATH:+:$PYTHONPATH}" \
         bash "$(oracle_tool_path "$tool")" "$@" >"$d_out" 2>"$d_err"; then
        d_rc=0
    else
        d_rc=$?
    fi
    cmp -s "$s_out" "$d_out" || fail "$tool $*: seam stdout differs from direct call"
    cmp -s "$s_err" "$d_err" || fail "$tool $*: seam stderr differs from direct call"
    [ "$s_rc" = "$d_rc" ] || fail "$tool $*: seam exit $s_rc != direct exit $d_rc"
    echo "ok: $tool $* — seam byte-identical to direct call (exit $s_rc)"
}

check_selfparity lint --help
check_selfparity validate-op            # no args -> usage path (nonzero exit)
check_selfparity search --paths-only    # missing-arg/usage path

echo "PASS: seam is byte-transparent under WIKI_IMPL=bash"
