#!/usr/bin/env bash
# Asserts bin/release.sh --dry-run's printed INCLUDES/EXCLUDES file set.
# REVIEWS.md HIGH #2 on 07-05: allowlist-based staging must be independently
# assertable from the dry-run output.
set -u

cd "$(dirname "$0")/../.."

OUT=$(bash bin/release.sh --remote dummy://test --dry-run 2>&1)
RC=$?
if [ "$RC" -ne 0 ]; then
    echo "FAIL: dry-run exited $RC; cannot proceed with allowlist assertions"
    exit 1
fi

FAILED=0

# --- Negative assertions (EXCLUDES set) ---
EXCLUDED=(
  ".planning"
  ".brownfield"
  "wiki/entities"
  "wiki/concepts"
  "wiki/comparisons"
  "wiki/overviews"
  "wiki/sources"
)
for p in "${EXCLUDED[@]}"; do
    if ! echo "$OUT" | grep -q "EXCLUDES: $p"; then
        echo "FAIL: EXCLUDES: $p not listed in dry-run output"
        FAILED=1
    fi
    # Also ensure p does NOT appear as an INCLUDES entry.
    if echo "$OUT" | grep "INCLUDES:" | grep -qE "[[:space:]]$p$|[[:space:]]$p/"; then
        echo "FAIL: $p appears in INCLUDES set (should be excluded)"
        FAILED=1
    fi
done

# --- Positive assertions (INCLUDES set) ---
INCLUDED=(
  "README.md"
  "LICENSE"
  "PRIVACY.md"
  "AGENTS.md"
  "CLAUDE.md"
  "examples/kahneman"
)
for p in "${INCLUDED[@]}"; do
    if ! echo "$OUT" | grep -q "INCLUDES: $p"; then
        echo "FAIL: INCLUDES: $p not listed in dry-run output"
        FAILED=1
    fi
done

if [ "$FAILED" -eq 0 ]; then
    echo "PASS: release.sh allowlist dry-run asserts correct EXCLUDES and INCLUDES."
    exit 0
fi
exit 1
