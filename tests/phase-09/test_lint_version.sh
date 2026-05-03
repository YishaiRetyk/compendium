#!/usr/bin/env bash
# CI-08: bin/lint.sh --version prints LINT_VERSION and exits 0.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

OUT="$(bash "$REPO_ROOT/bin/lint.sh" --version)"
if [ "$OUT" != "1.2.0" ]; then
    echo "FAIL: expected '1.2.0', got '$OUT'" >&2
    exit 1
fi
echo "PASS: bin/lint.sh --version -> 1.2.0"
