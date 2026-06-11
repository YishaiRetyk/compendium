#!/usr/bin/env bash
# tests/phase-20/test_pdf_convention_doc.sh -- PDF-02 convention-doc smoke.
#
# Confirms the authoritative PDF reference exists, documents the four extraction
# fields, that frontmatter.md documents extraction_tool, and that the AGENTS.md
# routing table points at the new file.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

DOC="$REPO_ROOT/schema/reference/pdf-ingestion.md"

if [ ! -f "$DOC" ]; then
    echo "FAIL: missing $DOC" >&2
    exit 1
fi

for field in extraction_tool extraction_model extraction_date original_asset; do
    if ! grep -q "$field" "$DOC"; then
        echo "FAIL: pdf-ingestion.md does not document '$field'" >&2
        exit 1
    fi
done

if ! grep -q extraction_tool "$REPO_ROOT/schema/reference/frontmatter.md"; then
    echo "FAIL: frontmatter.md does not document extraction_tool" >&2
    exit 1
fi

if ! grep -q 'pdf-ingestion.md' "$REPO_ROOT/AGENTS.md"; then
    echo "FAIL: AGENTS.md routing table does not point at pdf-ingestion.md" >&2
    exit 1
fi

echo "PASS: test_pdf_convention_doc.sh"
