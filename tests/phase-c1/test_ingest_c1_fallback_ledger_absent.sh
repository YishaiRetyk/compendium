#!/usr/bin/env bash
# tests/phase-c1/test_ingest_c1_fallback_ledger_absent.sh -- C-1/ADR-008 non-silent
# failure: when cc-ledger is ABSENT on the host (no bin/emit_op_line.py under
# CC_LEDGER_ROOT), ingest must (a) still exit 0 and (b) append the C-1-shaped record
# to the fallback file — the pre-ADR-008 behavior (silent no-op) is the regression
# this test pins against. Runs ingest twice (create, then --force edit) to assert the
# file is APPEND-ONLY and its line depth is the visible metric (1 -> 2), and that the
# op field tracks the write kind.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
printf '# c1 fixture\n' > "$TMP/note.md"

export CC_LEDGER_ROOT="$TMP/no-such-cc-ledger"   # absent: dir never created
export XDG_STATE_HOME="$TMP/state"
unset CLAUDE_SESSION_ID                          # default session must be "batch"

FB="$TMP/state/compendium/ledger-fallback.jsonl"

# 1) First ingest (create) -> exit 0, fallback depth 1, op=create.
set +e
( cd "$TMP" && invoke_tool_compat ingest \
    --slug c1-absent --contributor @c1-test "$TMP/note.md" ) >/dev/null 2>&1
rc=$?
set -e
assert_exit_code 0 "$rc" "ingest must stay fail-open when cc-ledger is absent"
[ -f "$FB" ] || { echo "FAIL: no fallback file when cc-ledger is absent (silent no-op regression): $FB" >&2; exit 1; }
depth=$(wc -l < "$FB")
[ "$depth" -eq 1 ] || { echo "FAIL: expected fallback depth 1 after first ingest, got $depth" >&2; exit 1; }

BUNDLE=$(find "$TMP/sources" -type d -name '*-c1-absent' | head -1)
[ -n "$BUNDLE" ] || { echo "FAIL: no bundle dir created" >&2; exit 1; }
TARGET="$(canon_dir "$BUNDLE")/source.md"
assert_c1_line "$FB" 1 create "$TARGET" batch

# 2) Second ingest (--force -> op=edit) -> depth grows to 2; line 1 untouched.
set +e
( cd "$TMP" && invoke_tool_compat ingest \
    --slug c1-absent --contributor @c1-test --force "$TMP/note.md" ) >/dev/null 2>&1
rc=$?
set -e
assert_exit_code 0 "$rc" "forced re-ingest must stay fail-open when cc-ledger is absent"
depth=$(wc -l < "$FB")
[ "$depth" -eq 2 ] || { echo "FAIL: expected fallback depth 2 after second ingest (append-only), got $depth" >&2; exit 1; }
assert_c1_line "$FB" 1 create "$TARGET" batch   # earlier line survives (append-only)
assert_c1_line "$FB" 2 edit   "$TARGET" batch

echo "PASS: test_ingest_c1_fallback_ledger_absent.sh"
