#!/usr/bin/env bash
# tests/phase-c1/test_ingest_c1_fallback_emit_failure.sh -- C-1/ADR-008 non-silent
# failure: a FAILING cc-ledger emit (emit_op_line.py present but exits nonzero) must
#   (a) leave ingest's exit code untouched (fail-open, C-1 failure rule), AND
#   (b) append the C-1-shaped record to $XDG_STATE_HOME/compendium/
#       ledger-fallback.jsonl — never a silent no-op.
# Also asserts the record shape (v/ts/store/target/op/agent/session/refs) so the
# cc-ledger replayer can sweep the line as-is.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
printf '# c1 fixture\n' > "$TMP/note.md"

make_failing_emitter "$TMP/cc-ledger"
export CC_LEDGER_ROOT="$TMP/cc-ledger"
export XDG_STATE_HOME="$TMP/state"
export CLAUDE_SESSION_ID="c1-test-session"

# Explicit --contributor short-circuits git-based resolution (temp cwd is not a repo).
set +e
( cd "$TMP" && invoke_tool_compat ingest \
    --slug c1-emit-fail --contributor @c1-test "$TMP/note.md" ) > "$TMP/out.txt" 2>&1
rc=$?
set -e
assert_exit_code 0 "$rc" "ingest must stay fail-open when the ledger emit fails"
grep -q '=== Source Scaffolded ===' "$TMP/out.txt" \
    || { echo "FAIL: ingest did not complete its normal output" >&2; exit 1; }

FB="$TMP/state/compendium/ledger-fallback.jsonl"
[ -f "$FB" ] || { echo "FAIL: no fallback file after a failing emit (silent no-op regression): $FB" >&2; exit 1; }
depth=$(wc -l < "$FB")
[ "$depth" -eq 1 ] || { echo "FAIL: expected fallback depth 1, got $depth" >&2; exit 1; }

BUNDLE=$(find "$TMP/sources" -type d -name '*-c1-emit-fail' | head -1)
[ -n "$BUNDLE" ] || { echo "FAIL: no bundle dir created" >&2; exit 1; }
TARGET="$(canon_dir "$BUNDLE")/source.md"
assert_c1_line "$FB" 1 create "$TARGET" c1-test-session

echo "PASS: test_ingest_c1_fallback_emit_failure.sh"
