#!/usr/bin/env bash
# tests/phase-20/test_pdf_epistemic_tiers.sh -- PDF-03 tiered-policy content grep.
#
# Confirms pdf-ingestion.md carries the tiered epistemic policy tokens (D-08):
# born-digital, tentative, spot-verification, and support_type: direct -- and
# that it does NOT misclassify a PDF extraction as support_type: derived.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/schema/reference/pdf-ingestion.md"

if [ ! -f "$DOC" ]; then
    echo "FAIL: missing $DOC" >&2
    exit 1
fi

for token in born-digital tentative spot-verif; do
    if ! grep -qi "$token" "$DOC"; then
        echo "FAIL: pdf-ingestion.md missing tier token '$token'" >&2
        exit 1
    fi
done

if ! grep -q 'support_type: direct' "$DOC"; then
    echo "FAIL: pdf-ingestion.md missing 'support_type: direct'" >&2
    exit 1
fi

if grep -q 'support_type: derived' "$DOC"; then
    echo "FAIL: pdf-ingestion.md must NOT classify a PDF extraction as 'support_type: derived'" >&2
    exit 1
fi

echo "PASS: test_pdf_epistemic_tiers.sh"
