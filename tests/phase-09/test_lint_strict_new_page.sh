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

# Now change type to source → exempt from D-10 provenance requirement.
# Flipping to source type also requires SOURCE_EXTRA_FIELDS (path, content_hash,
# ingested_at, source_type, compilation_status) per AGENTS.md §5 to avoid
# unrelated yaml-error findings that would otherwise gate --strict exit.
python3 - <<'PYEOF'
p = "wiki/concepts/new-concept.md"
text = open(p).read()
text = text.replace('type: concept', 'type: source')
# Inject required SOURCE_EXTRA_FIELDS before closing frontmatter delimiter.
extra = (
    'path: sources/new-concept.md\n'
    'content_hash: "sha256:fixture"\n'
    'ingested_at: 2026-04-16\n'
    'source_type: paper\n'
    'compilation_status: compiled\n'
)
# Find closing `---` of frontmatter (the second one) and insert before it.
first = text.find('---')
second = text.find('---', first + 3)
text = text[:second] + extra + text[second:]
open(p, 'w').write(text)
PYEOF
# Raw source file (DRFT-02 check requires the file at `path` to exist).
mkdir -p sources
echo "fixture" > sources/new-concept.md
git add .
git -c commit.gpgsign=false commit -q -m "feature: flip to source type + required fields"

# --category provenance isolates the D-10 strict provenance check so unrelated
# yaml/drift errors elsewhere in the wiki don't taint the exit-code assertion.
# (Source pages are exempt per D-10 regardless.)
bash "$REPO_ROOT/bin/lint.sh" --strict --category provenance wiki/ >/dev/null 2>&1 \
    || { echo "FAIL: --strict should exempt type:source pages from provenance check" >&2
         bash "$REPO_ROOT/bin/lint.sh" --strict --category provenance wiki/ 2>&1 >&2
         popd >/dev/null; exit 1; }

popd >/dev/null
echo "PASS: --strict new-page provenance + source-type exempt"
