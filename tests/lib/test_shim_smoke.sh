#!/usr/bin/env bash
# Seam self-test (REVIEWS cycle-3 HIGH finding #3 + cycle-4 finding #3 + cycle-6 fix #5,
# PRE-FIX-FAILING): run WITH THE SEAM PYTHONPATH UNSET — the canonical shim (which OWNS its
# own checkout-hermetic PYTHONPATH bootstrap) PASSES while a bootstrap-free shim FAILS with
# ModuleNotFoundError (the seam's PYTHONPATH preload would otherwise MASK the missing
# bootstrap); a deliberately-broken shim is CAUGHT on the py lane (proving WIKI_IMPL=py runs
# THROUGH bin/<tool>.sh, not python3 -m directly); and a MANIFEST-DRIVEN loop binds the
# bootstrap property to EVERY real ported shim (empty in Phase 24; lights up per port).
# Mechanism note (cycle-4 finding #3): the smoke runs execute the shim DIRECTLY the same way
# the seam's py lane does, but WITHOUT the seam's PYTHONPATH assignment (`unset PYTHONPATH`)
# — this is the ONLY place the seam PYTHONPATH is cleared; the normal lane keeps its export.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"

fail() { echo "FAIL: $1" >&2; exit 1; }

SC="$(mktemp -d)"; trap 'rm -rf "$SC"' EXIT
mkdir -p "$SC/bin" "$SC/src/compendium" "$SC/tests"
touch "$SC/src/compendium/__init__.py"
cat > "$SC/src/compendium/faketool.py" <<'EOF'
import sys

def main(argv=None):
    print("FAKETOOL-OK")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
EOF
printf '# scaffold manifest\nfaketool\n' > "$SC/tests/ported.manifest"

write_canonical_shim() {
    cat > "$SC/bin/faketool.sh" <<'EOF'
#!/usr/bin/env bash
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.faketool "$@"
EOF
    chmod +x "$SC/bin/faketool.sh"
}
write_bootstrap_free_shim() {
    cat > "$SC/bin/faketool.sh" <<'EOF'
#!/usr/bin/env bash
exec python3 -m compendium.faketool "$@"
EOF
    chmod +x "$SC/bin/faketool.sh"
}
write_broken_shim() {
    # WITH its own bootstrap (this case is purely a wrong-module test).
    cat > "$SC/bin/faketool.sh" <<'EOF'
#!/usr/bin/env bash
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.WRONGNAME "$@"
EOF
    chmod +x "$SC/bin/faketool.sh"
}

# Run the shim the way the seam's py lane does, MINUS the masking PYTHONPATH (seam env cleared).
run_shim_seam_env_cleared() {
    local out="$1" err="$2"; shift 2
    if ( unset PYTHONPATH; LC_ALL=C TZ=UTC bash "$SC/bin/faketool.sh" "$@" </dev/null >"$out" 2>"$err" ); then
        return 0
    else
        return $?
    fi
}

# 3. Canonical shim (own bootstrap) PASSES with the seam PYTHONPATH cleared.
write_canonical_shim
O="$(mktemp)"; E="$(mktemp)"
rc=0; run_shim_seam_env_cleared "$O" "$E" || rc=$?
[ "$rc" = "0" ] || fail "canonical shim failed with seam PYTHONPATH cleared (rc=$rc): $(cat "$E")"
grep -q 'FAKETOOL-OK' "$O" || fail "canonical shim did not reach the module"
echo "ok: canonical shim (owns its bootstrap) passes with seam env cleared"

# 4. Bootstrap-free shim FAILS with the seam PYTHONPATH cleared (cycle-4 finding #3 —
#    against a seam-PYTHONPATH-preloaded lane this wrongly PASSES; the clear exposes it).
write_bootstrap_free_shim
rc=0; run_shim_seam_env_cleared "$O" "$E" || rc=$?
[ "$rc" != "0" ] || fail "bootstrap-free shim PASSED with seam env cleared (the missing bootstrap was masked)"
grep -q 'ModuleNotFoundError' "$E" || fail "expected ModuleNotFoundError from the bootstrap-free shim, got: $(cat "$E")"
echo "ok: bootstrap-free shim caught (ModuleNotFoundError) with seam env cleared"

# 5. Broken shim caught ON THE PY LANE (finding #3): the seam runs the SHIM for a ported tool,
#    so a wrong module name surfaces as a nonzero IT_EXIT (not bypassed via python3 -m).
write_broken_shim
WIKI_EXEC_ROOT="$SC" WIKI_IMPL=py invoke_tool faketool
[ "$IT_EXIT" != "0" ] || fail "broken shim NOT caught on the py lane (was the shim bypassed?)"
echo "ok: broken shim caught on the py parity lane (IT_EXIT=$IT_EXIT)"

# 6. MANIFEST-DRIVEN per-shim enforcement (cycle-6 fix #5): iterate every ported tool in the
#    exec root's tests/ported.manifest and assert each REAL bin/<tool>.sh shim owns its
#    bootstrap (no ModuleNotFoundError for the package with the seam PYTHONPATH cleared).
#    Empty manifest -> zero iterations (the real repo in Phase 24); Phase 25 appends light it up.
smoke_manifest_loop() {
    local exec_root="$1" mf tool o e lrc=0
    mf="$exec_root/tests/ported.manifest"
    [ -f "$mf" ] || return 0
    while IFS= read -r tool; do
        case "$tool" in \#*|"") continue ;; esac
        o="$(mktemp)"; e="$(mktemp)"
        ( unset PYTHONPATH; LC_ALL=C TZ=UTC bash "$exec_root/bin/${tool}.sh" --help </dev/null >"$o" 2>"$e" ) || true
        if grep -q 'ModuleNotFoundError' "$e"; then
            echo "SHIM BOOTSTRAP MISSING: $tool (ModuleNotFoundError with seam PYTHONPATH cleared)" >&2
            lrc=1
        fi
    done < "$mf"
    return "$lrc"
}
# (a) bootstrap-free scaffold shim -> the loop FLAGS faketool (nonzero).
write_bootstrap_free_shim
if smoke_manifest_loop "$SC" 2>/dev/null; then
    fail "manifest-driven loop did NOT flag a bootstrap-free ported shim"
fi
# (b) canonical scaffold shim -> the loop passes.
write_canonical_shim
smoke_manifest_loop "$SC" || fail "manifest-driven loop flagged the canonical shim"
# (c) the REAL repo: manifest empty in Phase 24 -> loop body runs zero times -> passes.
smoke_manifest_loop "$REPO_ROOT" || fail "manifest-driven loop failed on the real repo"
echo "ok: manifest-driven per-shim bootstrap enforcement (flags bootstrap-free; passes canonical; empty=noop)"

echo "PASS: shim smoke (py lane via shim; shim owns its bootstrap; manifest-driven enforcement)"
