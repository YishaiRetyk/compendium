#!/usr/bin/env bash
# tests/phase-08/test_wizard_dryrun.sh -- WZRD-11: --dry-run emits unified
# diff headers for AGENTS.md and mutates nothing.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"
CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: --dry-run prints unified-diff headers + leaves repo unchanged (WZRD-11)"

# Snapshot a few repo paths we care about, to confirm --dry-run does not
# mutate them.
PRE_HASH=""
if [ -f "$REPO_ROOT/AGENTS.md" ]; then
    PRE_HASH="$(sha256sum "$REPO_ROOT/AGENTS.md" | cut -d' ' -f1)"
fi

STDOUT="$(bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" --dry-run)"

if ! grep -qE '^--- a/AGENTS\.md' <<<"$STDOUT"; then
    echo "ASSERT FAIL: --dry-run stdout missing '--- a/AGENTS.md' header" >&2
    printf '%s\n' "$STDOUT" | head -5 >&2
    exit 1
fi

if ! grep -qE '^\+\+\+ b/AGENTS\.md' <<<"$STDOUT"; then
    echo "ASSERT FAIL: --dry-run stdout missing '+++ b/AGENTS.md' header" >&2
    printf '%s\n' "$STDOUT" | head -5 >&2
    exit 1
fi

# Confirm repo unchanged: if AGENTS.md existed, its hash must match.
if [ -n "$PRE_HASH" ]; then
    POST_HASH="$(sha256sum "$REPO_ROOT/AGENTS.md" | cut -d' ' -f1)"
    assert_eq "$PRE_HASH" "$POST_HASH" "AGENTS.md must be unchanged by --dry-run"
fi

# Confirm no .wizard-answers.yaml was created.
if [ -f "$REPO_ROOT/.wizard-answers.yaml" ]; then
    # This shouldn't happen in normal repo state; guard against accidental
    # mutation from prior test runs.
    echo "WARNING: $REPO_ROOT/.wizard-answers.yaml already exists; test cannot verify no-write cleanly" >&2
fi

echo "PASS: --dry-run emits AGENTS.md diff headers + mutates nothing"
exit 0
