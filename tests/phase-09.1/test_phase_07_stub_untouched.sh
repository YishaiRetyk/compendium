#!/usr/bin/env bash
# I-3: docs/reference/examples.md stays a stub. Per D-06, Phase 09.1 must NOT touch that file.
# Wrapper re-invokes Phase-07's tests/phase-07/test_reference_stubs.sh as defense-in-depth.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

(cd "$REPO_ROOT" && bash tests/phase-07/test_reference_stubs.sh) \
    || { echo "FAIL: tests/phase-07/test_reference_stubs.sh failed — Phase 09.1 must not modify docs/reference/examples.md (D-06, D-18)" >&2; exit 1; }

echo "PASS: docs/reference/examples.md stub preserved per D-06/D-18"
