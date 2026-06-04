#!/usr/bin/env bash
# Plan 10-02 Task 2 Test 4: D-17 confidence label mapping.
# Asserts:
#   - SomeEntity.md (frontmatter type: entity) -> label=entity, confidence=high
#   - some-concept.md (frontmatter type: concept) -> label=concept, confidence=high
#   - src-2026-04-01-paper.md (frontmatter type: source) -> label=source, confidence=high
#   - vault/musings.md (no signals) -> label=unknown, confidence=unknown
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

tmp=$(make_fixture_repo scan-vault-basic)
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

bash "$REPO_ROOT/bin/brownfield.sh" scan --root "$tmp" >/dev/null 2>&1
report="$tmp/.brownfield/REPORT.md"

# SomeEntity.md → entity, high
if ! grep -E '`wiki-cloud/entities/SomeEntity.md`.*\bentity\b.*\bhigh\b' "$report" >/dev/null; then
    echo "FAIL: SomeEntity.md does not match 'entity high' in Inventory" >&2
    grep "SomeEntity" "$report" >&2 || true
    exit 1
fi

# some-concept.md → concept, high
if ! grep -E '`wiki-cloud/concepts/some-concept.md`.*\bconcept\b.*\bhigh\b' "$report" >/dev/null; then
    echo "FAIL: some-concept.md does not match 'concept high'" >&2
    grep "some-concept" "$report" >&2 || true
    exit 1
fi

# src-2026-04-01-paper.md → source, high
if ! grep -E '`wiki-cloud/sources/src-2026-04-01-paper.md`.*\bsource\b.*\bhigh\b' "$report" >/dev/null; then
    echo "FAIL: src-2026-04-01-paper.md does not match 'source high'" >&2
    grep "src-2026-04-01-paper" "$report" >&2 || true
    exit 1
fi

# vault/musings.md → unknown, unknown (or at least appears in Needs human judgment)
if ! grep -E '`vault/musings.md`.*\bunknown\b.*\bunknown\b' "$report" >/dev/null; then
    echo "FAIL: vault/musings.md does not match 'unknown unknown'" >&2
    grep "musings" "$report" >&2 || true
    exit 1
fi

echo "PASS: D-17 confidence labels"
