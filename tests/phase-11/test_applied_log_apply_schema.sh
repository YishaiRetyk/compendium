#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_applied_log_apply_schema.sh — BRWN-14 + REVIEWS item
# 10: applied.log apply-blocks follow the documented per-script shape
# (paired inputs for 01; single vault-walk input line for 02).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo small-vault-ambiguous)
trap 'rm -rf "$TMP"' EXIT

if ! invoke_tool_compat brownfield suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

# Approve all clusters by resolving decisions to `approve` for every cluster entry.
DECFILE="$TMP/.brownfield/page-typing-decisions.yaml"
assert_file_exists "$DECFILE"
sed -i 's/^\([[:space:]]*\)decision:[[:space:]]*pending/\1decision: approve/g' "$DECFILE"

if ! bash "$TMP/.brownfield/migrations/01-page-typing.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 01-page-typing.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

LOG="$TMP/.brownfield/applied.log"
assert_file_exists "$LOG"

# 01 apply-block shape
assert_grep "^## 01-page-typing.sh @ " "$LOG" "01 header missing"
assert_grep "^mode: apply" "$LOG" "01 mode missing"
assert_grep "^op_hash: sha256:" "$LOG" "01 op_hash missing"
assert_grep "^exit_code: 0" "$LOG" "01 exit_code missing"
assert_grep "^prereq_check:" "$LOG" "01 prereq_check missing"
assert_grep "^inputs:" "$LOG" "01 inputs missing"
assert_grep "page-typing-candidates.yaml @ sha256:" "$LOG" "01 candidates input missing"
assert_grep "page-typing-decisions.yaml @ sha256:" "$LOG" "01 decisions input missing"
assert_grep "^files_touched:" "$LOG" "01 files_touched missing"
assert_grep "^changes:" "$LOG" "01 changes missing"
assert_grep "approved_clusters:" "$LOG" "01 approved_clusters missing"
assert_grep "overridden_pages:" "$LOG" "01 overridden_pages missing"
assert_grep "pending_pages_remaining:" "$LOG" "01 pending_pages_remaining missing"

# Now run 02 on the same vault and assert the per-script variance
if ! bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 02-provenance-bootstrap.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

assert_grep "^## 02-provenance-bootstrap.sh @ " "$LOG" "02 header missing"
assert_grep "(vault walk — no candidate inputs; 02 is direct-apply)" "$LOG" "02 direct-apply inputs line missing"
assert_grep "pages_with_eligible_bullets:" "$LOG" "02 summary missing"
assert_grep "pages_with_no_eligible_bullets:" "$LOG" "02 summary missing"

echo "PASS $NAME"; exit 0
