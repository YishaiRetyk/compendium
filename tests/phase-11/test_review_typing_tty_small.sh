#!/usr/bin/env bash
# EXPECTED_BY: 11-04
# tests/phase-11/test_review_typing_tty_small.sh — BRWN-22: small-batch
# (<20 clusters) review-typing flows through the TTY prompt path; all
# clusters can be approved via 'a' responses piped over stdin.
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

# Pipe 20 'a' (approve) lines — more than enough for small-vault clusters.
input_lines=""
for _ in $(seq 1 20); do input_lines+="a"$'\n'; done

if ! echo -n "$input_lines" | bash "$REPO_ROOT/bin/brownfield.sh" review-typing --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh review-typing not yet implemented — Plan 11-04 pending" >&2
    exit 1
fi

DECFILE="$TMP/.brownfield/page-typing-decisions.yaml"
pending=$(grep -cE 'decision:[[:space:]]*pending' "$DECFILE" || true)
if [ "$pending" -ne "0" ]; then
    echo "FAIL: review-typing left $pending pending clusters after approve-all" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
