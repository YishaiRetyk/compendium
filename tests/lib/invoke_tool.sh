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
    normalize < "$IT_STDOUT" > "$casedir/stdout"
    normalize < "$IT_STDERR" > "$casedir/stderr"
    printf '%s\n' "$IT_EXIT" > "$casedir/exit"
    ( cd "$repo" && find . -path './.git' -prune -o -print 2>/dev/null \
        | sort \
        | while IFS= read -r e; do
              [ "$e" = "." ] && continue
              if [ -L "$e" ]; then
                  printf 'L %s -> %s\n' "$e" "$(readlink "$e")"
              elif [ -d "$e" ]; then
                  printf 'D %s %s\n' "$(stat -c '%a' "$e")" "$e"   # empty dirs recorded too
              elif [ -f "$e" ]; then
                  printf 'F %s %s  %s\n' "$(stat -c '%a' "$e")" \
                      "$(sha256sum "$e" | cut -d' ' -f1)" "$e"      # MODE captures exec bit
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
_IT_CALL_N=0                              # per-process call counter (disambiguates calls WITHIN one test file)
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
    if [ -n "${IT_CAPTURE_DIR:-}" ]; then
        _IT_CALL_N=$((_IT_CALL_N + 1))
        local key; key="$(_it_capture_key)"
        local cdir="$IT_CAPTURE_DIR/${key}/${tool}-$(printf '%03d' "$_IT_CALL_N")"
        # CYCLE-6 fix #4: snapshot the REAL fixture root, not $PWD. 86 parity invocations pass their fixture via
        # `--root <tmp>` WITHOUT cd-ing, so $PWD is the test's own dir, NOT the tree the tool mutated.
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
        case "$a" in --root=*) printf '%s\n' "${a#--root=}"; return 0 ;; esac
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
export -f invoke_tool _it_is_ported _it_capture_key _it_footprint_root it_pairing_key
