#!/usr/bin/env bash
# EXPECTED_BY: 11-03
# tests/phase-11/test_02_top_level_bullets_only.sh — REVIEWS item 5: 02
# regex MUST match only top-level bullets (col 0 `-`); nested bullets
# (col 2, col 4) remain untouched. Detail-section bullets also untouched.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

TMP=$(make_fixture_repo nested-bullets-vault)
trap 'rm -rf "$TMP"' EXIT

if ! bash "$REPO_ROOT/bin/brownfield.sh" suggest --root "$TMP" >/dev/null 2>&1; then
    echo "FAIL: bin/brownfield.sh suggest not yet implemented — Plan 11-02 pending" >&2
    exit 1
fi

if ! bash "$TMP/.brownfield/migrations/02-provenance-bootstrap.sh" --apply >/dev/null 2>&1; then
    echo "FAIL: 02-provenance-bootstrap.sh --apply not yet implemented — Plan 11-03 pending" >&2
    exit 1
fi

for page in nested-one.md nested-two.md; do
    PATH_F="$TMP/wiki/concepts/$page"
    assert_file_exists "$PATH_F"

    # Each page must tag the 4 top-level bullets in TL;DR + Key Facts
    for expected in \
        '^- Top-level bullet A \(eligible\) \[epistemic:: inferred\]$' \
        '^- Top-level bullet B \(eligible\) \[epistemic:: inferred\]$' \
        '^- Top-level fact 1 \(eligible\) \[epistemic:: inferred\]$' \
        '^- Top-level fact 2 \(eligible\) \[epistemic:: inferred\]$'; do
        if ! grep -qE "$expected" "$PATH_F"; then
            echo "FAIL: top-level bullet not tagged on $page: $expected" >&2
            cat "$PATH_F" >&2
            exit 1
        fi
    done

    # Nested bullets (col 2, col 4) must NOT have gained the marker
    if grep -qE '^(  |    |      )- .*\[epistemic::' "$PATH_F"; then
        echo "FAIL: nested bullet gained epistemic marker on $page" >&2
        grep -nE '^(  |    |      )- .*\[epistemic::' "$PATH_F" >&2
        exit 1
    fi

    # Detail-section top-level bullet must NOT have gained the marker
    if grep -qE '^- Top-level but NOT in target section.*\[epistemic::' "$PATH_F"; then
        echo "FAIL: Detail-section bullet was tagged on $page (D-05 section_scan violated)" >&2
        exit 1
    fi
done

echo "PASS $NAME"; exit 0
