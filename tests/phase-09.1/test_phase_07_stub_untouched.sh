#!/usr/bin/env bash
# I-3: Phase 09.1 must NOT touch docs/reference/examples.md (D-06). examples.md was
# later legitimately authored in Phase 13.1 Plan 04 — so this wrapper now defends the
# reference-doc invariant (every doc authored, no stub markers) by delegating to the
# updated Phase-07 tests/phase-07/test_reference_stubs.sh as defense-in-depth.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

(cd "$REPO_ROOT" && bash tests/phase-07/test_reference_stubs.sh) \
    || { echo "FAIL: tests/phase-07/test_reference_stubs.sh failed — reference-doc stub/authored invariant broken (D-06, D-18)" >&2; exit 1; }

echo "PASS: reference-doc invariant upheld (all docs authored, no stub markers) per D-06/D-18"
