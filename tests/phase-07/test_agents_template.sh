#!/usr/bin/env bash
# test_agents_template.sh -- Phase 07 Plan 03
# Asserts schema/AGENTS.template.md exists, has each of the 4 approved wizard
# placeholders at least once, and contains no Kahneman leak outside legitimate
# `See: examples/kahneman/...` pointer lines.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

TEMPLATE=schema/AGENTS.template.md
FAIL=0

[ -f "$TEMPLATE" ] || { echo "FAIL: $TEMPLATE missing"; exit 1; }

for ph in '{{PRIMARY_DOMAIN}}' '{{DEFAULT_PRIVACY}}' '{{AGENT_FILENAME}}' '{{DECAY_PROFILE}}'; do
  if ! grep -qF "$ph" "$TEMPLATE"; then
    echo "FAIL: placeholder $ph not found in $TEMPLATE"
    FAIL=1
  fi
done

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
echo "PASS: $TEMPLATE has all 4 wizard placeholders and is neutralized."
exit 0
