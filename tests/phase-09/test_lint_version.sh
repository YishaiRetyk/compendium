#!/usr/bin/env bash
# CI-08: bin/lint.sh --version prints LINT_VERSION and exits 0.
# The expected value is read from bin/lint.sh itself (single source of truth)
# rather than hard-coded -- the hard-coded form went stale at every version
# bump (asserted 1.7.0 while LINT_VERSION was 1.10.0; fixed in quick task
# 260703-m4f). The semver-shape assertion keeps the test non-vacuous.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

EXPECTED="$(sed -n 's/^LINT_VERSION="\([0-9.]*\)"$/\1/p' "$REPO_ROOT/bin/lint.sh")"   # noqa: direct-bin (source-read; inventoried, defer-to-MIG-02)
if ! printf '%s' "$EXPECTED" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "FAIL: could not extract a semver LINT_VERSION from bin/lint.sh (got '$EXPECTED')" >&2
    exit 1
fi

OUT="$(invoke_tool_compat lint --version)"
if [ "$OUT" != "$EXPECTED" ]; then
    echo "FAIL: expected '$EXPECTED' (LINT_VERSION in bin/lint.sh), got '$OUT'" >&2
    exit 1
fi
echo "PASS: bin/lint.sh --version -> $OUT (matches LINT_VERSION source of truth)"
