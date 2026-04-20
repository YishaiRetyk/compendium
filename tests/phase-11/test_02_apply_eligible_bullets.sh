#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_02_apply_eligible_bullets.sh — D-05 + BRWN-15:
# --apply marks eligible TL;DR + Key Facts bullets with [epistemic:: inferred]
# and NEVER touches Detail-section bullets.
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

if ! bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 02-provenance-bootstrap.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

PAGE="$TMP/wiki/concepts/attention-mechanism.md"
assert_file_exists "$PAGE"

# At least one TL;DR / Key Facts bullet gained [epistemic:: inferred]
tagged=$(grep -cE '^- .* \[epistemic:: inferred\]$' "$PAGE" || true)
if [ "$tagged" -lt "1" ]; then
    echo "FAIL: 02 --apply did not tag any TL;DR/Key Facts bullets on $PAGE" >&2
    cat "$PAGE" >&2
    exit 1
fi

# Detail-section content must not have gained the marker anywhere.
awk '/^## Detail/{flag=1; next} /^## /{flag=0} flag' "$PAGE" > /tmp/detail-section.$$
if grep -qE '\[epistemic:: inferred\]' /tmp/detail-section.$$; then
    echo "FAIL: 02 tagged Detail-section content (forbidden by D-05)" >&2
    cat /tmp/detail-section.$$ >&2
    rm -f /tmp/detail-section.$$
    exit 1
fi
rm -f /tmp/detail-section.$$

echo "PASS $NAME"; exit 0
