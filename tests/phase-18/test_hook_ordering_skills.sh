#!/usr/bin/env bash
# Covers: D-03 pre-commit hook ordering
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
hook="$REPO_ROOT/.githooks/pre-commit"
[ -f "$hook" ] || { echo "FAIL: pre-commit hook missing"; exit 1; }
# Assert gen-skills --check is present
grep -q 'gen-skills.sh' "$hook" || { echo "FAIL: gen-skills.sh not in pre-commit hook"; exit 1; }
# Assert ordering: sync-claude appears before gen-skills, gen-skills before lint
sync_line=$(grep -n 'sync-claude' "$hook" | head -1 | cut -d: -f1)
gen_line=$(grep -n 'gen-skills' "$hook" | head -1 | cut -d: -f1)
lint_line=$(grep -n 'lint.sh' "$hook" | head -1 | cut -d: -f1)
[ -n "$sync_line" ] && [ -n "$gen_line" ] && [ -n "$lint_line" ] || { echo "FAIL: one of the hooks not found"; exit 1; }
[ "$sync_line" -lt "$gen_line" ] || { echo "FAIL: sync-claude must appear before gen-skills (lines $sync_line vs $gen_line)"; exit 1; }
[ "$gen_line" -lt "$lint_line" ] || { echo "FAIL: gen-skills must appear before lint --strict (lines $gen_line vs $lint_line)"; exit 1; }
echo "PASS: hook ordering correct: sync-claude($sync_line) < gen-skills($gen_line) < lint($lint_line)"
