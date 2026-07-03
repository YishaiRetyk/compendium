#!/usr/bin/env bash
# Phase 24 (TEST-03, D-15): 4-channel characterization goldens for the UNTESTED
# search.sh modes (--query, --paths-only, --fulltext) + the missing-arg error paths,
# captured through the worktree-backed bash oracle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

GOLD="$REPO_ROOT/tests/goldens/search"
RC=0

seed_search_fixture() {
    mkdir -p wiki-cloud/concepts
    cat > wiki-cloud/index.md <<'EOF'
# Index

## Concepts

- [[gadget-theory|Gadget Theory]] — how gadgets compose
- [[widget-basics|Widget Basics]] — widget fundamentals
EOF
    cat > wiki-cloud/concepts/gadget-theory.md <<'EOF'
---
id: gadget-theory
title: Gadget Theory
type: concept
---

## TL;DR

- Gadgets compose into assemblies.

## Detail

The widget connects to the gadget through a coupling.
EOF
    cat > wiki-cloud/concepts/widget-basics.md <<'EOF'
---
id: widget-basics
title: Widget Basics
type: concept
---

## TL;DR

- Widgets are the smallest unit.
EOF
    chmod 644 wiki-cloud/index.md wiki-cloud/concepts/*.md
}

# A BARE-link index ([[id]] without pipe) — the only index shape whose title
# extraction resolves a page path today. CHARACTERIZATION FINDING (frozen, not
# fixed — behavior parity bar): on the convention-conforming PIPED index
# ([[id|Title]]), keyword/--paths-only/--query silently exit 1 with empty
# output — the title extraction keeps "id|Title", the slug never resolves, and
# the fallback `grep|head` under pipefail aborts the script. Broken on the real
# wiki since the Phase-14 piped-link migration; the piped-index goldens freeze
# that real behavior, the bare-index goldens exercise the working result path.
# Post-migration fix tracked in .planning/todos/pending/.
seed_bare_index() {
    cat > wiki-cloud/index.md <<'EOF'
# Index

## Concepts

- [[gadget-theory]] -- how gadgets compose
- [[widget-basics]] -- widget fundamentals
EOF
    chmod 644 wiki-cloud/index.md
}

run_case() {
    local case_name="$1"; shift
    local fixture; fixture="$(mktemp -d)"
    (
        cd "$fixture"
        seed_search_fixture
        case "$case_name" in
            keyword)        invoke_tool search gadget ;;
            paths-only)     invoke_tool search gadget --paths-only ;;
            fulltext)       invoke_tool search coupling --fulltext ;;
            query-mode)     invoke_tool search --query "How do widgets relate to gadgets?" ;;
            keyword-bare-index)    seed_bare_index; invoke_tool search gadget ;;
            paths-only-bare-index) seed_bare_index; invoke_tool search gadget --paths-only ;;
            query-mode-bare-index) seed_bare_index; invoke_tool search --query "How do widgets relate to gadgets?" ;;
            query-missing-value) invoke_tool search --query ;;
            no-args)        invoke_tool search ;;
            *) echo "unknown case: $case_name" >&2; exit 1 ;;
        esac
        actual="$(mktemp -d)/case"
        capture_footprint "$PWD" "$actual"
        golden_check_or_freeze "$GOLD/$case_name" "$actual"
    ) || { echo "FAIL: case $case_name" >&2; return 1; }
    rm -rf "$fixture"
}

for c in keyword paths-only fulltext query-mode \
         keyword-bare-index paths-only-bare-index query-mode-bare-index \
         query-missing-value no-args; do
    run_case "$c" || RC=1
done

# The bare-index happy path must exercise the RESULT-formatting code (non-hollow coverage):
grep -qx '0' "$GOLD/keyword-bare-index/exit" || { echo "FAIL: keyword-bare-index exit golden != 0" >&2; RC=1; }
grep -q 'Search Results' "$GOLD/keyword-bare-index/stdout" || { echo "FAIL: keyword-bare-index stdout is hollow" >&2; RC=1; }
grep -q 'Query Prompt' "$GOLD/query-mode-bare-index/stdout" || { echo "FAIL: query-mode-bare-index stdout is hollow" >&2; RC=1; }
# The piped-index cases freeze today's LATENT-BUG behavior (exit 1, empty channels):
grep -qx '1' "$GOLD/keyword/exit" || { echo "FAIL: keyword (piped index) exit golden != 1 (latent-bug freeze)" >&2; RC=1; }

grep -qx '1' "$GOLD/query-missing-value/exit" || { echo "FAIL: query-missing-value exit golden != 1" >&2; RC=1; }
grep -qx '1' "$GOLD/no-args/exit" || { echo "FAIL: no-args exit golden != 1" >&2; RC=1; }

[ "$RC" = "0" ] && echo "PASS: search modes characterization (9 cases incl. the piped-index latent-bug freeze)"
exit "$RC"
