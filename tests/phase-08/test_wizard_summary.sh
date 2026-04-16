#!/usr/bin/env bash
# tests/phase-08/test_wizard_summary.sh -- WZRD-08: --render-to mode prints
# a completion summary `Wrote ...` block listing the rendered AGENTS.md
# with size in bytes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"
CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: --render-to completion summary prints 'Wrote' block with file+bytes (WZRD-08)"

WORK="$(mktemp_repo)"
STDOUT="$(bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --render-to "$WORK")"

if ! printf '%s\n' "$STDOUT" | grep -qE '^Wrote'; then
    echo "ASSERT FAIL: stdout missing 'Wrote' summary header" >&2
    printf '%s\n' "$STDOUT" >&2
    exit 1
fi

if ! printf '%s\n' "$STDOUT" | grep -qE 'AGENTS\.md[[:space:]]+\([0-9]+ bytes'; then
    echo "ASSERT FAIL: stdout missing 'AGENTS.md (<N> bytes, ...)' line" >&2
    printf '%s\n' "$STDOUT" >&2
    exit 1
fi

echo "PASS: --render-to emits 'Wrote' summary block with file path + byte count"
exit 0
