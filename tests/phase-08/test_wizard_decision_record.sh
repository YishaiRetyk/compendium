#!/usr/bin/env bash
# tests/phase-08/test_wizard_decision_record.sh -- WZRD-10: initial decision
# record at wiki/decisions/dr-<TODAY>-initial-setup.md conforms to AGENTS.md
# §4.6 -- type=decision, trigger_type=schema-update, affected_pages=[],
# all 7 required sections present, no leftover {{...}} placeholders.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"
CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: initial decision record schema conformance (WZRD-10)"

WORK="$(mktemp_repo)"

WIZARD_GENERATED_AT=2026-04-16T12:00:00Z WIZARD_TEMPLATE_SHA=fixed-sha \
    bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK" >/dev/null

DR="$WORK/wiki/decisions/dr-2026-04-16-initial-setup.md"
assert_file_exists "$DR" "decision record must exist at dr-<TODAY>-initial-setup.md"

# Frontmatter fields.
assert_grep '^type: decision$' "$DR" "type: decision must be in frontmatter"
assert_grep '^trigger_type: schema-update$' "$DR" "trigger_type: schema-update must be in frontmatter"
assert_grep '^affected_pages: \[\]$' "$DR" "affected_pages: [] must be in frontmatter"
assert_grep '^privacy: cloud_safe$' "$DR" "privacy: cloud_safe must be in frontmatter"
assert_grep '^created_at: 2026-04-16$' "$DR" "created_at must be TODAY-derived from WIZARD_GENERATED_AT"
assert_grep '^updated_at: 2026-04-16$' "$DR" "updated_at must be TODAY-derived from WIZARD_GENERATED_AT"
assert_grep '^knowledge_domain: software$' "$DR" "knowledge_domain: software must be in frontmatter"
assert_grep '^status: active$' "$DR" "status: active must be in frontmatter"
assert_grep '^epistemic_status: sourced$' "$DR" "epistemic_status: sourced must be in frontmatter"
assert_grep '^has_contradictions: false$' "$DR" "has_contradictions: false must be in frontmatter"
assert_grep '^id: dr-2026-04-16-initial-setup$' "$DR" "id must match filename slug"

# All 7 required sections present (AGENTS.md §4.6 ordering).
section_count="$(grep -cE '^## (TL;DR|Decision|Why|Alternatives Considered|Consequences|Affected Pages|Sources)$' "$DR")"
assert_eq 7 "$section_count" "all 7 required sections must be present"

# No leftover placeholders after render.
assert_no_grep '\{\{[A-Z_]+\}\}' "$DR" "no leftover {{PLACEHOLDER}} tokens allowed post-render"

echo "PASS: decision record schema conformance verified (7 sections + frontmatter fields + no leftovers)"
exit 0
