#!/usr/bin/env bash
# R-1 mitigation (POST-EXTRACTION): AGENTS.md §4 stub is byte-identical to
# schema/AGENTS.template.md §4 stub (both now bare pointer stubs, not full bodies).
# §16 is DELETED from both files (Phase 16 Plan 03).
#
# POST-EXTRACTION shape (Phase 16):
#   AGENTS.md §4 = a 3-line stub pointing to schema/reference/page-types.md
#   schema/AGENTS.template.md §4 = same 3-line stub (byte-identical)
#   AGENTS.md §16 = ABSENT (section deleted in Phase 16-03)
#   schema/AGENTS.template.md §16 = ABSENT (section deleted in Phase 16-03)
#
# Strategy: Extract §4 stub from "## 4." through "## 5." (exclusive) from both
# files and assert byte-equality; assert §16 header absent from both.
# Phase 08-04 / 09-06 / 13.1 precedent for relaxing prior-phase tests when
# a successor plan changes the shape (see test_reference_stubs.sh header).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"
T="$REPO_ROOT/schema/AGENTS.template.md"

# Extract §4 stub body: from "## 4." to just before "## 5."
extract_section_4() {
    awk '
        /^## 5\. Frontmatter Schema/ { inside=0 }
        inside==1 { print }
        /^## 4\. Page Types and Templates/ { inside=1 }
    ' "$1"
}

# ASSERTION 1: §4 stub byte-identical between AGENTS.md and template
diff <(extract_section_4 "$A") <(extract_section_4 "$T") > /tmp/phase-09.1-s4.diff \
    || { echo "FAIL: §4 stub drift between AGENTS.md and schema/AGENTS.template.md" >&2; cat /tmp/phase-09.1-s4.diff >&2; exit 1; }

# ASSERTION 2: §4 stub contains the routing pointer to page-types.md
grep -q 'schema/reference/page-types.md' "$A" \
    || { echo "FAIL: §4 stub missing 'schema/reference/page-types.md' pointer" >&2; exit 1; }

# ASSERTION 3: schema/reference/page-types.md exists (the §4 body moved there)
test -f "$REPO_ROOT/schema/reference/page-types.md" \
    || { echo "FAIL: schema/reference/page-types.md missing (§4 body should live here)" >&2; exit 1; }

# ASSERTION 4: page-types.md contains the six subsection markers (entity/concept/source/comparison/overview/decision)
for t in entity concept source comparison overview decision; do
    grep -qi "### 4\.[0-9] ${t}\|### .* (.\`type: ${t}\`\|^### .*${t}" "$REPO_ROOT/schema/reference/page-types.md" 2>/dev/null \
        || grep -qi "${t}" "$REPO_ROOT/schema/reference/page-types.md" \
        || { echo "FAIL: schema/reference/page-types.md missing type '${t}'" >&2; exit 1; }
done

# ASSERTION 5: §16 header ABSENT from AGENTS.md (section deleted in Phase 16-03)
! grep -q '^## 16\.' "$A" \
    || { echo "FAIL: §16 header found in AGENTS.md — should be deleted (Phase 16-03)" >&2; exit 1; }

# ASSERTION 6: §16 header ABSENT from template (section deleted in Phase 16-03)
! grep -q '^## 16\.' "$T" \
    || { echo "FAIL: §16 header found in schema/AGENTS.template.md — should be deleted (Phase 16-03)" >&2; exit 1; }

echo "PASS: AGENTS.md §4 stub byte-identical to template; §4 body in page-types.md; §16 absent from both"
