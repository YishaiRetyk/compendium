#!/usr/bin/env bash
# Phase 24 (TEST-03, D-15): 4-channel characterization goldens for validate-op.sh —
# ZERO tests existed for it before this suite. All 4 ops + error/usage paths, captured
# through the worktree-backed bash oracle (Plan 03). Goldens are frozen on first capture
# (commit them); later runs byte-assert against them.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

GOLD="$REPO_ROOT/tests/goldens/validate-op"
RC=0

run_case() {
    local case_name="$1"; shift
    local fixture; fixture="$(mktemp -d)"
    (
        cd "$fixture"
        case "$case_name" in
            update-ok)
                seed_valid_page wiki-cloud/concepts/alpha.md alpha concept
                invoke_tool validate-op UPDATE wiki-cloud/concepts/alpha.md ;;
            merge-ok)
                seed_valid_page wiki-cloud/concepts/alpha.md alpha concept
                seed_valid_page wiki-cloud/concepts/beta.md beta concept
                invoke_tool validate-op MERGE wiki-cloud/concepts/alpha.md wiki-cloud/concepts/beta.md ;;
            merge-same-path)
                seed_valid_page wiki-cloud/concepts/alpha.md alpha concept
                invoke_tool validate-op MERGE wiki-cloud/concepts/alpha.md wiki-cloud/concepts/alpha.md ;;
            supersede-ok)
                seed_valid_page wiki-cloud/concepts/alpha.md alpha concept
                invoke_tool validate-op SUPERSEDE wiki-cloud/concepts/alpha.md ;;
            supersede-already)
                seed_valid_page wiki-cloud/concepts/alpha.md alpha concept
                sed -i 's/^status: active/status: active\nsuperseded_by: beta/' wiki-cloud/concepts/alpha.md
                invoke_tool validate-op SUPERSEDE wiki-cloud/concepts/alpha.md ;;
            archive-ok)
                seed_valid_page wiki-cloud/concepts/alpha.md alpha concept
                invoke_tool validate-op ARCHIVE wiki-cloud/concepts/alpha.md ;;
            archive-already)
                seed_valid_page wiki-cloud/concepts/alpha.md alpha concept
                sed -i 's/^status: active/status: archived/' wiki-cloud/concepts/alpha.md
                invoke_tool validate-op ARCHIVE wiki-cloud/concepts/alpha.md ;;
            usage-noargs)
                invoke_tool validate-op ;;
            bad-op)
                invoke_tool validate-op FROBNICATE some/path.md ;;
            missing-target)
                mkdir -p wiki-cloud/concepts
                invoke_tool validate-op UPDATE wiki-cloud/concepts/nonexistent.md ;;
            *) echo "unknown case: $case_name" >&2; exit 1 ;;
        esac
        actual="$(mktemp -d)/case"
        capture_footprint "$PWD" "$actual"
        golden_check_or_freeze "$GOLD/$case_name" "$actual"
    ) || { echo "FAIL: case $case_name" >&2; return 1; }
    rm -rf "$fixture"
}

for c in update-ok merge-ok merge-same-path supersede-ok supersede-already \
         archive-ok archive-already usage-noargs bad-op missing-target; do
    run_case "$c" || RC=1
done

# Exit-code spot checks on the committed goldens (the contract, human-readable):
grep -qx '0' "$GOLD/update-ok/exit"        || { echo "FAIL: update-ok exit golden != 0" >&2; RC=1; }
grep -qx '0' "$GOLD/merge-ok/exit"         || { echo "FAIL: merge-ok exit golden != 0" >&2; RC=1; }
grep -qx '1' "$GOLD/merge-same-path/exit"  || { echo "FAIL: merge-same-path exit golden != 1" >&2; RC=1; }
grep -qx '1' "$GOLD/supersede-already/exit" || { echo "FAIL: supersede-already exit golden != 1" >&2; RC=1; }
grep -qx '1' "$GOLD/archive-already/exit"  || { echo "FAIL: archive-already exit golden != 1" >&2; RC=1; }
grep -qx '1' "$GOLD/usage-noargs/exit"     || { echo "FAIL: usage-noargs exit golden != 1" >&2; RC=1; }
grep -qx '1' "$GOLD/bad-op/exit"           || { echo "FAIL: bad-op exit golden != 1" >&2; RC=1; }

[ "$RC" = "0" ] && echo "PASS: validate-op characterization (10 cases, 4 channels each)"
exit "$RC"
