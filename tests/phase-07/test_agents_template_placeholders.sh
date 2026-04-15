#!/usr/bin/env bash
# test_agents_template_placeholders.sh -- Phase 07 Plan 03 (REVIEWS.md HIGH #1)
# Asserts that the ONLY {{...}} tokens in schema/AGENTS.template.md are
# the four approved wizard placeholders (D-08). All illustrative tokens
# must use <UPPERCASE_NAME> angle-bracket syntax.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

TEMPLATE=schema/AGENTS.template.md
[ -f "$TEMPLATE" ] || { echo "FAIL: $TEMPLATE missing"; exit 1; }

APPROVED=$(printf '%s\n' '{{AGENT_FILENAME}}' '{{DECAY_PROFILE}}' '{{DEFAULT_PRIVACY}}' '{{PRIMARY_DOMAIN}}' | sort -u)
FOUND=$(grep -oE '\{\{[A-Z_]+\}\}' "$TEMPLATE" | sort -u || true)

if [ "$FOUND" != "$APPROVED" ]; then
  echo "FAIL: placeholder set mismatch"
  echo "Expected:"
  echo "$APPROVED"
  echo "Found:"
  echo "$FOUND"
  echo "Hint: illustrative tokens must use <UPPERCASE_NAME>, not {{UPPERCASE_NAME}}."
  exit 1
fi

# Also assert no {{EXAMPLE_CLUSTER_REF}} variant slipped in (D-08 rejects it).
if grep -q '{{EXAMPLE_CLUSTER_REF}}' "$TEMPLATE"; then
  echo "FAIL: {{EXAMPLE_CLUSTER_REF}} present (D-08 rejected this placeholder)"
  exit 1
fi

echo "PASS: $TEMPLATE has EXACTLY the four approved wizard placeholders."
exit 0
