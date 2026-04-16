#!/usr/bin/env bash
# tests/phase-08/test_wizard_template_render.sh -- WZRD-07: template render
# via 4 placeholders produces byte-equal output against the canonical fixture.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"
CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"
CANONICAL_RENDER="$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"

echo "TEST: --render-to + canonical answers produces byte-equal AGENTS.md (WZRD-07)"

WORK="$(mktemp_repo)"

bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK" >/dev/null

assert_file_exists "$WORK/AGENTS.md" "render-to must write AGENTS.md"

assert_byte_equal "$CANONICAL_RENDER" "$WORK/AGENTS.md" \
    "rendered AGENTS.md must be byte-equal to canonical fixture"

# Assert no leftover placeholders remain.
if grep -qE '\{\{[A-Z_]+\}\}' "$WORK/AGENTS.md"; then
    echo "ASSERT FAIL: rendered AGENTS.md contains leftover {{...}} placeholders" >&2
    grep -nE '\{\{[A-Z_]+\}\}' "$WORK/AGENTS.md" >&2 || true
    exit 1
fi

echo "PASS: wizard render byte-equals canonical fixture; zero leftover placeholders"
exit 0
