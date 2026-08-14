#!/usr/bin/env bash
# C-8 consult integrity against the REAL wiki index — READ-ONLY (wayfinder ticket 24).
#
# Why this test exists: the piped-alias bug (search resolved nothing on an
# [[id|Title]] index and exited 1 with empty output) survived a full golden
# suite because every existing case ran against a synthetic fixture that the
# author wrote to match the code. The real index is 100% piped, so the seam was
# dead in production while the tests were green. This test closes that gap by
# running against the corpus C-8 actually consults.
#
# READ-ONLY CONTRACT: this test never writes inside wiki-cloud/. It snapshots the
# tree before and after and fails if anything changed. Consult-health output is
# redirected to a temp file so a test run cannot touch real health state.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

cd "$REPO_ROOT"
RC=0
WIKI="wiki-cloud"
INDEX="$WIKI/index.md"

# The six canonical page-type subdirectories (schema/AGENTS.template.md).
PAGE_DIRS=(entities concepts sources comparisons overviews decisions)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export COMPENDIUM_CONSULT_HEALTH="$TMP/consult-health.status"

fail() { echo "FAIL: $*" >&2; RC=1; }

[ -f "$INDEX" ] || { echo "FAIL: $INDEX missing — cannot test the real index" >&2; exit 1; }

# Snapshot for the read-only assertion.
before="$(find "$WIKI" -type f -exec sha256sum {} + | sort)"

# --- A. The index really is piped-convention -------------------------------
# AGENTS.md §8 rule 3 mandates [[id|Exact Title]]. If this ever stops holding,
# the rest of the test is checking the wrong shape and should be revisited.
total_entries=$(grep -c '^- \[\[' "$INDEX" || true)
piped_entries=$(grep '^- \[\[' "$INDEX" | grep -c '|' || true)
[ "$total_entries" -gt 0 ] || fail "real index has no wikilink entries to test"
[ "$piped_entries" = "$total_entries" ] \
    || fail "expected every index entry piped ([[id|Title]]); got $piped_entries/$total_entries"

# --- B. Independent oracle: index and pages agree --------------------------
# Deliberately does NOT reuse the resolver — it asserts the underlying invariant
# (every indexed id has a page file under one of the six schema dirs) so a
# resolver bug cannot make its own test pass.
missing=0
while IFS= read -r id; do
    [ -n "$id" ] || continue
    found=0
    for d in "${PAGE_DIRS[@]}"; do
        [ -f "$WIKI/$d/$id.md" ] && { found=1; break; }
    done
    if [ "$found" = "0" ]; then
        echo "  index entry with no page file: $id" >&2
        missing=$((missing + 1))
    fi
done < <(sed -nE 's/^- \[\[([^]|]+)\|.*/\1/p' "$INDEX")
[ "$missing" = "0" ] || fail "$missing indexed page(s) have no file under ${PAGE_DIRS[*]}"

# --- C. A real consult resolves the real index, and says so ----------------
# One sweep across the em-dash-formatted entries (the bulk of the index) — the
# exact path that returned exit 1 and empty output before the fix.
sweep_out="$TMP/sweep.out"; sweep_err="$TMP/sweep.err"
sweep_rc=0
# invoke_tool_compat gives direct-call semantics (payload on stdout, the tool's
# own exit status); plain invoke_tool always returns 0 and hides output in $IT_*.
invoke_tool_compat search --paths-only "—" >"$sweep_out" 2>"$sweep_err" || sweep_rc=$?
[ "$sweep_rc" = "0" ] || fail "real-index sweep exited $sweep_rc (expected 0)"
resolved=$(wc -l < "$sweep_out")
[ "$resolved" -gt 0 ] || fail "real-index sweep resolved 0 pages (the ticket-24 regression)"
if grep -q 'WARNING' "$sweep_err"; then
    fail "real-index sweep reported unresolved entries: $(cat "$sweep_err")"
fi
# Every returned path must be a real file.
while IFS= read -r p; do
    [ -n "$p" ] || continue
    [ -f "$p" ] || fail "sweep returned a non-existent path: $p"
done < "$sweep_out"

# Consult health must exist and be ok for a healthy consult.
[ -f "$COMPENDIUM_CONSULT_HEALTH" ] || fail "consult-health file was not written"
health="$(cat "$COMPENDIUM_CONSULT_HEALTH" 2>/dev/null || true)"
case "$health" in
    ok\ *) : ;;
    *) fail "expected consult health 'ok <ts>' after a clean sweep, got: $health" ;;
esac

# --- D. Keyword mode returns real, non-hollow results ----------------------
first_id="$(sed -nE 's/^- \[\[([^]|]+)\|.*/\1/p' "$INDEX" | head -1)"
kw_out="$TMP/kw.out"; kw_rc=0
invoke_tool_compat search --paths-only "$first_id" >"$kw_out" 2>/dev/null || kw_rc=$?
[ "$kw_rc" = "0" ] || fail "keyword search for '$first_id' exited $kw_rc (expected 0)"
grep -q "$first_id" "$kw_out" \
    || fail "keyword search for '$first_id' did not return its own page: $(cat "$kw_out")"

# Default mode must render the result contract, not an empty shell.
def_out="$TMP/def.out"; def_rc=0
invoke_tool_compat search "$first_id" >"$def_out" 2>/dev/null || def_rc=$?
[ "$def_rc" = "0" ] || fail "default-mode search exited $def_rc (expected 0)"
grep -q '=== Search Results ===' "$def_out" || fail "default mode produced no result header"
grep -q 'result(s) ===' "$def_out" || fail "default mode produced no result count"

# --- E. READ-ONLY -----------------------------------------------------------
after="$(find "$WIKI" -type f -exec sha256sum {} + | sort)"
[ "$before" = "$after" ] || fail "$WIKI was MODIFIED by a search run (must be read-only)"

[ "$RC" = "0" ] && echo "PASS: C-8 real-index integrity ($total_entries piped entries, $resolved resolved, read-only)"
exit "$RC"
