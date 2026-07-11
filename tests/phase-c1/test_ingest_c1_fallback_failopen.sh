#!/usr/bin/env bash
# tests/phase-c1/test_ingest_c1_fallback_failopen.sh -- the two boundary conditions of
# the ADR-008 fallback itself:
#   1) HEALTHY emit -> the primary path runs (emitter argv recorded) and NO fallback
#      line is written (no double-recording; the fallback fires only on failure).
#   2) UNWRITABLE fallback (XDG_STATE_HOME/compendium blocked by a plain file) with
#      cc-ledger absent -> ingest STILL exits 0 with its normal output — the fallback
#      write is itself fail-open and must never break ingest (C-1 failure rule).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
printf '# c1 fixture\n' > "$TMP/note.md"

# 1) Healthy emit: recorded, and no fallback line.
make_recording_emitter "$TMP/cc-ledger"
export CC_LEDGER_ROOT="$TMP/cc-ledger"
export XDG_STATE_HOME="$TMP/state"

set +e
( cd "$TMP" && invoke_tool_compat ingest \
    --slug c1-healthy --contributor @c1-test "$TMP/note.md" ) >/dev/null 2>&1
rc=$?
set -e
assert_exit_code 0 "$rc" "ingest with a healthy emitter"
[ -f "$TMP/cc-ledger/calls.txt" ] \
    || { echo "FAIL: healthy emitter was never invoked (primary path skipped)" >&2; exit 1; }
grep -q -- '--store knowledge --op create' "$TMP/cc-ledger/calls.txt" \
    || { echo "FAIL: emitter argv missing expected --store/--op: $(cat "$TMP/cc-ledger/calls.txt")" >&2; exit 1; }
if [ -e "$TMP/state/compendium/ledger-fallback.jsonl" ]; then
    echo "FAIL: fallback line written although the emit SUCCEEDED (double-recording)" >&2
    exit 1
fi

# 2) Fallback unwritable + cc-ledger absent: ingest still succeeds.
export CC_LEDGER_ROOT="$TMP/no-such-cc-ledger"
export XDG_STATE_HOME="$TMP/state2"
mkdir -p "$TMP/state2"
touch "$TMP/state2/compendium"        # plain FILE where the dir must go -> makedirs fails

set +e
( cd "$TMP" && invoke_tool_compat ingest \
    --slug c1-blocked --contributor @c1-test "$TMP/note.md" ) > "$TMP/out2.txt" 2>&1
rc=$?
set -e
assert_exit_code 0 "$rc" "ingest must stay fail-open when the fallback write itself fails"
grep -q '=== Source Scaffolded ===' "$TMP/out2.txt" \
    || { echo "FAIL: ingest did not complete its normal output with fallback blocked" >&2; exit 1; }
[ -f "$TMP/state2/compendium" ] \
    || { echo "FAIL: blocking file was replaced — fallback write is not fail-open" >&2; exit 1; }

echo "PASS: test_ingest_c1_fallback_failopen.sh"
