#!/usr/bin/env bash
# test_agents_template_placeholders.sh -- Phase 07 Plan 03 (REVIEWS.md HIGH #1)
# Asserts that the {{...}} tokens in schema/AGENTS.template.md are the approved
# wizard placeholders (D-08). All illustrative tokens must use <UPPERCASE_NAME>
# angle-bracket syntax.
#
# POST-EXTRACTION (Phase 16): {{DEFAULT_PRIVACY}} and {{DECAY_PROFILE}} lived in
# illustrative §5/§6 carrier lines (a `privacy_default:` frontmatter line and a
# §6 decay sentence). Phase 16 extracted §5/§6 and DROPPED both carrier lines
# rather than relocating them — privacy is now structural (Phase 15, §13), so the
# privacy_default line is obsolete, and the decay profile is recorded only in
# .wizard-answers.yaml + the initial decision record, not rendered into the spec
# (REF-10 DR records this intentional drop). The approved placeholder set is
# therefore EXACTLY {{AGENT_FILENAME}} and {{PRIMARY_DOMAIN}}.
#
# This test asserts that EXACT set (not a presence subset) so that any new,
# typo'd, or re-introduced {{...}} placeholder fails CI — bin/init-wizard.sh
# only substitutes these two tokens, so any other is an unrenderable leftover.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

TEMPLATE=schema/AGENTS.template.md
[ -f "$TEMPLATE" ] || { echo "FAIL: $TEMPLATE missing"; exit 1; }

# The exact approved set, sorted (must match bin/init-wizard.sh `subs`).
APPROVED=$(printf '%s\n' '{{AGENT_FILENAME}}' '{{PRIMARY_DOMAIN}}' | sort -u)
FOUND=$(grep -oE '\{\{[A-Z_]+\}\}' "$TEMPLATE" | sort -u || true)

if [ "$FOUND" != "$APPROVED" ]; then
  echo "FAIL: template placeholder set does not match the approved set."
  echo "  Approved (exact): $(echo "$APPROVED" | tr '\n' ' ')"
  echo "  Found:            $(echo "$FOUND" | tr '\n' ' ')"
  echo "  Any extra token (e.g. a re-introduced {{DEFAULT_PRIVACY}}/{{DECAY_PROFILE}}"
  echo "  or a typo) is an unrenderable leftover — bin/init-wizard.sh substitutes only"
  echo "  {{AGENT_FILENAME}} and {{PRIMARY_DOMAIN}}."
  exit 1
fi

echo "PASS: $TEMPLATE wizard placeholders are EXACTLY the approved set ({{AGENT_FILENAME}}, {{PRIMARY_DOMAIN}})."
exit 0
