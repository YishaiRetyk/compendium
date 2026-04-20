#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_review_typing_validates_override_label.sh — REVIEWS
# item 11: override flow rejects invalid type labels (not in VALID_ENUMS)
# without mutating decisions.yaml.
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

DECFILE="$TMP/.brownfield/page-typing-decisions.yaml"

# Pipe an override attempt with an INVALID label, then skip remaining prompts.
# Stdin: `o` (override), `<path>`, `<invalid label>`, then 's' to skip the rest.
input=$'o\nwiki/concepts/attention-mechanism.md\nbadlabel\n'
for _ in $(seq 1 20); do input+=$'s\n'; done

set +e
echo -n "$input" | bash "$REPO_ROOT/bin/brownfield.sh" review-typing --root "$TMP" >/dev/null 2>stderr.txt
ec=$?
set -e

# Wave-0 stub detection
if grep -q "not yet implemented" stderr.txt 2>/dev/null; then
    rm -f stderr.txt
    echo "FAIL: review-typing hit the Wave-0 stub — Plan 11-04 pending" >&2
    exit 1
fi

if ! grep -qiE 'invalid label|not a valid type|unknown label' stderr.txt; then
    echo "FAIL: review-typing did not reject 'badlabel' with an invalid-label message" >&2
    cat stderr.txt >&2 || true
    rm -f stderr.txt
    exit 1
fi

if grep -q 'badlabel' "$DECFILE"; then
    echo "FAIL: decisions.yaml contains 'badlabel' — invalid label was written through" >&2
    rm -f stderr.txt
    exit 1
fi

rm -f stderr.txt
echo "PASS $NAME"; exit 0
