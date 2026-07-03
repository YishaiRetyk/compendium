# tests/phase-24/lib.sh — Phase 24 characterization-suite helpers.
# Sources the FROZEN parity seam (Plan 03); do NOT redefine seam functions here.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
source "$REPO_ROOT/tests/lib/invoke_tool.sh"   # sources oracle-worktree.sh + normalize.sh

# Deterministic modes for committed goldens: the tree channel records file modes,
# and a 002-umask dev box would emit 664 while a 022-umask CI box emits 644.
umask 022

# Writable extracted tree for STATE-DEPENDENT error paths the frozen/shared worktree
# cannot reach (REVIEWS cycle-3 finding #1): git archive the SAME baseline ref the
# oracle reads, extracted into a per-test temp dir the driver CAN seed.
extract_writable_tree() {
    local ext
    ext="$(mktemp -d)"
    git -C "$REPO_ROOT" archive "$(_oracle_baseline_ref)" | tar -x -C "$ext"
    printf '%s\n' "$ext"
}

# golden_check_or_freeze <golden-case-dir> <actual-case-dir>
# REVIEW FIX: freezing a first capture now requires an EXPLICIT GOLDEN_FREEZE=1 — a missing
# golden (forgotten `git add`, dropped in a rebase, typo'd path) previously auto-froze the
# CURRENT behavior and passed green in CI forever, silently converting the byte-assert into
# self-certification. Missing golden without the flag = loud FAILURE with the recipe.
golden_check_or_freeze() {
    local golden="$1" actual="$2"
    if [ ! -d "$golden" ]; then
        if [ "${GOLDEN_FREEZE:-0}" = "1" ]; then
            mkdir -p "$(dirname "$golden")"
            cp -r "$actual" "$golden"
            echo "GOLDEN FROZEN: $golden (first capture — commit it)"
            return 0
        fi
        echo "FAIL: golden missing: $golden — if this is a NEW case, re-run with GOLDEN_FREEZE=1 and commit the result; if not, the committed golden was lost (do NOT blindly re-freeze)" >&2
        return 1
    fi
    assert_parity "$golden" "$actual"
}

# assert_exit_code <expected> <actual> <description>
assert_exit_code() {
    local expected="$1" actual="$2" desc="$3"
    if [ "$actual" != "$expected" ]; then
        echo "FAIL: $desc — expected exit $expected, got $actual" >&2
        return 1
    fi
}

# build_parity_gate_scaffold — a mini git repo wired for bin/check-staged-parity.sh:
# the gate + guard + the frozen seam/runner copied in, a committed bash faketool (= the
# oracle body), a ported.manifest listing faketool, a pinned freeze baseline, and a tiny
# routed suite. Callers export WIKI_PARITY_ONLY_SUITES="<sc>/tests/phase-divtest" so the
# gate's run-all executes ONLY the tiny suite (the runner's frozen --only-suite knob).
# Prints the scaffold root. Caller cleans up (incl. the scaffold's oracle worktree).
build_parity_gate_scaffold() {
    local sc; sc="$(mktemp -d)"
    mkdir -p "$sc/bin" "$sc/src/compendium" "$sc/tests/lib" "$sc/tests/phase-divtest" "$sc/tests/foot"
    cp "$REPO_ROOT/bin/check-staged-parity.sh" "$REPO_ROOT/bin/check-common-freeze.sh" "$sc/bin/"
    cp "$REPO_ROOT/tests/run-all-suites.sh" "$sc/tests/"
    cp "$REPO_ROOT/tests/lib/invoke_tool.sh" "$REPO_ROOT/tests/lib/oracle-worktree.sh" \
       "$REPO_ROOT/tests/lib/normalize.sh" "$REPO_ROOT/tests/lib/no-direct-bin-calls.sh" "$sc/tests/lib/"
    printf '# scaffold manifest\nfaketool\n' > "$sc/tests/ported.manifest"
    printf '# scaffold exemptions\n' > "$sc/tests/oracle-exempt.txt"
    printf 'phase-divtest/test_div PASS\n' > "$sc/tests/SUITE_MANIFEST.txt"
    touch "$sc/src/compendium/__init__.py"
    scaffold_write_module "$sc" 'OK\n'
    cat > "$sc/bin/faketool.sh" <<'EOF'
#!/usr/bin/env bash
printf 'OK\n'
EOF
    chmod +x "$sc/bin/faketool.sh"
    cat > "$sc/tests/phase-divtest/test_div.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/../.." && pwd)"
source "\$REPO_ROOT/tests/lib/invoke_tool.sh"
export IT_FOOTPRINT_ROOT="\$REPO_ROOT/tests/foot"
invoke_tool faketool run-once
[ "\$IT_EXIT" = "0" ] || { echo "faketool exited \$IT_EXIT" >&2; exit 1; }
EOF
    chmod +x "$sc/tests/phase-divtest/test_div.sh"
    (
        cd "$sc"
        git init -q -b main
        git config user.email fixture@example.com
        git config user.name Fixture
        git add -A
        git -c commit.gpgsign=false commit -qm seed
        git rev-parse HEAD > tests/freeze-baseline.sha
        git add tests/freeze-baseline.sha
        git -c commit.gpgsign=false commit -qm "pin baseline"
    )
    printf '%s\n' "$sc"
}

# scaffold_write_module <sc> <printf-bytes> — (re)write the scaffold's python module.
scaffold_write_module() {
    cat > "$1/src/compendium/faketool.py" <<EOF
import sys

def main(argv=None):
    sys.stdout.write("$2")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
EOF
}

# scaffold_write_shim <sc> — the canonical Phase-25 shim form for faketool.
scaffold_write_shim() {
    cat > "$1/bin/faketool.sh" <<'EOF'
#!/usr/bin/env bash
_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONPATH="${_REPO_ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
exec python3 -m compendium.faketool "$@"
EOF
    chmod +x "$1/bin/faketool.sh"
}

# scaffold_oracle_worktree_dir <sc> — the scaffold's cached oracle worktree path (for cleanup).
scaffold_oracle_worktree_dir() {
    WIKI_ORACLE_GIT_ROOT="$1" bash -c "source '$REPO_ROOT/tests/lib/invoke_tool.sh'; _oracle_worktree_dir" 2>/dev/null || true
}

# seed_valid_page <path> <id> <type> — a page satisfying validate-op's required
# base fields (id,title,type,status,summary,created_at,updated_at,sources,
# epistemic_status,tags,domains) with fixed dates (deterministic goldens).
seed_valid_page() {
    local path="$1" id="$2" ptype="$3"
    mkdir -p "$(dirname "$path")"
    cat > "$path" <<EOF
---
id: ${id}
title: Sample ${id}
type: ${ptype}
status: active
summary: A deterministic fixture page.
created_at: 2026-01-02
updated_at: 2026-01-02
sources: []
epistemic_status: sourced
tags: [fixture]
domains: [general]
---

## TL;DR

- A fixture claim.
EOF
    chmod 644 "$path"
}
