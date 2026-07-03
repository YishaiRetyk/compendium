#!/usr/bin/env bash
# Phase 24 Plan 05 (REVIEWS HIGH#4 / cycle-3 finding #2 / cycle-4 finding #1 / cycle-6
# MEDIUM a, PRE-FIX-FAILING): the LIVE-path catch-a-routed-divergence behavioral test.
#   1. A stub "ported" tool whose py lane emits ONE divergent byte is run through the
#      REAL runner path (run-all --only-suite -> child test_*.sh -> invoke_tool ->
#      IT_CAPTURE_DIR self-record) for BOTH impls; --require-parity over the two REAL
#      capture dirs must exit NON-ZERO (the divergence is caught via live captures,
#      NOT hand-built comparator dirs).
#   2. With identical bytes on both lanes, --require-parity must exit 0.
#   3. PER-ROUTED-TOOL coverage: every routed tool has >=1 BEHAVIORAL (non-usage)
#      invocation or golden under the parity net — a tool covered only by --help
#      (or not at all) FAILS this test by name.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

fail() { echo "FAIL: $1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Scaffold: a tiny GIT repo (its committed HEAD = the bash oracle body; its
# WORKING tree carries the python shim) + a throwaway routed suite.
# ---------------------------------------------------------------------------
SC="$(mktemp -d)"
SUITE="$(mktemp -d)/phase-divtest"
BASHCH="$(mktemp -d)"; PYCH="$(mktemp -d)"
FOOT="$(mktemp -d)"   # stable footprint root for the divtest (empty dir)
trap 'rm -rf "$SC" "$(dirname "$SUITE")" "$BASHCH" "$PYCH" "$FOOT"; git -C "$REPO_ROOT" worktree prune >/dev/null 2>&1 || true' EXIT

mkdir -p "$SC/bin" "$SC/src/compendium" "$SC/tests"
touch "$SC/src/compendium/__init__.py"
cat > "$SC/bin/faketool.sh" <<'EOF'
#!/usr/bin/env bash
printf 'OK\n'
EOF
chmod +x "$SC/bin/faketool.sh"
printf '# divtest manifest\nfaketool\n' > "$SC/tests/ported.manifest"
(
    cd "$SC"
    git init -q -b main
    git config user.email fixture@example.com
    git config user.name Fixture
    git add -A
    git -c commit.gpgsign=false commit -qm seed
)
# N-4: a NON-EMPTY ported.manifest with no pinned baseline makes the oracle FAIL LOUDLY
# (verified live — the guard fired on this scaffold). Pin the scaffold's baseline at its
# seed commit so the bash leg runs the COMMITTED bash body from the worktree.
git -C "$SC" rev-parse HEAD > "$SC/tests/freeze-baseline.sha"
# Pre-compute the scaffold's oracle-worktree path for trap cleanup (do NOT glob-delete
# /tmp/wiki-oracle-worktree-* — that would nuke the real repo's cached oracle).
SC_WT="$(WIKI_ORACLE_GIT_ROOT="$SC" bash -c 'source "'"$REPO_ROOT"'/tests/lib/invoke_tool.sh"; _oracle_worktree_dir')"
trap 'rm -rf "$SC" "$(dirname "$SUITE")" "$BASHCH" "$PYCH" "$FOOT" "$SC_WT"' EXIT
# NOW flip the WORKING-TREE faketool.sh into the canonical shim -> python module.
# bash leg = worktree at HEAD (the committed bash body, prints "OK");
# py leg   = the working-tree shim -> python (prints a DIVERGENT byte).
write_py_module() {   # $1 = the exact bytes the module prints
    cat > "$SC/src/compendium/faketool.py" <<EOF
import sys

def main(argv=None):
    sys.stdout.write("$1")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
EOF
}
cat > "$SC/bin/faketool.sh" <<'EOF'
#!/usr/bin/env bash
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.faketool "$@"
EOF
chmod +x "$SC/bin/faketool.sh"

mkdir -p "$SUITE"
cat > "$SUITE/test_div.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export REPO_ROOT="$REPO_ROOT"
source "$REPO_ROOT/tests/lib/invoke_tool.sh"
export IT_FOOTPRINT_ROOT="$FOOT"
invoke_tool faketool run-once
rc=\$IT_EXIT
[ "\$rc" = "0" ] || { echo "faketool exited \$rc" >&2; exit 1; }
EOF
chmod +x "$SUITE/test_div.sh"

run_leg() {   # $1=impl  $2=capture-dir
    WIKI_IMPL="$1" WIKI_EXEC_ROOT="$SC" WIKI_ORACLE_GIT_ROOT="$SC" \
        bash "$REPO_ROOT/tests/run-all-suites.sh" --capture-channels "$2" --only-suite "$SUITE" >/dev/null 2>&1
}

# 1. DIVERGENT byte on the py lane -> --require-parity must exit NON-ZERO.
write_py_module 'OK \n'    # trailing space: one divergent byte vs the bash "OK\n"
run_leg bash "$BASHCH" || fail "bash leg of the divtest suite failed"
run_leg py "$PYCH"     || fail "py leg of the divtest suite failed"
if bash "$REPO_ROOT/tests/run-all-suites.sh" --require-parity "$BASHCH" "$PYCH" >/dev/null 2>&1; then
    fail "--require-parity PASSED an injected one-byte routed stdout divergence (LIVE path not caught)"
fi
echo "ok: injected routed byte divergence CAUGHT via the live run-all->seam->capture path"

# 2. Identical bytes -> --require-parity must exit 0.
write_py_module 'OK\n'
rm -rf "$PYCH"; PYCH="$(mktemp -d)"
run_leg py "$PYCH" || fail "py leg (identical) failed"
bash "$REPO_ROOT/tests/run-all-suites.sh" --require-parity "$BASHCH" "$PYCH" >/dev/null \
    || fail "--require-parity FAILED identical live captures"
echo "ok: identical live captures pass parity"

# 3. PER-ROUTED-TOOL coverage — >=1 BEHAVIORAL (non-usage) invocation or golden per tool.
#    Behavioral = an invocation with args beyond --help/-h, or a committed non-usage golden.
ROUTED_TOOLS=(audit-claims brownfield release pdf-extract requirements-sync repo-snapshot
              validate-op search sync-claude gen-skills lint ingest
              check-privacy check-neutrality check-sources-cloud-safe init-wizard)
MISSING=()
for tool in "${ROUTED_TOOLS[@]}"; do
    behavioral=0
    # (a) suite invocations that are not bare --help/-h
    if grep -rhE "invoke_tool(_compat)? $tool( |\$)" "$REPO_ROOT"/tests/phase-*/test_*.sh 2>/dev/null \
        | grep -vE -- '--help|-h$' | grep -q .; then
        behavioral=1
    fi
    # (b) committed goldens with a non-usage case name
    if [ -d "$REPO_ROOT/tests/goldens/$tool" ] \
        && ls -d "$REPO_ROOT/tests/goldens/$tool"/*/ 2>/dev/null | grep -vE 'usage|help' | grep -q .; then
        behavioral=1
    fi
    [ "$behavioral" = "1" ] || MISSING+=("$tool")
done
if [ "${#MISSING[@]}" -gt 0 ]; then
    fail "routed tool(s) with NO behavioral (non-usage) parity coverage: ${MISSING[*]}"
fi
echo "ok: every routed tool has >=1 behavioral coverage point (${#ROUTED_TOOLS[@]} tools)"

echo "PASS: routed parity divergence (live path) + per-tool coverage"
