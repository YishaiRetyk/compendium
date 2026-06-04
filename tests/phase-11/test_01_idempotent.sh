#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_01_idempotent.sh — BRWN-13: running --apply twice
# produces zero byte diff on the second run.
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

sed -i 's/^\([[:space:]]*\)decision:[[:space:]]*pending/\1decision: approve/g' \
    "$TMP/.brownfield/page-typing-decisions.yaml"

if ! bash "$TMP/.brownfield/migrations/01-page-typing.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 01-page-typing.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

# Commit current state so we can diff after second apply
(cd "$TMP" && git add -A && git -c commit.gpgsign=false commit -q -m "post-first-apply")

# Second apply
bash "$TMP/.brownfield/migrations/01-page-typing.sh" --apply >/dev/null 2>&1

dirty=$(cd "$TMP" && git status --porcelain -- 'wiki-cloud/')
if [ -n "$dirty" ]; then
    echo "FAIL: second --apply was not idempotent — wiki-cloud/ changed:" >&2
    echo "$dirty" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
