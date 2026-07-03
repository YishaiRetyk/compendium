#!/usr/bin/env bash
# tests/phase-20/test_pdf_extraction_fields.sh -- PDF-02 conditional-lint unit.
#
# Drives bin/lint.sh against a fixture WIKI_ROOT (the WIKI_ROOT env override
# selects the scan dir; default is wiki-cloud/). Asserts on the CONTENT of the
# finding lines, never the bare exit code (default-mode lint.sh always exits 0;
# findings print to STDERR as "  [sev] path: msg" -- the 2>&1 capture is
# MANDATORY, a stdout-only capture sees zero findings and asserts vacuously).
#
# TOP-5 WINDOW (verified): lint prints at most 5 finding lines to stderr. For
# this single-page fixture tree it cannot truncate -- but it is an implicit
# invariant: a red Variant A/C with no matching line means the fixture has 6+
# unrelated findings crowding out the target -- fix the fixture, not the
# assertion.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/sources"

FIXTURE_PAGE_NAME="src-fixture-pdf.md"
FIXTURE="$TMP/sources/$FIXTURE_PAGE_NAME"

# Base + source-extra fields composed to lint clean on their own; the PDF
# extraction fields are varied per-variant below.
write_fixture() {
    # $1 = original_asset value; remaining args appended verbatim (extraction_*)
    local oa="$1"; shift
    {
        cat <<EOF
---
id: src-fixture-pdf
title: "Fixture PDF Source"
type: source
status: active
summary: "Fixture source page used by the phase-20 lint test."
created_at: 2026-06-11
updated_at: 2026-06-11
sources: []
epistemic_status: sourced
tags:
- fixture
domains:
- testing
supersedes: null
superseded_by: null
aliases:
- "Fixture PDF Source"
has_contradictions: false
knowledge_domain: software
example: false
path: sources/2026/2026-06/2026-06-11-fixture-pdf/source.md
url: "https://example.invalid/fixture.pdf"
content_hash: "sha256:0000000000000000000000000000000000000000000000000000000000000000"
ingested_at: 2026-06-11
source_type: paper
compilation_status: pending
original_asset: ${oa}
EOF
        for line in "$@"; do
            printf '%s\n' "$line"
        done
        cat <<'EOF'
---

## TL;DR

Fixture body.
EOF
    } > "$FIXTURE"
}

# Variant A: original_asset=*.pdf but extraction_model OMITTED -> missing-field error.
write_fixture "scan.pdf" \
    'extraction_tool: olmocr' \
    'extraction_date: 2026-06-11'
OUTPUT=$(WIKI_ROOT="$TMP" invoke_tool_compat lint --dry-run --category yaml 2>&1)
if ! echo "$OUTPUT" | grep -q 'extraction'; then
    echo "FAIL: Variant A -- expected a missing-extraction-field finding, got none" >&2
    echo "$OUTPUT" >&2
    exit 1
fi

# Variant B: all four fields present -> zero findings for the fixture page.
write_fixture "scan.pdf" \
    'extraction_tool: olmocr' \
    'extraction_model: "richardyoung/olmocr2:7b-q8"' \
    'extraction_date: 2026-06-11'
OUTPUT=$(WIKI_ROOT="$TMP" invoke_tool_compat lint --dry-run --category yaml 2>&1)
if echo "$OUTPUT" | grep -q 'missing.*extraction'; then
    echo "FAIL: Variant B -- a missing-extraction finding fired with all fields present" >&2
    echo "$OUTPUT" >&2
    exit 1
fi
# Anchor on the finding-line shape, NOT the bare page name (a future verbose
# line echoing scanned filenames must not false-fail this).
if echo "$OUTPUT" | grep -E '^\s*\[(error|warning)\]' | grep -q "$FIXTURE_PAGE_NAME"; then
    echo "FAIL: Variant B -- fixture page produced an error/warning finding (expected zero)" >&2
    echo "$OUTPUT" >&2
    exit 1
fi

# Variant C: all four fields but original_asset has a directory component ->
# the bare-co-located-filename guard must fire.
write_fixture "/tmp/scan.pdf" \
    'extraction_tool: olmocr' \
    'extraction_model: "richardyoung/olmocr2:7b-q8"' \
    'extraction_date: 2026-06-11'
OUTPUT=$(WIKI_ROOT="$TMP" invoke_tool_compat lint --dry-run --category yaml 2>&1)
if ! echo "$OUTPUT" | grep -q 'bare co-located'; then
    echo "FAIL: Variant C -- expected a bare-co-located-filename finding, got none" >&2
    echo "$OUTPUT" >&2
    exit 1
fi

echo "PASS: test_pdf_extraction_fields.sh"
