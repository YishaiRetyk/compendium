#!/usr/bin/env bash
# tests/phase-13/test_page_marker_convention.sh -- Plan 13-04 Task 1.
# Asserts the §6 `<!-- page: N -->` page-marker convention (D-04/D-05/D-06/D-07)
# is documented in AGENTS.md and mirrored byte-equal into CLAUDE.md and
# schema/AGENTS.template.md.
#
# NOTE on the subsection extractor: the plan text sketches
#   awk 'f&&/^#{2,3} /{exit} /^### Page-marker convention$/{f=1} f'
# but the `{2,3}` interval is an ERE quantifier that the system awk (mawk 1.3.4)
# does NOT support, so that terminator never fires and the extraction overshoots
# to EOF. We use the mawk-safe alternation `/^###? /` instead (one or two `#`
# after the leading `###` of a level-2/3 heading), which correctly bounds the
# subsection at the next `### Support Types` heading. The acceptance INTENT --
# the Page-marker convention subsection body is byte-identical between AGENTS.md
# and the template (the schema-mirror neutrality guard, since check-neutrality.sh
# PUBLIC_PATHS excludes schema/) -- is preserved.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

AGENTS="$REPO_ROOT/AGENTS.md"
CLAUDE="$REPO_ROOT/CLAUDE.md"
TEMPLATE="$REPO_ROOT/schema/AGENTS.template.md"

fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. AGENTS.md §6 documents the marker, the insufficient-locator fallback,
#    the exclusive slice wording, and the Obsidian-invisible property.
grep -q '<!-- page:' "$AGENTS"        || fail "AGENTS.md missing '<!-- page:' marker example"
grep -qi 'insufficient-locator' "$AGENTS" || fail "AGENTS.md missing insufficient-locator fallback"
grep -qi 'exclusive' "$AGENTS"        || fail "AGENTS.md missing 'exclusive' slice wording"
grep -qi 'Obsidian' "$AGENTS"         || fail "AGENTS.md missing Obsidian-invisible property"

# 2. CLAUDE.md and the template carry the same marker text (mirror coverage).
grep -q '<!-- page:' "$CLAUDE"   || fail "CLAUDE.md missing '<!-- page:' marker (sync drift)"
grep -q '<!-- page:' "$TEMPLATE" || fail "schema/AGENTS.template.md missing '<!-- page:' marker (manual mirror)"

# 3. CLAUDE.md is byte-equal to AGENTS.md (sync-claude contract).
cmp -s "$AGENTS" "$CLAUDE" || fail "CLAUDE.md not byte-equal to AGENTS.md (run bin/sync-claude.sh)"

# 4. The "### Page-marker convention" subsection is byte-identical between
#    AGENTS.md and schema/AGENTS.template.md (neutrality-by-verbatim-copy guard
#    for the schema mirror that check-neutrality.sh does not cover).
#    mawk-safe extractor: start at the heading, stop at the next ## or ### heading.
extract_subsection() {
    awk 'f && /^###? /{exit} /^### Page-marker convention$/{f=1} f' "$1"
}
if ! diff <(extract_subsection "$AGENTS") <(extract_subsection "$TEMPLATE") >/dev/null; then
    echo "FAIL: Page-marker convention subsection diverges between AGENTS.md and schema/AGENTS.template.md" >&2
    diff <(extract_subsection "$AGENTS") <(extract_subsection "$TEMPLATE") >&2 || true
    exit 1
fi

# Guard against the broken-extractor tautology: the extracted subsection must be
# non-empty AND must NOT include the next heading line.
sub="$(extract_subsection "$AGENTS")"
[ -n "$sub" ] || fail "extracted subsection is empty (extractor did not match the heading)"
if printf '%s\n' "$sub" | grep -q '^### Support Types$'; then
    fail "extractor overshot into '### Support Types' (terminator did not fire)"
fi

echo "PASS: §6 page-marker convention documented + mirrored byte-equal across AGENTS.md / CLAUDE.md / template"
exit 0
