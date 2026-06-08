#!/usr/bin/env bash
# Covers: SKILL-02 -- --check detects drift in any SKILL.md
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
[ -f "$REPO_ROOT/bin/gen-skills.sh" ] || { echo "SKIP"; exit 1; }
# Restore committed skill files on any exit (idempotent), so a mid-loop abort never
# leaves a drifted file in the working tree.
trap 'bash "$REPO_ROOT/bin/gen-skills.sh" >/dev/null 2>&1 || true' EXIT
bash "$REPO_ROOT/bin/gen-skills.sh"
FAIL=0
for op in ingest query lint reflect; do
    skill="$REPO_ROOT/.claude/skills/$op/SKILL.md"
    echo "DRIFT" >> "$skill"
    bash "$REPO_ROOT/bin/gen-skills.sh" --check >/dev/null 2>&1 && rc=0 || rc=$?
    if [ "$rc" -ne 1 ]; then
        echo "FAIL: --check did not exit 1 after editing $skill (got $rc)"; FAIL=1
    fi
    bash "$REPO_ROOT/bin/gen-skills.sh"  # restore between iterations
done
[ "$FAIL" -eq 0 ] && echo "PASS: drift detection works for all four ops"
exit "$FAIL"
