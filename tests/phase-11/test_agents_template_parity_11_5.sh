#!/usr/bin/env bash
# EXPECTED_BY: 11-05
# tests/phase-11/test_agents_template_parity_11_5.sh — BRWN-20 + D-16:
# the §11.5 body in AGENTS.md is byte-identical to the §11.5 body in
# schema/AGENTS.template.md (no template placeholders in §11.5).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

AGENTS="$REPO_ROOT/AGENTS.md"
TEMPLATE="$REPO_ROOT/schema/AGENTS.template.md"
assert_file_exists "$AGENTS"
assert_file_exists "$TEMPLATE"

tmpl_count=$(grep -c '^### 11\.5 Brownfield Workflow' "$TEMPLATE" || true)
if [ "$tmpl_count" != "1" ]; then
    echo "FAIL: schema/AGENTS.template.md missing '### 11.5 Brownfield Workflow' heading" >&2
    exit 1
fi

# Flag-based awk extraction from `### 11.5 ` inclusive to next `### 11.`
# exclusive.  Pattern-twin with Phase 9.1's test_template_parity.sh.
extract_115() {
    local file="$1"
    awk '
        /^### 11\.5 / { flag=1; print; next }
        /^### 11\./   { if (flag) { flag=0 } }
        flag          { print }
    ' "$file"
}

a_body=$(extract_115 "$AGENTS")
t_body=$(extract_115 "$TEMPLATE")

if [ "$a_body" != "$t_body" ]; then
    echo "FAIL: §11.5 body differs between AGENTS.md and schema/AGENTS.template.md" >&2
    diff <(echo "$a_body") <(echo "$t_body") | head -40 >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
