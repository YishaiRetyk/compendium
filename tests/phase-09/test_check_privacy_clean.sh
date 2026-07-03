#!/usr/bin/env bash
# CI-07: bin/check-privacy.sh exits 0 on clean repo.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Use real repo root; must be clean by project invariant
invoke_tool_compat check-privacy --root "$REPO_ROOT" \
    || { echo "FAIL: check-privacy should exit 0 on clean repo" >&2; exit 1; }
echo "PASS: check-privacy clean repo exit 0"
