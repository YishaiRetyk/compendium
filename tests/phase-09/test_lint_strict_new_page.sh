#!/usr/bin/env bash
# CI-06 / D-10: --strict fails on new (git diff status A) entity|concept|overview|comparison
# page with zero [prov:] markers. Source + decision types exempt.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo strict-missing-prov)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT
pushd "$FIXTURE" >/dev/null

# Simulate "feature branch adds a new page": start from a commit WITHOUT the
# offender (on main), then re-add it on the feature branch.
git branch pre-claim
git rm -q wiki/concepts/new-concept.md
git -c commit.gpgsign=false commit -q -m "main: drop offender"
# Pin origin/main here (claim-free main)
seed_origin_main_ref "$FIXTURE"
# Create feature branch that ADDS the offender
git checkout -q -b feature
git checkout pre-claim -- wiki/concepts/new-concept.md
git add wiki/concepts/new-concept.md
git -c commit.gpgsign=false commit -q -m "feature: add offender"

if bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ > /tmp/sn-out 2> /tmp/sn-err; then
    echo "FAIL: --strict should fail on new concept page without [prov:]" >&2
    cat /tmp/sn-out /tmp/sn-err >&2
    popd >/dev/null; exit 1
fi
# Error message mentions provenance
if ! grep -qi "prov" /tmp/sn-out /tmp/sn-err; then
    echo "FAIL: error output should mention provenance" >&2
    cat /tmp/sn-out /tmp/sn-err >&2
    popd >/dev/null; exit 1
fi

# Now change type to source → exempt
sed -i 's/^type: concept/type: source/' wiki/concepts/new-concept.md
git add . && git -c commit.gpgsign=false commit -q -m "feature: flip to source type"

bash "$REPO_ROOT/bin/lint.sh" --strict wiki/ >/dev/null 2>&1 \
    || { echo "FAIL: --strict should exempt type:source pages from provenance check" >&2; popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --strict new-page provenance + source-type exempt"
