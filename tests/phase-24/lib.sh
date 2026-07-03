# tests/phase-24/lib.sh — characterization-suite helpers.
# Sources the tool-invocation seam (tests/lib/invoke_tool.sh → normalize.sh).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
source "$REPO_ROOT/tests/lib/invoke_tool.sh"

# Deterministic modes for committed goldens: the tree channel records file modes,
# and a 002-umask dev box would emit 664 while a 022-umask CI box emits 644.
umask 022

# Writable extracted tree for STATE-DEPENDENT error paths a read-only fixture cannot reach
# (gen-skills DRIFT exit 1 [a pristine checkout is always in-sync], init-wizard exit 4).
# `git archive HEAD` extracts the committed tree into a per-test temp dir the driver CAN seed.
# (Pre-26-02 this archived the frozen-oracle baseline ref; HEAD is the shipped state now, and
# HEAD's tools are byte-equivalent to that retired baseline — the migration certified it.)
extract_writable_tree() {
    local ext
    ext="$(mktemp -d)"
    git -C "$REPO_ROOT" archive HEAD | tar -x -C "$ext"
    printf '%s\n' "$ext"
}

# golden_check_or_freeze <golden-case-dir> <actual-case-dir>
# A missing golden without an EXPLICIT GOLDEN_FREEZE=1 is a LOUD FAILURE (a forgotten
# `git add`/dropped rebase must not silently auto-freeze current behavior and self-certify).
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

# seed_valid_page <path> <id> <type> — a page satisfying validate-op's required
# base fields with fixed dates (deterministic goldens).
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
