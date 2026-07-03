#!/usr/bin/env bash
# Phase 24 (TEST-04; REVIEWS cycle-4 finding #2b + cycle-6 fix #5): SHIM-LEVEL exit-3
# preflight-preservation CONTRACT TEST. init-wizard's exit 3 is a dependency-PRESENCE
# check ("is python3 present?") — a Python port CANNOT detect "python3 missing" from
# inside python3, so the Phase-25 .sh shim MUST preserve the pre-flight and return
# exit 3 BEFORE invoking Python. This test makes that compat boundary enforceable NOW:
#   1) a CANONICAL preflight-preserving shim (the documented Phase-25 form + preflight
#      gate) returns exit 3 with python3 stripped, WITHOUT reaching Python;
#   2) a BARE bootstrap-shim (no preflight) returns 127 (command not found), NOT 3 —
#      proving the contract is non-trivial (pre-fix-failing);
#   3) a CONTRACT-REGISTRY loop binds the contract to the REAL shipped shim population:
#      for each tool with a declared preflight contract (registry: init-wizard -> strip
#      python3 -> exit 3), the REAL bin/<tool>.sh shim is driven with the dependency
#      stripped and must return the contract code before Python. Proven via a scaffold
#      (bare shim flagged, canonical passes), then run against the real repo shim.
#      (Pre-26-02 this iterated tests/ported.manifest via the oracle exec-root; the
#      manifest is retired — all 16 tools ship, so the registry is the source of truth.)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }

# PATH farm WITHOUT python3 (bash/git/coreutils kept so the shim itself still runs).
build_no_python3_farm() {
    local farm t p
    farm="$(mktemp -d)"
    for t in bash sh git grep sed awk cat mkdir mktemp dirname basename readlink \
             cut tr sort find date stat cp mv rm ls chmod head tail wc env cmp diff \
             sha256sum tar uname; do
        p="$(command -v "$t" 2>/dev/null || true)"
        [ -n "$p" ] && ln -s "$p" "$farm/$t"
    done
    printf '%s\n' "$farm"
}
FARM="$(build_no_python3_farm)"
SC="$(mktemp -d)"
trap 'rm -rf "$FARM" "$SC"' EXIT

mkdir -p "$SC/bin" "$SC/src/compendium" "$SC/tests"
touch "$SC/src/compendium/__init__.py"
cat > "$SC/src/compendium/init_wizard.py" <<'EOF'
import sys

def main(argv=None):
    print("PY-MODULE-REACHED")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
EOF

write_canonical_preflight_shim() {
    cat > "$SC/bin/init-wizard.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# PRE-FLIGHT (exit 3) — MUST run in the shim BEFORE Python (a python port cannot check "python3 missing").
command -v python3 >/dev/null 2>&1 || { echo "init-wizard: python3 not found (pre-flight)" >&2; exit 3; }
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.init_wizard "$@"
EOF
    chmod +x "$SC/bin/init-wizard.sh"
}
write_bare_bootstrap_shim() {
    # NO preflight gate — with python3 stripped, `exec python3` dies with 127, NOT the contract 3.
    cat > "$SC/bin/init-wizard.sh" <<'EOF'
#!/usr/bin/env bash
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.init_wizard "$@"
EOF
    chmod +x "$SC/bin/init-wizard.sh"
}

run_stripped() {   # run a shim with python3 stripped from PATH; echoes rc
    local shim="$1" out="$2" err="$3"; shift 3
    set +e
    ( PATH="$FARM"; export PATH; bash "$shim" --dry-run </dev/null >"$out" 2>"$err" )
    local rc=$?
    set -e
    printf '%s\n' "$rc"
}

# 1. Canonical preflight-preserving shim -> exit 3 BEFORE Python.
write_canonical_preflight_shim
O="$(mktemp)"; E="$(mktemp)"
rc="$(run_stripped "$SC/bin/init-wizard.sh" "$O" "$E")"
[ "$rc" = "3" ] || fail "canonical shim: expected exit 3 with python3 stripped, got $rc"
grep -q 'PY-MODULE-REACHED' "$O" && fail "canonical shim reached Python despite missing python3"
grep -qi 'pre-flight\|preflight' "$E" || fail "canonical shim stderr does not name the pre-flight"
echo "ok: canonical shim preserves exit 3 before Python (python3 stripped)"

# 2. BARE bootstrap-shim (no preflight) -> 127, NOT 3 (the contract is non-trivial).
write_bare_bootstrap_shim
rc="$(run_stripped "$SC/bin/init-wizard.sh" "$O" "$E")"
[ "$rc" != "3" ] || fail "bare shim returned 3 — the preflight contract test is vacuous"
[ "$rc" = "127" ] || echo "note: bare shim returned $rc (expected 127 command-not-found; still NOT the contract 3)"
echo "ok: bare bootstrap-shim returns $rc (not 3) — contract is non-trivial"

# 3. Happy passthrough: with python3 PRESENT, the canonical shim reaches Python.
write_canonical_preflight_shim
set +e
bash "$SC/bin/init-wizard.sh" --dry-run </dev/null >"$O" 2>"$E"
rc=$?
set -e
[ "$rc" = "0" ] || fail "canonical shim with python3 present exited $rc"
grep -q 'PY-MODULE-REACHED' "$O" || fail "canonical shim did not reach Python with python3 present"
echo "ok: preflight gate does not over-block (module reached with python3 present)"

# 4. CONTRACT-REGISTRY per-shim enforcement (cycle-6 fix #5): iterate every tool with a
#    declared preflight contract and assert the REAL shim honors it (dependency stripped).
#    Contract registry: tool -> expected exit. All 16 tools ship post-migration; only
#    init-wizard carries a preflight (python3-presence) contract.
preflight_contract_exit() {
    case "$1" in
        init-wizard) printf '3\n' ;;
        *) printf '\n' ;;      # no preflight contract for other tools
    esac
}
CONTRACT_TOOLS="init-wizard"   # the tools with a non-empty preflight_contract_exit
preflight_loop() {
    local exec_root="$1" tool want rc o e lrc=0
    for tool in $CONTRACT_TOOLS; do
        want="$(preflight_contract_exit "$tool")"
        [ -n "$want" ] || continue
        [ -f "$exec_root/bin/${tool}.sh" ] || continue
        o="$(mktemp)"; e="$(mktemp)"
        rc="$(run_stripped "$exec_root/bin/${tool}.sh" "$o" "$e")"
        if [ "$rc" != "$want" ]; then
            echo "SHIM PREFLIGHT CONTRACT VIOLATION: $tool returned $rc (contract: $want) with its dependency stripped" >&2
            lrc=1
        elif grep -q 'PY-MODULE-REACHED' "$o"; then
            echo "SHIM PREFLIGHT CONTRACT VIOLATION: $tool reached Python before the preflight" >&2
            lrc=1
        fi
    done
    return "$lrc"
}
# (a) scaffold with a BARE shim -> loop FLAGS it.
write_bare_bootstrap_shim
if preflight_loop "$SC" 2>/dev/null; then
    fail "contract-registry loop did NOT flag a preflight-free shim"
fi
# (b) canonical shim -> loop passes.
write_canonical_preflight_shim
preflight_loop "$SC" || fail "contract-registry loop flagged the canonical preflight-preserving shim"
# (c) the REAL repo: the shipped bin/init-wizard.sh shim honors its exit-3 preflight.
preflight_loop "$REPO_ROOT" || fail "contract-registry loop failed on the real repo shim population"
echo "ok: contract-registry per-shim preflight enforcement (flags bare; passes canonical; real shim honors it)"

echo "PASS: shim-level exit-3 preflight-preservation contract (cycle-4 #2b + cycle-6 #5)"
