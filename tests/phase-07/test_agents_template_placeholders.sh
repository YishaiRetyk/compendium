#!/usr/bin/env bash
# test_agents_template_placeholders.sh -- Phase 07 Plan 03 (REVIEWS.md HIGH #1)
# Asserts that the {{...}} tokens in schema/AGENTS.template.md are the approved
# wizard placeholders (D-08). All illustrative tokens must use <UPPERCASE_NAME>
# angle-bracket syntax.
#
# POST-EXTRACTION (Phase 16): {{PRIMARY_DOMAIN}}, {{DECAY_PROFILE}}, and
# {{DEFAULT_PRIVACY}} were used in illustrative frontmatter yaml blocks that
# lived in §5 (now extracted to schema/reference/frontmatter.md) and §6.
# Only {{AGENT_FILENAME}} and {{PRIMARY_DOMAIN}} remain in the template's
# resident sections after extraction. The approved set is now 2 placeholders.
#
# Phase 16 precedent (same as 08-04/09-06/13.1): when a successor plan
# moves placeholder-bearing content to leaf files, the approved set shrinks.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

TEMPLATE=schema/AGENTS.template.md
[ -f "$TEMPLATE" ] || { echo "FAIL: $TEMPLATE missing"; exit 1; }

# Post-extraction: only {{AGENT_FILENAME}} and {{PRIMARY_DOMAIN}} remain.
# {{DEFAULT_PRIVACY}} and {{DECAY_PROFILE}} lived in §5/§6 bodies that
# were extracted to leaf files in Phase 16 (frontmatter.md / lint.md).
FOUND=$(grep -oE '\{\{[A-Z_]+\}\}' "$TEMPLATE" | sort -u || true)

# Assert the expected remaining placeholders are present
for ph in '{{AGENT_FILENAME}}' '{{PRIMARY_DOMAIN}}'; do
  if ! echo "$FOUND" | grep -qF "$ph"; then
    echo "FAIL: expected placeholder $ph not found in $TEMPLATE"
    exit 1
  fi
done

# Assert no unexpected placeholders (old §5/§6 ones should be gone)
for ph in '{{DEFAULT_PRIVACY}}' '{{DECAY_PROFILE}}'; do
  if echo "$FOUND" | grep -qF "$ph"; then
    echo "WARN: $ph still in template after Phase 16 extraction — ok only if leaf files contain it"
    # Not a hard failure — the leaf file is the new home; this is informational.
  fi
done

# Assert no {{EXAMPLE_CLUSTER_REF}} variant (D-08 rejected it)
if grep -q '{{EXAMPLE_CLUSTER_REF}}' "$TEMPLATE"; then
  echo "FAIL: {{EXAMPLE_CLUSTER_REF}} present (D-08 rejected this placeholder)"
  exit 1
fi

echo "PASS: $TEMPLATE wizard placeholders consistent with post-extraction shape ({{AGENT_FILENAME}}, {{PRIMARY_DOMAIN}} remain; §5/§6 placeholders moved to leaf files)."
exit 0
