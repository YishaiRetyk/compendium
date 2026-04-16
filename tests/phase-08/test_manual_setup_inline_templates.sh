#!/usr/bin/env bash
# tests/phase-08/test_manual_setup_inline_templates.sh -- review concern #4 verification.
# Asserts Section 8 contains a self-contained decision-record heredoc with all 7 required
# section headings, critical frontmatter values, and an inline wiki/index.md append snippet
# matching Plan 03's update_index_md() wikilink format. Manual track must NOT defer the
# decision record to wizard invocation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/docs/manual-setup.md"

assert_file_exists "$DOC" "docs/manual-setup.md must exist"

# Section 8 must contain the decision-record heredoc
if ! grep -q 'cat > "wiki/decisions/dr-${TODAY}-initial-setup.md" <<EOF' "$DOC"; then
    echo "ASSERT FAIL: manual-setup.md Section 8 must contain the decision-record heredoc 'cat > \"wiki/decisions/dr-\${TODAY}-initial-setup.md\" <<EOF' (review concern #4)" >&2
    exit 1
fi

# All 7 required decision-record section headings (AGENTS.md §4.6)
for heading in 'TL;DR' 'Decision' 'Why' 'Alternatives Considered' 'Consequences' 'Affected Pages' 'Sources'; do
    if ! grep -qE "## $heading" "$DOC"; then
        echo "ASSERT FAIL: decision-record heading '## $heading' missing from inline template" >&2
        exit 1
    fi
done

# Critical frontmatter values must appear inline (no wizard invocation required)
if ! grep -q 'trigger_type: schema-update' "$DOC"; then
    echo "ASSERT FAIL: inline decision-record must contain 'trigger_type: schema-update'" >&2
    exit 1
fi
if ! grep -qE '^type: decision' "$DOC"; then
    echo "ASSERT FAIL: inline decision-record must contain 'type: decision' frontmatter" >&2
    exit 1
fi
if ! grep -qE 'affected_pages: \[\]' "$DOC"; then
    echo "ASSERT FAIL: inline decision-record must contain 'affected_pages: []' (inaugural infrastructure record per AGENTS.md §4.6)" >&2
    exit 1
fi

# Inline wiki/index.md wikilink must match Plan 03's update_index_md() output exactly
if ! grep -qF '[[dr-${TODAY}-initial-setup|Initial Wizard Setup -- ${PRIMARY_DOMAIN}]]' "$DOC"; then
    echo "ASSERT FAIL: Section 8 must contain the exact wiki/index.md wikilink format '[[dr-\${TODAY}-initial-setup|Initial Wizard Setup -- \${PRIMARY_DOMAIN}]]' (byte-parity with Plan 03)" >&2
    exit 1
fi

# Manual track must NOT defer decision-record creation to the wizard
if grep -qE '(run the wizard|invoke the wizard|bin/init-wizard\.sh).*to (generate|produce|create).*(decision|wiki/decisions)' "$DOC"; then
    echo "ASSERT FAIL: manual-setup.md defers decision-record creation to the wizard — Section 8 must be self-contained (review concern #4)" >&2
    grep -nE '(run the wizard|invoke the wizard|bin/init-wizard\.sh).*to (generate|produce|create).*(decision|wiki/decisions)' "$DOC" >&2
    exit 1
fi

echo "PASS: manual-setup.md Section 8 contains self-contained decision-record heredoc with 7 required headings + inline wiki/index.md append snippet (review concern #4)"
exit 0
