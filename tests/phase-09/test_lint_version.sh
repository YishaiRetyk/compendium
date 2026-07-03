#!/usr/bin/env bash
# CI-08: lint --version prints LINT_VERSION and exits 0.
# Post-MIG-02 form: the expected value is read from the PORTED module
# src/compendium/lint.py (single source of truth) rather than hard-coded --
# the hard-coded form went stale at every version bump, and the pre-port sed
# against the bash `LINT_VERSION="..."` line returns empty on the Python port
# (impl-assertion inventory row, defer-to-MIG-02 -> done). The semver-shape
# assertion keeps the test non-vacuous.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

EXPECTED="$(sed -n 's/^LINT_VERSION = "\([0-9.]*\)"$/\1/p' "$REPO_ROOT/src/compendium/lint.py")"
if ! printf '%s' "$EXPECTED" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "FAIL: could not extract a semver LINT_VERSION from src/compendium/lint.py (got '$EXPECTED')" >&2
    exit 1
fi

OUT="$(invoke_tool_compat lint --version)"
if [ "$OUT" != "$EXPECTED" ]; then
    echo "FAIL: expected '$EXPECTED' (LINT_VERSION in src/compendium/lint.py), got '$OUT'" >&2
    exit 1
fi
echo "PASS: lint --version -> $OUT (matches LINT_VERSION source of truth)"
