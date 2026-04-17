#!/usr/bin/env bash
# tests/phase-10/test_agents_template_parity_section_5.sh
# Phase 10 Plan 04 — asserts AGENTS.md §5 and schema/AGENTS.template.md §5
# carry byte-identical bootstrap_stage + bootstrap_date rows in the
# "### Field Descriptions" table.
#
# Scope note: the template intentionally differs from AGENTS.md in the
# illustrative yaml example block at the top of §5 (it embeds
# `{{PRIMARY_DOMAIN}}` and `{{DEFAULT_PRIVACY}}` placeholders per Phase 07 D-08).
# The field-descriptions TABLE rows, however, are byte-mirrored between the
# two files — and that is what this test locks. Range: from `### Field
# Descriptions` heading through the line before `### Source Summary
# Additional Fields`.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

agents="$REPO_ROOT/AGENTS.md"
template="$REPO_ROOT/schema/AGENTS.template.md"
[ -f "$agents" ]   || { echo "FAIL: AGENTS.md missing" >&2; exit 1; }
[ -f "$template" ] || { echo "FAIL: schema/AGENTS.template.md missing" >&2; exit 1; }

# Extract the §5 field-descriptions table via flag-based awk with sentinel
# start/end headings.
extract_sec5() {
    awk '
        /^### Field Descriptions/ { in_s5 = 1 }
        in_s5 && /^### Source Summary Additional Fields/ { exit }
        in_s5 { print }
    ' "$1"
}

tmp_agents="$(mktemp)"
tmp_template="$(mktemp)"
extract_sec5 "$agents"   > "$tmp_agents"
extract_sec5 "$template" > "$tmp_template"

# Sanity: both extracts non-empty + both contain the new rows.
[ -s "$tmp_agents" ]   || { echo "FAIL: AGENTS.md §5 extract empty" >&2; exit 1; }
[ -s "$tmp_template" ] || { echo "FAIL: schema/AGENTS.template.md §5 extract empty" >&2; exit 1; }
grep -qE "^\| \`bootstrap_stage\` \| enum \|" "$tmp_agents" \
    || { echo "FAIL: bootstrap_stage row missing from AGENTS.md §5 extract" >&2; exit 1; }
grep -qE "^\| \`bootstrap_stage\` \| enum \|" "$tmp_template" \
    || { echo "FAIL: bootstrap_stage row missing from schema/AGENTS.template.md §5 extract" >&2; exit 1; }
grep -qE "^\| \`bootstrap_date\` \| date \|" "$tmp_agents" \
    || { echo "FAIL: bootstrap_date row missing from AGENTS.md §5 extract" >&2; exit 1; }
grep -qE "^\| \`bootstrap_date\` \| date \|" "$tmp_template" \
    || { echo "FAIL: bootstrap_date row missing from schema/AGENTS.template.md §5 extract" >&2; exit 1; }

# Byte-equality assertion on the §5 extract.
if ! cmp -s "$tmp_agents" "$tmp_template"; then
    echo "FAIL: AGENTS.md §5 != schema/AGENTS.template.md §5 (byte-parity broken)" >&2
    echo "--- diff (first 50 lines) ---" >&2
    diff -u "$tmp_agents" "$tmp_template" | head -50 >&2 || true
    rm -f "$tmp_agents" "$tmp_template"
    exit 1
fi

rm -f "$tmp_agents" "$tmp_template"
echo "PASS: AGENTS.md §5 == schema/AGENTS.template.md §5 (byte-parity preserved)"
