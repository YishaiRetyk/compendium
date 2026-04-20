#!/usr/bin/env bash
# EXPECTED_BY: 11-05
# tests/phase-11/test_agents_section_11_5.sh — BRWN-20: AGENTS.md §11.5
# is the Brownfield Workflow section (Option C renumber per RESEARCH
# Pitfall 1) and contains the D-01 design-principle quote verbatim.
# §11.6 is the (renumbered) Release Workflow.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

AGENTS="$REPO_ROOT/AGENTS.md"
assert_file_exists "$AGENTS"

brownfield_count=$(grep -c '^### 11\.5 Brownfield Workflow' "$AGENTS" || true)
if [ "$brownfield_count" != "1" ]; then
    echo "FAIL: expected exactly 1 '### 11.5 Brownfield Workflow' heading, got $brownfield_count" >&2
    exit 1
fi

release_at_115=$(grep -c '^### 11\.5 Release Workflow' "$AGENTS" || true)
if [ "$release_at_115" != "0" ]; then
    echo "FAIL: '### 11.5 Release Workflow' still present — Option C renumber not applied" >&2
    exit 1
fi

release_at_116=$(grep -c '^### 11\.6 Release Workflow' "$AGENTS" || true)
if [ "$release_at_116" != "1" ]; then
    echo "FAIL: expected '### 11.6 Release Workflow' (Option C renumber target), got $release_at_116" >&2
    exit 1
fi

if ! grep -q 'Review may be interactive and AI-guided; apply must always be deterministic\.' "$AGENTS"; then
    echo "FAIL: AGENTS.md missing D-01 design-principle quote verbatim" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
