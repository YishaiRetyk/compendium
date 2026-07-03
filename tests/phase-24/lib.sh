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
# First capture: freeze (copy actual -> golden; commit it). Later runs: byte-assert.
golden_check_or_freeze() {
    local golden="$1" actual="$2"
    if [ ! -d "$golden" ]; then
        mkdir -p "$(dirname "$golden")"
        cp -r "$actual" "$golden"
        echo "GOLDEN FROZEN: $golden (first capture — commit it)"
        return 0
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
