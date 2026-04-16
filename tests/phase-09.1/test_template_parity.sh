#!/usr/bin/env bash
# R-1 mitigation: AGENTS.md §4 and §16 bodies byte-identical to schema/AGENTS.template.md
# at offset-adjusted line ranges (RESEARCH.md §2.2).
#
# PRE-EXTRACTION (today):   AGENTS.md §4 = lines 131-559; template §4 = lines 133-561.
#                           AGENTS.md §16 = lines 1700-1785; template §16 = lines 1638-1723.
# POST-EXTRACTION (Wave 1): End line-numbers shift because the worked-example fenced blocks
#                           shrink to residue. The two files must STAY byte-identical at
#                           whatever their new line ranges are.
#
# Strategy: Lock the START of each region and use a sentinel END pattern, extracting via
# awk from "## 4." through "## 5." (exclusive) for §4, and from "## 16." through EOF
# for §16. Compare the extracted blocks with diff.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"
T="$REPO_ROOT/schema/AGENTS.template.md"

# Extract §4 body: from line matching '^## 4\. Page Types and Templates' through line
# before '^## 5\. Frontmatter Schema'. Use awk flag-based extraction (PATTERNS.md Note:
# flag-based awk replaces range-pair because range pair collapses to 1 line when start
# regex is a subset of end regex).
extract_section_4() {
    awk '
        /^## 5\. Frontmatter Schema/ { inside=0 }
        inside==1 { print }
        /^## 4\. Page Types and Templates/ { inside=1 }
    ' "$1"
}

# Extract §16 body: from '^## 16\. Appendices and Examples' through EOF.
extract_section_16() {
    awk '
        /^## 16\. Appendices and Examples/ { inside=1 }
        inside==1 { print }
    ' "$1"
}

diff <(extract_section_4 "$A") <(extract_section_4 "$T") > /tmp/phase-09.1-s4.diff \
    || { echo "FAIL: §4 body drift between AGENTS.md and schema/AGENTS.template.md" >&2; cat /tmp/phase-09.1-s4.diff >&2; exit 1; }

diff <(extract_section_16 "$A") <(extract_section_16 "$T") > /tmp/phase-09.1-s16.diff \
    || { echo "FAIL: §16 body drift between AGENTS.md and schema/AGENTS.template.md" >&2; cat /tmp/phase-09.1-s16.diff >&2; exit 1; }

echo "PASS: AGENTS.md §4 and §16 bodies byte-identical to schema/AGENTS.template.md"
