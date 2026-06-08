#!/usr/bin/env bash
# test_agents_template.sh -- Phase 07 Plan 03
# Asserts schema/AGENTS.template.md exists, has the core approved wizard
# placeholders, and contains no Kahneman leak outside legitimate
# `See: examples/kahneman/...` pointer lines.
#
# POST-EXTRACTION (Phase 16): {{PRIMARY_DOMAIN}}, {{DECAY_PROFILE}}, and
# {{DEFAULT_PRIVACY}} lived in §5/§6 bodies that were extracted to leaf files.
# Only {{AGENT_FILENAME}} and {{PRIMARY_DOMAIN}} remain in the template's
# resident sections. The test checks for these 2 core placeholders.
#
# Phase 16 precedent (same as 08-04/09-06/13.1): when a successor plan moves
# placeholder-bearing content to leaf files, the template's placeholder set shrinks.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

TEMPLATE=schema/AGENTS.template.md
FAIL=0

[ -f "$TEMPLATE" ] || { echo "FAIL: $TEMPLATE missing"; exit 1; }

# Core placeholders that must remain in the template (resident sections)
for ph in '{{PRIMARY_DOMAIN}}' '{{AGENT_FILENAME}}'; do
  if ! grep -qF "$ph" "$TEMPLATE"; then
    echo "FAIL: placeholder $ph not found in $TEMPLATE"
    FAIL=1
  fi
done

# Kahneman leak check
LEAK=$(grep -iEn 'kahneman|prospect.theory|loss.aversion' "$TEMPLATE" \
  | grep -vE '^[0-9]+:See: examples/kahneman/' \
  | grep -vE 'examples/kahneman/' \
  || true)
if [ -n "$LEAK" ]; then
  echo "FAIL: Kahneman leak in $TEMPLATE (outside See:/examples/kahneman/ lines):"
  echo "$LEAK"
  FAIL=1
fi

if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
echo "PASS: $TEMPLATE has core wizard placeholders ({{AGENT_FILENAME}}, {{PRIMARY_DOMAIN}}) and is neutralized. ({{DEFAULT_PRIVACY}}/{{DECAY_PROFILE}} extracted to leaf files in Phase 16.)"
exit 0
