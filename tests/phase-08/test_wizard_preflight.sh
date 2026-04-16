#!/usr/bin/env bash
# tests/phase-08/test_wizard_preflight.sh -- WZRD-09: pre-flight exits 3
# with stderr containing "git: not found" + docs pointer when git is missing
# from PATH. bash itself must remain reachable (we symlink it into the temp
# PATH) so the shell can still start the wizard; the wizard's preflight
# then fails git + python3 lookups.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

WIZARD="$REPO_ROOT/bin/init-wizard.sh"

echo "TEST: pre-flight fails with exit 3 + docs pointer when git missing (WZRD-09)"

# Build a minimal PATH that has bash only (so we can still invoke the wizard)
# but not git or python3 (so preflight fails both).
STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT INT TERM
BASH_BIN="$(command -v bash)"
ln -s "$BASH_BIN" "$STUB_DIR/bash"

STDERR_FILE="$STUB_DIR/stderr.log"

set +e
PATH="$STUB_DIR" bash "$WIZARD" --answers-file "$REPO_ROOT/schema/fixtures/canonical-answers.yaml" 2>"$STDERR_FILE" >/dev/null
RC=$?
set -e

assert_eq 3 "$RC" "preflight exit code should be 3"

assert_grep 'git: not found in PATH' "$STDERR_FILE" "stderr must mention git not found"
assert_grep 'docs/reference/setup-prerequisites\.md' "$STDERR_FILE" "stderr must point at docs/reference/setup-prerequisites.md"

echo "PASS: pre-flight failure returns exit 3 with clear message + docs pointer"
exit 0
