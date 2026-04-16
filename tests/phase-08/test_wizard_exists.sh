#!/usr/bin/env bash
# tests/phase-08/test_wizard_exists.sh -- WZRD-01: wizard script exists,
# is executable, syntax-clean, and --help advertises all 4 flags including
# the `(internal — CI/testing only)` marker on --render-to (review #5).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"

echo "TEST: bin/init-wizard.sh exists, executable, advertises all flags (WZRD-01)"

assert_file_exists "$WIZARD" "bin/init-wizard.sh must exist"

if [ ! -x "$WIZARD" ]; then
    echo "ASSERT FAIL: bin/init-wizard.sh not executable" >&2
    exit 1
fi

if ! bash -n "$WIZARD"; then
    echo "ASSERT FAIL: bin/init-wizard.sh syntax error" >&2
    exit 1
fi

HELP_OUT="$(bash "$WIZARD" --help)"

for flag in "--answers-file" "--dry-run" "--render-to" "--help"; do
    if ! printf '%s\n' "$HELP_OUT" | grep -qE -- "$flag"; then
        echo "ASSERT FAIL: --help output missing flag $flag" >&2
        exit 1
    fi
done

if ! printf '%s\n' "$HELP_OUT" | grep -q 'internal — CI/testing only'; then
    echo "ASSERT FAIL: --render-to not marked 'internal — CI/testing only' in --help (review #5)" >&2
    exit 1
fi

echo "PASS: bin/init-wizard.sh exists + advertises all flags + marks --render-to internal"
exit 0
