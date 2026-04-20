#!/usr/bin/env bash
# EXPECTED_BY: 11-05
# tests/phase-11/test_canonical_agents_byte_equality.sh — MANUAL-06 /
# TMPL-byte-equality: Plan 11-05 re-renders the canonical AGENTS.md
# (schema/fixtures/canonical-AGENTS.md) using the Phase 8-01 wizard
# render routine after §11.5 lands; this test asserts the re-rendered
# fixture is byte-equal to the checked-in fixture.
#
# Implementation: re-use the Phase 8 test shape (see 11-01-PLAN.md
# `test_canonical_agents_byte_equality.sh` description) — invoke
# bin/init-wizard.sh --answers-file canonical-answers.yaml --render-to
# <tmp> and compare produced AGENTS.md byte-for-byte against the
# checked-in fixture.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

CANON="$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"
ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"
TEMPLATE="$REPO_ROOT/schema/AGENTS.template.md"

assert_file_exists "$CANON"
assert_file_exists "$ANSWERS"
assert_file_exists "$TEMPLATE"

# Freeze time + template SHA to match schema/fixtures/canonical-answers.yaml
# metadata so .wizard-answers.yaml is reproducible.
export WIZARD_GENERATED_AT="2026-04-16T00:00:00Z"
export WIZARD_TEMPLATE_SHA="<frozen-fixture>"

WORK="$(mktemp -d -t wz-canon-agents-XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

bash "$REPO_ROOT/bin/init-wizard.sh" \
    --answers-file "$ANSWERS" \
    --render-to "$WORK" >/dev/null

if ! cmp -s "$WORK/AGENTS.md" "$CANON"; then
    echo "FAIL: re-rendered canonical AGENTS.md differs from checked-in schema/fixtures/canonical-AGENTS.md" >&2
    echo "" >&2
    echo "Regenerate the fixture after a template change via:" >&2
    echo "  bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen" >&2
    echo "  cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md" >&2
    echo "" >&2
    echo "Diff (first 50 lines):" >&2
    diff -u "$CANON" "$WORK/AGENTS.md" | head -50 >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
