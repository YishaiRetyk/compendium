#!/usr/bin/env bash
# tests/phase-13/test_harness_red_canary.sh
# Wave-0 canary. The name is historical (REVIEW LOW); this canary PASSES.
# It proves the aggregator is wired and non-empty so `bash tests/phase-13/run.sh`
# emits `PHASE 13 TESTS: 1/1`. It does NOT assert bin/audit-claims.sh exists --
# it always passes, keeping the suite green-on-a-canary. If bin/audit-claims.sh
# already exists it prints an INFO note hinting Plan 02 should DELETE this canary
# (per the Rule-3 prior-phase-test obsolescence precedent).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
if [ -f "$REPO_ROOT/bin/audit-claims.sh" ]; then
    echo "INFO: bin/audit-claims.sh now exists — Plan 02 should remove this Wave-0 canary." >&2
fi
echo "PASS: phase-13 harness wired (Wave 0 canary)"
