#!/usr/bin/env bash
# tests/phase-08/test_wizard_not_yet_implemented.sh -- Review concern #6:
# Plan 02 explicit "not yet implemented" gate. Real-run invocation (no
# --render-to AND no --dry-run) MUST exit 2 with a clear message and write
# nothing.
#
# Plan 03 will remove this gate (and either delete this test or convert it
# to assert the gate is gone) once real-run repo-root writes are wired.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

CANONICAL_ANSWERS="$REPO_ROOT/schema/fixtures/canonical-answers.yaml"

echo "TEST: real-run mode without --render-to/--dry-run exits 2 with 'not yet implemented' (review #6)"

WORK="$(mktemp_repo)"
mkdir -p "$WORK/bin" "$WORK/schema"
cp "$REPO_ROOT/bin/init-wizard.sh" "$WORK/bin/init-wizard.sh"
cp "$REPO_ROOT/schema/AGENTS.template.md" "$WORK/schema/AGENTS.template.md"
chmod +x "$WORK/bin/init-wizard.sh"

WIZARD="$WORK/bin/init-wizard.sh"
OUT_FILE="$WORK/combined.log"

set +e
bash "$WIZARD" --answers-file "$CANONICAL_ANSWERS" >"$OUT_FILE" 2>&1
RC=$?
set -e

assert_eq 2 "$RC" "real-run without --render-to/--dry-run must exit 2"

assert_grep 'not yet implemented — Plan 03 pending' "$OUT_FILE" \
    "output must contain 'not yet implemented — Plan 03 pending'"

# Verify NO files written at the fake repo root.
if [ -f "$WORK/AGENTS.md" ]; then
    echo "ASSERT FAIL: wizard wrote $WORK/AGENTS.md despite exit 2" >&2
    exit 1
fi
if [ -f "$WORK/.wizard-answers.yaml" ]; then
    echo "ASSERT FAIL: wizard wrote $WORK/.wizard-answers.yaml despite exit 2" >&2
    exit 1
fi

echo "PASS: real-run exit 2 gate active; no files written"
exit 0
