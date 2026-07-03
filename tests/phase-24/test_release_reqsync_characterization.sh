#!/usr/bin/env bash
# Phase 24 (TEST-03, D-15 + cycle-4 finding #1 per-tool coverage): characterization
# goldens for the TWO routed tools the coverage census found with ZERO behavioral
# coverage — release (dry-run plan + the no-args quirk) and requirements-sync
# (--root fixture: advisory, --strict drift, --require-complete). Captured through
# the worktree oracle; goldens frozen on first run.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

GOLD="$REPO_ROOT/tests/goldens"
RC=0

# --- release: no-args usage path (exit 1 + usage on stdout/stderr).
release_noargs() {
    local fixture; fixture="$(mktemp -d)"
    (
        cd "$fixture"
        invoke_tool release
        actual="$(mktemp -d)/case"
        capture_footprint "$PWD" "$actual"
        golden_check_or_freeze "$GOLD/release/usage-noargs" "$actual"
        assert_exit_code 1 "$(cat "$GOLD/release/usage-noargs/exit")" "release no-args usage golden"
    ) || return 1
    rm -rf "$fixture"
}

# --- release: BEHAVIORAL dry-run plan (deterministic: prints the STATIC allowlist/
#     denylist plan, no per-file walk; changes only on a deliberate allowlist edit).
release_dryrun() {
    local fixture; fixture="$(mktemp -d)"
    (
        cd "$fixture"
        invoke_tool release --remote "file:///nonexistent-remote.git" --dry-run
        actual="$(mktemp -d)/case"
        capture_footprint "$PWD" "$actual"
        golden_check_or_freeze "$GOLD/release/dry-run-plan" "$actual"
        grep -q 'INCLUDES:' "$GOLD/release/dry-run-plan/stdout" || { echo "FAIL: dry-run plan missing allowlist (hollow golden)" >&2; exit 1; }
    ) || return 1
    rm -rf "$fixture"
}

# --- requirements-sync against a --root fixture: a 2-row REQUIREMENTS.md (one
#     Complete, one Pending) + a VERIFICATION.md that marks REQ-2 complete
#     (=> drift: REQUIREMENTS says Pending, VERIFICATION says Complete).
seed_reqsync_fixture() {
    local root="$1"
    mkdir -p "$root/phases/01-sample"
    cat > "$root/REQUIREMENTS.md" <<'EOF'
# Requirements: Fixture

| Requirement | Phase | Status |
|-------------|-------|--------|
| REQ-1 | Phase 1 | Complete |
| REQ-2 | Phase 1 | Pending |

- [x] **REQ-1**: The first fixture requirement
- [ ] **REQ-2**: The second fixture requirement
EOF
    cat > "$root/phases/01-sample/01-VERIFICATION.md" <<'EOF'
# Phase 1 Verification

- [x] REQ-1: Complete
- [x] REQ-2: Complete
EOF
    chmod 644 "$root/REQUIREMENTS.md" "$root/phases/01-sample/01-VERIFICATION.md"
}

reqsync_case() {
    local case_name="$1"; shift
    local fixture; fixture="$(mktemp -d)"
    seed_reqsync_fixture "$fixture/planning"
    (
        cd "$fixture"
        invoke_tool requirements-sync --root "$fixture/planning" "$@"
        actual="$(mktemp -d)/case"
        IT_FOOTPRINT_ROOT="$fixture/planning" capture_footprint "$fixture/planning" "$actual"
        golden_check_or_freeze "$GOLD/requirements-sync/$case_name" "$actual"
    ) || return 1
    rm -rf "$fixture"
}

release_noargs   || { echo "FAIL: release usage-noargs case" >&2; RC=1; }
release_dryrun   || { echo "FAIL: release dry-run case" >&2; RC=1; }
reqsync_case advisory                       || { echo "FAIL: requirements-sync advisory case" >&2; RC=1; }
reqsync_case strict-drift --strict          || { echo "FAIL: requirements-sync strict case" >&2; RC=1; }
reqsync_case require-complete --require-complete || { echo "FAIL: requirements-sync require-complete case" >&2; RC=1; }

# Contract spot checks on committed goldens:
grep -qx '2' "$GOLD/requirements-sync/strict-drift/exit" || { echo "FAIL: --strict drift exit golden != 2" >&2; RC=1; }
grep -qx '2' "$GOLD/requirements-sync/require-complete/exit" || { echo "FAIL: --require-complete exit golden != 2" >&2; RC=1; }

[ "$RC" = "0" ] && echo "PASS: release + requirements-sync characterization (5 cases)"
exit "$RC"
