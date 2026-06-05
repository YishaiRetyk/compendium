#!/usr/bin/env bash
# tests/phase-10/test_agents_template_parity_section_5.sh
# Phase 10 Plan 04 — POST-EXTRACTION (Phase 16): asserts AGENTS.md §5 and
# schema/AGENTS.template.md §5 carry byte-identical stub content (both are
# now 2-line stubs pointing to schema/reference/frontmatter.md).
#
# The §5 field-descriptions table (incl. bootstrap_stage / bootstrap_date rows)
# has MOVED to schema/reference/frontmatter.md in Phase 16 Plan 01. This test
# now asserts:
#   1. §5 stub is byte-identical between AGENTS.md and template
#   2. The §5 stub contains the pointer to frontmatter.md
#   3. frontmatter.md contains the bootstrap_stage and bootstrap_date rows
#
# Phase 08-04 / 09-06 / 13.1 / 16 precedent: when a successor plan changes
# the shape, the prior-phase tests are relaxed to assert the NEW invariant.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

agents="$REPO_ROOT/AGENTS.md"
template="$REPO_ROOT/schema/AGENTS.template.md"
frontmatter="$REPO_ROOT/schema/reference/frontmatter.md"

[ -f "$agents" ]      || { echo "FAIL: AGENTS.md missing" >&2; exit 1; }
[ -f "$template" ]    || { echo "FAIL: schema/AGENTS.template.md missing" >&2; exit 1; }
[ -f "$frontmatter" ] || { echo "FAIL: schema/reference/frontmatter.md missing" >&2; exit 1; }

# Extract §5 stub from "## 5." to just before "## 6."
extract_sec5() {
    awk '
        /^## 6\./ { exit }
        /^## 5\./ { in_s5 = 1 }
        in_s5 { print }
    ' "$1"
}

tmp_agents="$(mktemp)"
tmp_template="$(mktemp)"
extract_sec5 "$agents"   > "$tmp_agents"
extract_sec5 "$template" > "$tmp_template"

# ASSERTION 1: Both extracts non-empty
[ -s "$tmp_agents" ]   || { echo "FAIL: AGENTS.md §5 extract empty" >&2; exit 1; }
[ -s "$tmp_template" ] || { echo "FAIL: schema/AGENTS.template.md §5 extract empty" >&2; exit 1; }

# ASSERTION 2: §5 stub contains the frontmatter.md pointer
grep -q 'schema/reference/frontmatter.md' "$tmp_agents" \
    || { echo "FAIL: AGENTS.md §5 stub missing 'schema/reference/frontmatter.md' pointer" >&2; exit 1; }
grep -q 'schema/reference/frontmatter.md' "$tmp_template" \
    || { echo "FAIL: schema/AGENTS.template.md §5 stub missing 'schema/reference/frontmatter.md' pointer" >&2; exit 1; }

# ASSERTION 3: §5 stub byte-identical between AGENTS.md and template
if ! cmp -s "$tmp_agents" "$tmp_template"; then
    echo "FAIL: AGENTS.md §5 stub != schema/AGENTS.template.md §5 stub (byte-parity broken)" >&2
    echo "--- diff ---" >&2
    diff -u "$tmp_agents" "$tmp_template" | head -30 >&2 || true
    rm -f "$tmp_agents" "$tmp_template"
    exit 1
fi

rm -f "$tmp_agents" "$tmp_template"

# ASSERTION 4: frontmatter.md contains bootstrap_stage and bootstrap_date rows
grep -qE "^\| \`bootstrap_stage\` \| enum \|" "$frontmatter" \
    || { echo "FAIL: bootstrap_stage row missing from schema/reference/frontmatter.md" >&2; exit 1; }
grep -qE "^\| \`bootstrap_date\` \| date \|" "$frontmatter" \
    || { echo "FAIL: bootstrap_date row missing from schema/reference/frontmatter.md" >&2; exit 1; }

echo "PASS: AGENTS.md §5 stub == schema/AGENTS.template.md §5 stub (byte-parity preserved); frontmatter.md has bootstrap rows"
