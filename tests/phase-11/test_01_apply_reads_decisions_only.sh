#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_01_apply_reads_decisions_only.sh — REVIEWS item 2
# (reworded contract): 01-page-typing.sh --apply does NOT re-classify at
# apply time. Decisions.yaml is authoritative; inject conflicting signals
# after suggest, re-apply, assert type still reflects decisions.yaml.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo small-vault-ambiguous)
trap 'rm -rf "$TMP"' EXIT

if ! bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

# Approve everything via sed on decisions
DECFILE="$TMP/.brownfield/page-typing-decisions.yaml"
sed -i 's/^\([[:space:]]*\)decision:[[:space:]]*pending/\1decision: approve/g' "$DECFILE"

if ! bash "$TMP/.brownfield/migrations/01-page-typing.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 01-page-typing.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

# Record one page's resulting type
POST_TYPE=$(grep -E '^type:' "$TMP/wiki-cloud/concepts/attention-mechanism.md" | head -1)

# Now mutate that page's body + heading to inject conflicting signals that
# a re-classifier would interpret differently (change H1 to entity-like
# proper name). We do NOT rerun suggest — decisions.yaml stays fixed.
sed -i 's/^# Attention Mechanism$/# Jane Doe (person)/' "$TMP/wiki-cloud/concepts/attention-mechanism.md"

# Re-apply 01. The page's type MUST still be decided by decisions.yaml,
# NOT reclassified from the new signals.
if ! bash "$TMP/.brownfield/migrations/01-page-typing.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 01-page-typing.sh --apply second run failed — Plan 11-03 pending" >&2
    exit 1
fi

POST2_TYPE=$(grep -E '^type:' "$TMP/wiki-cloud/concepts/attention-mechanism.md" | head -1)

if [ "$POST_TYPE" != "$POST2_TYPE" ]; then
    echo "FAIL: 01 re-classified page despite decisions.yaml being authoritative" >&2
    echo "  before: $POST_TYPE" >&2
    echo "  after:  $POST2_TYPE" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
