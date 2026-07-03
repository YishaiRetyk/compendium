#!/usr/bin/env bash
# D-09: escape-hatch marker exempts [inferred] claim when placed on line
# IMMEDIATELY above claim. Blank line or id mismatch invalidates exemption.
# Uses PR-diff setup (origin/main pinned at claim-free commit) so the claim
# addition is in the diff and subject to --strict scope rules.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo strict-escape-hatch)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Pin origin/main at a PRE-claim state, then re-add the marker+claim on feature.
git branch pre-claim
python3 - <<'PYEOF'
p = "wiki-cloud/concepts/attention.md"
text = open(p).read().splitlines()
# Remove the marker AND the epistemic line so main is "pre-PR"
kept = [ln for ln in text if ('lint:expect-inferred' not in ln and 'epistemic:: inferred' not in ln)]
open(p, 'w').write('\n'.join(kept) + '\n')
PYEOF
git add -A && git -c commit.gpgsign=false commit -q -m "main: remove marker+claim"
seed_origin_main_ref "$FIXTURE"
git checkout -q -b feature
git checkout pre-claim -- wiki-cloud/concepts/attention.md  # restore marker+claim
git add -A && git -c commit.gpgsign=false commit -q -m "feature: re-add marker+claim"

# 1. Marker directly above claim → exempt (D-09)
invoke_tool_compat lint --strict wiki-cloud/ >/dev/null 2>&1 \
    || { echo "FAIL: marker on line above claim should exempt (D-09)" >&2; popd >/dev/null; exit 1; }

# 1b. Exempted claim surfaces as skip-count info finding in JSON mode
invoke_tool_compat lint --strict --format json wiki-cloud/ > /tmp/eh.json 2>/dev/null || true
assert_json_has_finding /tmp/eh.json skip-count info \
    || { echo "FAIL: exempted claim should emit skip-count info finding" >&2; popd >/dev/null; exit 1; }

# 2. Blank line between marker and claim → invalidates
python3 - <<'PYEOF'
p = "wiki-cloud/concepts/attention.md"
text = open(p).read().splitlines()
for i, line in enumerate(text):
    if line.startswith('<!-- lint:expect-inferred'):
        text.insert(i+1, '')  # blank line between marker and claim
        break
open(p, 'w').write('\n'.join(text) + '\n')
PYEOF
git add . && git -c commit.gpgsign=false commit -q -m "insert blank line"

if invoke_tool_compat lint --strict wiki-cloud/ >/dev/null 2>&1; then
    echo "FAIL: blank line between marker and claim should invalidate exemption" >&2
    popd >/dev/null; exit 1
fi

# 3. Restore & corrupt id match
git reset --hard HEAD~1 >/dev/null 2>&1
sed -i 's/id=attention/id=wrong-id/' wiki-cloud/concepts/attention.md
git add . && git -c commit.gpgsign=false commit -q -m "corrupt id"
if invoke_tool_compat lint --strict wiki-cloud/ >/dev/null 2>&1; then
    echo "FAIL: marker id mismatch should invalidate exemption" >&2
    popd >/dev/null; exit 1
fi

popd >/dev/null
echo "PASS: escape-hatch marker (adjacent + blank-line-invalidates + id-match) with PR-diff scope"
