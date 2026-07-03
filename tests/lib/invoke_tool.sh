# tests/lib/invoke_tool.sh — direct tool-invocation + footprint-capture seam.
#
# Post-migration (Phase 26 / 26-02): the frozen-bash parity oracle is RETIRED — there is
# ONE implementation (Python behind the `bin/<tool>.sh` shims). `invoke_tool` runs that
# shim directly; the WIKI_IMPL branch, the git-worktree oracle, `ported.manifest`, and the
# cross-run channel-capture machinery are gone. The footprint helpers survive because the
# phase-24 characterization goldens still byte-assert the shipped tool's 4 channels.
#
# Usage:  invoke_tool <tool> [args...]   # <tool> = bare name, e.g. "lint"
# Sets:   IT_STDOUT IT_STDERR (paths) and IT_EXIT (value).  ALWAYS returns 0.
# Call-site idiom (set -e-safe):  invoke_tool X ARGS ; rc=$IT_EXIT
_IT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_IT_REPO_ROOT="$(cd "$_IT_DIR/../.." && pwd)"
# shellcheck source=/dev/null
. "$_IT_DIR/normalize.sh"

# capture_footprint <repo-dir> <case-dir> — 4-channel snapshot into a CASE DIRECTORY.
# Writes <case-dir>/{stdout,stderr,exit,tree}. The tree manifest records file TYPE + MODE +
# symlink target + empty dirs (generated-script executability is observable behavior). The
# tree is snapshotted over per-test FIXTURE roots only; a live-repo footprint root (the
# PWD-fallback class) gets a fixed placeholder — hashing the whole working tree is neither
# meaningful nor deterministic, and each tool's write behavior is owned by its fixture tests.
capture_footprint() {
    local repo="$1" casedir="$2"
    mkdir -p "$casedir"
    normalize < "$IT_STDOUT" > "$casedir/stdout"
    normalize < "$IT_STDERR" > "$casedir/stderr"
    printf '%s\n' "$IT_EXIT" > "$casedir/exit"
    if [ ! -d "$repo" ]; then
        printf 'tree channel unavailable: footprint root missing\n' > "$casedir/tree"
        return 0
    fi
    if [ "$(cd "$repo" && pwd)" = "$_IT_REPO_ROOT" ]; then
        printf 'tree channel skipped: live-repo footprint root (not a per-test fixture)\n' > "$casedir/tree"
        return 0
    fi
    # File hashes are computed over NORMALIZED content (same treatment as the stdout/stderr
    # channels), because written artifacts embed second-granularity run stamps; raw hashing
    # made the tree channel diverge across any two runs minutes apart. __pycache__/.pytest_cache
    # are generated caches (mtime-bearing .pyc bytes), pruned like .git.
    ( cd "$repo" && find . \( -path './.git' -o -name '__pycache__' -o -name '.pytest_cache' \) -prune -o -print 2>/dev/null \
        | LC_ALL=C sort \
        | while IFS= read -r e; do
              [ "$e" = "." ] && continue
              if [ -L "$e" ]; then
                  printf 'L %s -> %s\n' "$e" "$(readlink "$e")"
              elif [ -d "$e" ]; then
                  printf 'D %s %s\n' "$(stat -c '%a' "$e")" "$e"   # empty dirs recorded too
              elif [ -f "$e" ]; then
                  printf 'F %s %s  %s\n' "$(stat -c '%a' "$e")" \
                      "$(normalize < "$e" | sha256sum | cut -d' ' -f1)" "$e"   # MODE captures exec bit
              fi
          done ) > "$casedir/tree"
}

# assert_parity <expected-case-dir> <actual-case-dir> — all 4 channels byte-equal.
assert_parity() { for ch in stdout stderr exit tree; do
    cmp -s "$1/$ch" "$2/$ch" || { echo "PARITY DIFF ($ch)"; diff "$1/$ch" "$2/$ch"; return 1; }
done; }

# invoke_tool <tool> [args...] — run bin/<tool>.sh (the shim → python) directly.
invoke_tool() {
    local tool="$1"; shift
    IT_STDOUT="$(mktemp)"; IT_STDERR="$(mktemp)"
    # set -e-SAFE exit capture: if/then/else protects the caller, THEN return 0 so the
    # `invoke_tool X; rc=$IT_EXIT` idiom reaches rc even when the tool exits nonzero.
    # LC_ALL/TZ/PYTHONPATH pinned for hermetic, deterministic tool output.
    if LC_ALL=C TZ=UTC PYTHONPATH="$_IT_REPO_ROOT/src${PYTHONPATH:+:$PYTHONPATH}" \
         bash "$_IT_REPO_ROOT/bin/${tool}.sh" "$@" >"$IT_STDOUT" 2>"$IT_STDERR"; then
        IT_EXIT=0
    else
        IT_EXIT=$?
    fi
    return 0    # ALWAYS 0 — status is exposed ONLY via $IT_EXIT
}

# invoke_tool_compat <tool> [args...] — DIRECT-CALL-SEMANTICS wrapper: payload on stdout,
# diagnostics on stderr, the tool's own exit status. Used by the pre-existing suites' call
# sites (if-conditions, ||-lists, command substitutions) whose assertions expect that contract.
invoke_tool_compat() {
    invoke_tool "$@"
    cat "$IT_STDOUT"
    cat "$IT_STDERR" >&2
    return "$IT_EXIT"
}
export -f capture_footprint assert_parity invoke_tool invoke_tool_compat
