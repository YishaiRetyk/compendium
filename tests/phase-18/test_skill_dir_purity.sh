#!/usr/bin/env bash
# Covers: SKILL-01 directory purity (SPEC: each skill dir contains ONLY SKILL.md)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
FAIL=0
for op in ingest query lint reflect; do
    dir="$REPO_ROOT/.claude/skills/$op"
    [ -d "$dir" ] || { echo "FAIL: $dir missing"; FAIL=1; continue; }
    # Reject ANY top-level entry that is not SKILL.md (any extension, dirs included).
    extra=$(find "$dir" -mindepth 1 -maxdepth 1 ! -name "SKILL.md" | wc -l)
    [ "$extra" -eq 0 ] || { echo "FAIL: $dir contains $extra entr(y/ies) other than SKILL.md"; FAIL=1; }
done
[ "$FAIL" -eq 0 ] && echo "PASS: all skill dirs contain ONLY SKILL.md"
exit "$FAIL"
