#!/usr/bin/env bash
# Covers: SKILL-01 frontmatter: name + description format
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
FAIL=0
for op in ingest query lint reflect; do
    skill="$REPO_ROOT/.claude/skills/$op/SKILL.md"
    [ -f "$skill" ] || { echo "FAIL: $skill missing"; FAIL=1; continue; }
    grep -q "^name:" "$skill" || { echo "FAIL: $skill missing name field"; FAIL=1; }
    grep -q "^description:" "$skill" || { echo "FAIL: $skill missing description field"; FAIL=1; }
    desc_line=$(grep "^description:" "$skill")
    # First-person check via word boundaries (REVIEWS.md LOW: the old [[:space:]|$] was a
    # character class matching literal space/pipe/dollar, NOT "space or end-of-line"). Use \b
    # word boundaries so a trailing pronoun is also caught. Case-sensitive to avoid flagging
    # legitimate lowercase words; matched tokens are the first-person markers I, we, I'll, we'll.
    if echo "$desc_line" | grep -qE "\b(I|we|We|I'll|We'll|I've|We've|I'm|we're|We're)\b"; then
        echo "FAIL: $skill description contains first-person pronoun"; FAIL=1
    fi
    grep -q 'disable-model-invocation: *true' "$skill" && { echo "FAIL: $skill has disable-model-invocation:true"; FAIL=1; }
done
[ "$FAIL" -eq 0 ] && echo "PASS: all frontmatter valid"
exit "$FAIL"
