#!/usr/bin/env bash
# tests/phase-18/run.sh -- Phase 18 Skills Overlay test aggregator.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Run the whole suite from the repo root (REVIEW WR-02): the generator and several tests
# use repo-relative paths, so a non-root caller cwd causes vacuous passes and can corrupt
# the real working tree via the drift-test restore trap.
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
PASS=0; FAIL=0
run_test() {
    local name="$1"
    if bash "$SCRIPT_DIR/$name" > /dev/null 2>&1; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name"; FAIL=$((FAIL+1))
    fi
}
run_test test_gen_skills_creates_files.sh
run_test test_gen_skills_idempotent.sh
run_test test_skill_body_thin.sh
run_test test_skill_dir_purity.sh
run_test test_skill_frontmatter.sh
run_test test_gen_skills_check_clean.sh
run_test test_gen_skills_check_drift.sh
run_test test_skills_git_tracked.sh
run_test test_hook_ordering_skills.sh
run_test test_neutrality_covers_skills.sh
echo ""
echo "PHASE 18 TESTS: $PASS/$((PASS+FAIL))"
[ "$FAIL" -eq 0 ]
