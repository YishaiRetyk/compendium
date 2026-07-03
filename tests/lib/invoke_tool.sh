# tests/lib/invoke_tool.sh — FROZEN shared seam (D-08).
# Usage:  invoke_tool <tool> [args...]   # <tool> = bare name, e.g. "lint"
# Sets:   IT_STDOUT IT_STDERR (paths) and IT_EXIT (value).  ALWAYS returns 0 (REVIEWS HIGH#2).
# Call-site idiom (set -e-safe):  invoke_tool X ARGS ; rc=$IT_EXIT     # rc is reached even if the tool exits nonzero
# BRANCHES on WIKI_IMPL:
#   WIKI_IMPL=bash -> the held-fixed bash oracle: <worktree>/bin/<tool>.sh (oracle_tool_path, full bin/-relative tree) (HIGH#1)
#   WIKI_IMPL=py   -> the bin/<tool>.sh SHIM (which itself execs python3 -m compendium.<tool>) ONLY IF <tool> is in
#                     tests/ported.manifest; else the bash oracle. Running the SHIM (not `python3 -m` directly) puts a
#                     broken shim (bad PYTHONPATH/quoting/module/exec) ON the parity path (cycle-3 HIGH finding #3).
# In Phase 24 ported.manifest is EMPTY, so py falls through to the bash oracle for every tool.
# IT_CAPTURE_DIR (cycle-3 HIGH finding #2 + cycle-4 finding #1): if set, EACH call self-records its normalized
#   channels + a tree snapshot of the fixture root into a COLLISION-PROOF keyed sub-dir
#   $IT_CAPTURE_DIR/<testbasename>-<pid>/<tool>-<NN>/{stdout,stderr,exit,tree}. The <testbasename>-<pid>
#   segment is UNIQUE per calling test-file subprocess (basename of $0 of the running test + this process's PID),
#   so two DIFFERENT test_*.sh files in ONE suite that share ONE IT_CAPTURE_DIR (run-all exports it per suite —
#   Plan 05) and both record their first <tool> call do NOT overwrite a shared <tool>-001 (cycle-4 finding #1 /
#   Codex new-HIGH #1: a bare per-PROCESS counter resets to 0 in each subprocess -> silent overwrite). The per-call
#   counter still disambiguates multiple calls within one test file. This lets a black-box child test process
#   collect per-call routed channels with NO <repo> arg from run-all.
_IT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$_IT_DIR/oracle-worktree.sh"
. "$_IT_DIR/normalize.sh"

# capture_footprint <repo-dir> <case-dir> — 4-channel snapshot into a CASE DIRECTORY (D-11).
# Writes <case-dir>/{stdout,stderr,exit,tree}. The tree manifest records file TYPE + MODE +
# symlink target + empty dirs (generated-script executability is observable behavior).
capture_footprint() {
    local repo="$1" casedir="$2"
    mkdir -p "$casedir"
    # REVIEW FIX: a missing footprint root must not abort the calling test under set -e
    # (only capture runs would die, making failures unreproducible in plain runs). Both
    # legs get the same deterministic placeholder, so parity still pairs.
    if [ ! -d "$repo" ]; then
        normalize < "$IT_STDOUT" > "$casedir/stdout"
        normalize < "$IT_STDERR" > "$casedir/stderr"
        printf '%s\n' "$IT_EXIT" > "$casedir/exit"
        printf 'tree channel unavailable: footprint root missing\n' > "$casedir/tree"
        return 0
    fi
    normalize < "$IT_STDOUT" > "$casedir/stdout"
    normalize < "$IT_STDERR" > "$casedir/stderr"
    printf '%s\n' "$IT_EXIT" > "$casedir/exit"
    # D-09 REBASE (2026-07-03, Phase 25 first live channel-comparison): file hashes are computed
    # over NORMALIZED content (same treatment as the stdout/stderr channels), because written
    # artifacts embed (a) second-granularity wall-clock run stamps and (b) the executing
    # checkout's own root path (oracle worktree vs staged index vs repo) — neither is behavior,
    # and raw hashing made the tree channel diverge across ANY two runs minutes apart (even
    # bash-vs-bash). Phase 24 never hit this: the staged-gate's empty-manifest short-circuit
    # meant the cross-run comparison had never actually executed. normalize is byte-safe here
    # under the seam's LC_ALL=C. __pycache__/.pytest_cache are generated caches (mtime-bearing
    # .pyc bytes), pruned like .git.
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
# assert_parity <bash-case-dir> <py-case-dir> — all 4 channels.
assert_parity() { for ch in stdout stderr exit tree; do
    cmp -s "$1/$ch" "$2/$ch" || { echo "PARITY DIFF ($ch)"; diff "$1/$ch" "$2/$ch"; return 1; }
done; }
export -f capture_footprint assert_parity

_it_is_ported() {                         # is <tool> listed (non-comment, non-blank) in ported.manifest?
    local tool="$1" mf="$(_oracle_exec_root)/tests/ported.manifest"
    [ -f "$mf" ] || return 1
    grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$mf" | grep -qx "$tool"
}

# COLLISION-PROOF per-subprocess discriminator (cycle-4 finding #1): basename of the running test file's $0 +
# this process's PID. Honor IT_CAPTURE_KEY override (run-all / a test may set an explicit key).
_it_capture_key() {
    if [ -n "${IT_CAPTURE_KEY:-}" ]; then printf '%s\n' "$IT_CAPTURE_KEY"; return 0; fi
    local base; base="$(basename "${0:-shell}" .sh)"
    printf '%s-%s\n' "$base" "$$"
}
invoke_tool() {
    local tool="$1"; shift
    local impl="${WIKI_IMPL:-bash}"
    IT_STDOUT="$(mktemp)"; IT_STDERR="$(mktemp)"
    local cmd
    if [ "$impl" = "py" ] && _it_is_ported "$tool"; then
        # FINDING #3: run the ACTUAL shim, NOT python3 -m directly, so a broken shim is caught on the parity path.
        cmd=(bash "$(_oracle_exec_root)/bin/${tool}.sh")
    else
        cmd=(bash "$(oracle_tool_path "$tool")")             # bash leg / unported fallthrough: WORKTREE oracle
    fi
    # set -e-SAFE exit capture: capture into IT_EXIT via if/then/else (protects the child), THEN return 0
    # (REVIEWS HIGH#2 — a `return "$IT_EXIT"` would abort `invoke_tool X; rc=$IT_EXIT` before rc is read).
    # PYTHONPATH/LC_ALL/TZ pinned on the NORMAL lane so the py-via-shim lane inherits the cycle-1 hermeticity
    # (finding #3). NOTE: the dedicated shim-smoke test (cycle-4 finding #3) clears the seam PYTHONPATH to prove
    # the shim owns its OWN bootstrap; the normal lane below KEEPS the export (must_not_regress).
    if LC_ALL=C TZ=UTC PYTHONPATH="$(_oracle_exec_root)/src${PYTHONPATH:+:$PYTHONPATH}" \
         "${cmd[@]}" "$@" >"$IT_STDOUT" 2>"$IT_STDERR"; then
        IT_EXIT=0
    else
        IT_EXIT=$?
    fi
    # FINDING #2 + CYCLE-4 finding #1: per-call self-record into IT_CAPTURE_DIR under a COLLISION-PROOF key, if requested.
    # REVIEW FIX (2026-07-03): the per-call counter is FILESYSTEM-derived (count of existing
    # <tool>-* capture dirs under this key), NOT a shell variable — a shell counter is lost when
    # the call happens inside a command substitution / cd-subshell (the dominant compat shape:
    # `out="$(... invoke_tool_compat tool ...)"`), so every same-tool subshell call re-used -001
    # and silently OVERWROTE earlier captures (verified). Numbering is per-tool and derived from
    # committed-on-disk state, so it survives subshells AND stays deterministic across the two
    # capture runs (same call order → same counts → pairing keys align).
    if [ -n "${IT_CAPTURE_DIR:-}" ]; then
        local key; key="$(_it_capture_key)"
        mkdir -p "$IT_CAPTURE_DIR/$key"      # find on a missing dir would abort a set -e caller (pipefail)
        local n_prev
        n_prev="$(find "$IT_CAPTURE_DIR/$key" -mindepth 1 -maxdepth 1 -type d -name "${tool}-*" | wc -l)"
        local cdir="$IT_CAPTURE_DIR/${key}/${tool}-$(printf '%03d' "$((n_prev + 1))")"
        # CYCLE-6 fix #4: snapshot the REAL fixture root, not $PWD. 86 parity invocations pass their fixture via
        # `--root <tmp>` WITHOUT cd-ing, so $PWD is the test's own dir, NOT the tree the tool mutated.
        # D-09 REBASE (2026-07-03): hand normalize() the per-lane exec roots so every form of "the
        # executing checkout's path" (oracle worktree / staged index / repo) collapses to ONE
        # <EXEC_ROOT> token on BOTH legs — a tool embedding its own location is otherwise a
        # guaranteed cross-lane divergence. Exported for the capture only; both lanes list BOTH
        # roots (symmetry is what makes the tokens equal).
        local _wt=""; _wt="$(_oracle_worktree_dir 2>/dev/null || true)"
        _NORM_EXEC_ROOTS="${_wt}:$(_oracle_exec_root):$(_oracle_git_root)" \
            capture_footprint "$(_it_footprint_root "$@")" "$cdir"
    fi
    return 0    # ALWAYS 0 — status is exposed ONLY via $IT_EXIT (REVIEWS HIGH#2)
}
# CYCLE-6 fix #4 — the tree-channel snapshot root. Honor an explicit IT_FOOTPRINT_ROOT override; else scan the
# invocation args for `--root <dir>` / `--root=<dir>` (the dominant fixture-passing flag — 86 sites) and snapshot
# THAT tree; else fall back to $PWD (the cd-into-fixture minority). This makes the resulting-file-tree channel
# capture the actual fixture the tool wrote, so a py-vs-bash tree divergence under `--root` is no longer missed.
_it_footprint_root() {
    if [ -n "${IT_FOOTPRINT_ROOT:-}" ]; then printf '%s\n' "$IT_FOOTPRINT_ROOT"; return 0; fi
    local a prev=""
    for a in "$@"; do
        # REVIEW FIX: the --root=<dir> spelling now gets the same -d existence check as the
        # two-arg form (a nonexistent root previously flowed into capture_footprint's cd and
        # killed the calling test under set -e in capture runs only).
        case "$a" in --root=*) if [ -d "${a#--root=}" ]; then printf '%s\n' "${a#--root=}"; return 0; fi ;; esac
        if [ "$prev" = "--root" ] && [ -d "$a" ]; then printf '%s\n' "$a"; return 0; fi
        prev="$a"
    done
    printf '%s\n' "$PWD"
}
# CYCLE-6 fix #4 — the CROSS-RUN pairing key. The on-disk capture segment is <testbasename>-<pid>; the -<pid>
# suffix disambiguates WITHIN one run but DIFFERS across the separate bash and py --capture-channels runs. Plan 05's
# --require-parity pairs captures by STRIPPING the trailing -<pid> so <suite>/<testbasename>/<tool>-<NN> is the
# stable pid-INDEPENDENT cross-run identity (else the two runs' PIDs never match -> vacuous green). This helper
# strips the -<pid> from a keyed segment; --require-parity uses it (or an equivalent inline strip) to build pairs.
it_pairing_key() { printf '%s\n' "$1" | sed -E 's/-[0-9]+$//'; }

# invoke_tool_compat <tool> [args...] — DIRECT-CALL-SEMANTICS wrapper over the seam,
# used by the mechanical Plan-05 routing of the pre-existing suites. The 204 direct
# call sites span if-conditions, ||-lists, command substitutions with cd-subshells and
# env prefixes — shapes whose assertions expect the direct contract (payload on stdout,
# diagnostics on stderr, the tool's own exit status). This wrapper preserves that
# contract byte-for-byte while still routing through the seam (WIKI_IMPL branch +
# worktree oracle + IT_CAPTURE_DIR self-record), so no assertion is rewritten (D-13).
# NOTE: callers of THIS form rely on its nonzero return; the set -e-safe
# `invoke_tool X; rc=$IT_EXIT` idiom remains the form for NEW tests. Existing sites
# already handle direct semantics safely (they pass today with direct calls).
invoke_tool_compat() {
    invoke_tool "$@"
    cat "$IT_STDOUT"
    cat "$IT_STDERR" >&2
    return "$IT_EXIT"
}
export -f invoke_tool _it_is_ported _it_capture_key _it_footprint_root it_pairing_key invoke_tool_compat
