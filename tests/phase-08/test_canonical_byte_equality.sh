#!/usr/bin/env bash
# tests/phase-08/test_canonical_byte_equality.sh -- MANUAL-06
# Renders bin/init-wizard.sh against schema/fixtures/canonical-answers.yaml and
# asserts byte-equality vs schema/fixtures/canonical-AGENTS.md.
# This is THE drift-prevention gate (M-1/M-3 mitigation per RESEARCH.md Pitfall 1).
#
# On failure, regenerate the fixture via the wizard's render routine:
#   bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen
#   cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md
# See schema/fixtures/README.md for the full regeneration procedure.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "TEST: MANUAL-06 wizard <-> canonical-AGENTS.md byte-equality"

WORK="$(mktemp_repo)"

# Freeze time + template SHA so .wizard-answers.yaml is reproducible.
# Values must match schema/fixtures/canonical-answers.yaml metadata.
export WIZARD_GENERATED_AT="2026-04-16T00:00:00Z"
export WIZARD_TEMPLATE_SHA="<frozen-fixture>"

bash "$REPO_ROOT/bin/init-wizard.sh" \
    --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" \
    --render-to "$WORK"

# 1. AGENTS.md byte-equal to fixture
if ! cmp -s "$WORK/AGENTS.md" "$REPO_ROOT/schema/fixtures/canonical-AGENTS.md"; then
    echo "FAIL: canonical-AGENTS.md drift detected." >&2
    echo "" >&2
    echo "To regenerate the fixture (intentional drift after template change):" >&2
    echo "  bash bin/init-wizard.sh --answers-file schema/fixtures/canonical-answers.yaml --render-to /tmp/wz-regen" >&2
    echo "  cp /tmp/wz-regen/AGENTS.md schema/fixtures/canonical-AGENTS.md" >&2
    echo "  git add schema/fixtures/canonical-AGENTS.md && git commit -m 'fixtures: regenerate canonical-AGENTS.md after template change'" >&2
    echo "" >&2
    echo "See schema/fixtures/README.md for details." >&2
    echo "" >&2
    echo "Diff (first 50 lines):" >&2
    diff -u "$REPO_ROOT/schema/fixtures/canonical-AGENTS.md" "$WORK/AGENTS.md" | head -50 >&2
    exit 1
fi

# 2. CLAUDE.md byte-equal to AGENTS.md (sync-claude contract)
assert_byte_equal "$WORK/AGENTS.md" "$WORK/CLAUDE.md"

# 3. .wizard-answers.yaml exists and has the 6 expected keys
assert_file_exists "$WORK/.wizard-answers.yaml"
python3 -c "
import yaml, sys
d = yaml.safe_load(open('$WORK/.wizard-answers.yaml'))
expected = {'maintainer_name', 'primary_domain', 'agent', 'default_privacy', 'decay_profile', 'obsidian'}
got = set(d.get('answers', {}).keys())
if got != expected:
    print(f'FAIL: answer keys mismatch. expected={expected} got={got}', file=sys.stderr)
    sys.exit(1)
"

# 4. Decision record exists at deterministic path
assert_file_exists "$WORK/wiki-cloud/decisions/dr-2026-04-16-initial-setup.md"

# 5. wiki-cloud/index.md edited with exactly one ## Decisions heading
assert_file_exists "$WORK/wiki-cloud/index.md"
assert_grep '^## Decisions$' "$WORK/wiki-cloud/index.md" "Decisions subsection in index.md"
[ "$(grep -c '^## Decisions$' "$WORK/wiki-cloud/index.md")" -eq 1 ] || { echo "FAIL: expected exactly one ## Decisions heading"; exit 1; }

echo "PASS: MANUAL-06 byte-equality"
exit 0
