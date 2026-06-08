#!/usr/bin/env bash
# Covers: SKILL-01 -- bash bin/gen-skills.sh creates exactly 4 SKILL.md files
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# RED: bin/gen-skills.sh does not exist yet
[ -f "$REPO_ROOT/bin/gen-skills.sh" ] || { echo "SKIP (generator not implemented)"; exit 1; }
bash "$REPO_ROOT/bin/gen-skills.sh"
for op in ingest query lint reflect; do
    [ -f "$REPO_ROOT/.claude/skills/$op/SKILL.md" ] || { echo "FAIL: missing .claude/skills/$op/SKILL.md"; exit 1; }
done
count=$(find "$REPO_ROOT/.claude/skills" -name "SKILL.md" | wc -l)
[ "$count" -eq 4 ] || { echo "FAIL: expected 4 SKILL.md files, got $count"; exit 1; }
echo "PASS: 4 SKILL.md files created"
