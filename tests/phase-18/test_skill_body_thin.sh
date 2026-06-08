#!/usr/bin/env bash
# Covers: SKILL-01 thinness + SKILL-02 zero-behavior (body is exactly one pointer line)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
FAIL=0
for op in ingest query lint reflect; do
    skill="$REPO_ROOT/.claude/skills/$op/SKILL.md"
    [ -f "$skill" ] || { echo "FAIL: $skill missing"; FAIL=1; continue; }
    # Extract post-frontmatter body (everything after the 2nd `---`).
    body=$(awk '/^---/{n++; if(n==2){found=1; next}} found{print}' "$skill")
    body_lines=$(printf '%s\n' "$body" | wc -l)
    [ "$body_lines" -le 3 ] || { echo "FAIL: $skill body has $body_lines lines (max 3)"; FAIL=1; }
    grep -q "schema/workflows/${op}.md" "$skill" || { echo "FAIL: $skill missing pointer to schema/workflows/${op}.md"; FAIL=1; }
    # SKILL-02 zero-behavior: exactly ONE non-blank body line (the pointer). More than one
    # non-blank line means procedural content was added to the body template.
    nonblank=$(printf '%s\n' "$body" | grep -c '[^[:space:]]' || true)
    [ "$nonblank" -eq 1 ] || { echo "FAIL: $skill body has $nonblank non-blank lines (expected exactly 1 pointer line -- zero behavior)"; FAIL=1; }
    # SKILL-02 zero-behavior: the single non-blank body line must be the allowed pointer form.
    # Reject any body line carrying imperative/procedural verbs that would encode behavior
    # rather than route to the workflow file. The allowed pointer uses "Read ... and follow it".
    nonblank_line=$(printf '%s\n' "$body" | grep '[^[:space:]]' | head -1)
    printf '%s\n' "$nonblank_line" | grep -qE "^You have been invoked to ${op}\. Read \`schema/workflows/${op}\.md\` and follow it verbatim\.$" \
        || { echo "FAIL: $skill body line is not the exact allowed pointer (zero-behavior): $nonblank_line"; FAIL=1; }
    # Defense in depth: reject procedural step markers anywhere in the body (numbered steps,
    # bullet lists, or extra imperative verbs that signal encoded behavior).
    if printf '%s\n' "$body" | grep -qE '^[[:space:]]*([0-9]+\.|[-*]|Step |Then |First,|Next,|Run |Create |Write |Update |Classify |Extract |Merge )'; then
        echo "FAIL: $skill body contains procedural/imperative content (steps/bullets/verbs) -- SKILL-02 zero-behavior violated"; FAIL=1
    fi
done
[ "$FAIL" -eq 0 ] && echo "PASS: all bodies thin, single pointer line, zero behavior"
exit "$FAIL"
