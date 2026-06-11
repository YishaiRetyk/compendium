#!/usr/bin/env bash
# tests/phase-20/run.sh -- Phase 20 PDF Ingestion test aggregator.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Run the whole suite from the repo root: tests use repo-relative paths via
# $REPO_ROOT, so a non-root caller cwd is harmless but we cd anyway for parity
# with the other phase aggregators.
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"
PASS=0; FAIL=0; SKIP=0
run_test() {
    local name="$1"
    # Not-yet-authored test files SKIP rather than FAIL, so the aggregator is
    # green at every commit between Wave 1 and Wave 2 (no false regression signal).
    if [ ! -f "$SCRIPT_DIR/$name" ]; then
        echo "SKIP: $name (not yet authored)"; SKIP=$((SKIP+1)); return 0
    fi
    local OUT rc
    set +e
    OUT=$(bash "$SCRIPT_DIR/$name" 2>&1); rc=$?
    set -e
    if [ "$rc" -eq 0 ]; then
        # A test may exit 0 with an in-test SKIP (e.g. model-gated assertion not
        # exercised). Annotate it so "5/5 passed" on a model-less host is not
        # mistaken for a live-exercised run (round 4). SKIP-exit-0 counts as PASS.
        if echo "$OUT" | grep -q '^SKIP:'; then
            echo "PASS: $name (in-test SKIP -- live assertions not exercised)"
        else
            echo "PASS: $name"
        fi
        PASS=$((PASS+1))
    else
        echo "FAIL: $name"; FAIL=$((FAIL+1))
    fi
}
run_test test_pdf_extract_markers.sh
run_test test_pdf_extraction_fields.sh
run_test test_pdf_convention_doc.sh
run_test test_pdf_epistemic_tiers.sh
run_test test_ingest_asset_flag.sh
echo ""
echo "PHASE 20 TESTS: $PASS/$((PASS+FAIL)) passed, $SKIP skipped"
[ "$FAIL" -eq 0 ]
