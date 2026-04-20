#!/usr/bin/env bash
# test_brownfield_docs_populated.sh — asserts docs/reference/brownfield.md is
# fully populated per Phase 10-05 D-22: ≥150 lines, required section headers,
# D-02 typed-merge taxonomy, .brownfield/ artifact names, Phase-11 stubs,
# W-4 (no fifth "## Needs summary" section), I-1 (--ci-only BRWN-08 scope),
# Codex BLOCKER 2 (narrowed "gitignore-like patterns" wording).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

doc="$REPO_ROOT/docs/reference/brownfield.md"
[ -f "$doc" ] || { echo "FAIL: docs/reference/brownfield.md missing" >&2; exit 1; }
lines=$(wc -l < "$doc")
[ "$lines" -ge 150 ] || { echo "FAIL: brownfield.md has $lines lines, expected ≥150" >&2; exit 1; }

# Assert stub is gone
if grep -qF "Status: stub — populated in v1.1 Phase 10/11." "$doc"; then
    echo "FAIL: stub marker still present" >&2
    exit 1
fi

# Assert required sections present
for section in "## Prerequisites" "## scan subcommand" "## bootstrap subcommand" "## Rollback" "## suggest subcommand" "## verify subcommand" "## See also"; do
    grep -qF "$section" "$doc" \
        || { echo "FAIL: missing section heading: $section" >&2; exit 1; }
done

# Phase-11 Plan 11-05 populated the suggest + verify sections.  This test
# originally asserted ≥2 `[Populated in Phase 11]` stub markers; now that
# Phase 11 has landed, the markers are gone.  The Plan 11-05 test suite
# (test_docs_suggest_section.sh, test_docs_review_typing_section.sh,
# test_docs_verify_section.sh) owns the populated-content assertions — see
# tests/phase-11/.  The precedent for relaxing a Phase-N test after Phase-M
# (M>N) populates the referenced content is established by Plan 08-04
# (phase-07 test_docs_skeleton.sh) and Plan 09.1-02 (phase-07
# test_reference_stubs.sh).

# Assert typed-merge taxonomy present
for klass in "Class A" "Class B" "Class C"; do
    grep -qF "$klass" "$doc" \
        || { echo "FAIL: typed-merge taxonomy missing $klass" >&2; exit 1; }
done

# Assert .brownfield/ artifact names present
for artifact in "REPORT.md" "APPLIED.md" "SKIPPED.md"; do
    grep -qF "$artifact" "$doc" \
        || { echo "FAIL: artifact name missing: $artifact" >&2; exit 1; }
done

# W-4 mirror: assert no "## Needs summary" section heading
if grep -q "^## Needs summary" "$doc"; then
    echo "FAIL: brownfield.md introduces a '## Needs summary' section — D-04 mandates exactly 4 sections; orphan raw sources belong under '## Needs human judgment' per W-4" >&2
    exit 1
fi

# W-4 mirror: assert the fold-in is explicitly documented
grep -qF "Needs human judgment" "$doc" \
    || { echo "FAIL: brownfield.md missing 'Needs human judgment' section reference" >&2; exit 1; }
grep -qF "orphan raw sources" "$doc" \
    || { echo "FAIL: brownfield.md missing 'orphan raw sources' wording; W-4 fold-in not documented" >&2; exit 1; }
grep -qF "four sections" "$doc" \
    || { echo "FAIL: brownfield.md missing explicit 'four sections' D-04 structure reference" >&2; exit 1; }

# Known limitations section present (Codex review fix #10)
grep -qF "Known limitations" "$doc" \
    || { echo "FAIL: brownfield.md missing Known limitations section" >&2; exit 1; }

# I-1 mirror: assert the BRWN-08 downgrade --ci scope is documented
grep -qF "fires in \`--ci\` mode ONLY" "$doc" \
    || { echo "FAIL: brownfield.md missing BRWN-08 --ci-scope note (I-1)" >&2; exit 1; }

# Codex BLOCKER 2 mirror: .brownfield-ignore wording must be narrowed to fnmatch-based subset
if grep -qF "gitignore-grammar" "$doc"; then
    echo "FAIL: brownfield.md still uses the over-promising 'gitignore-grammar' phrase — Plan 10-02 narrowed the contract to a fnmatch-based subset; docs must use 'gitignore-like patterns' wording only" >&2
    exit 1
fi
grep -qF "gitignore-like patterns" "$doc" \
    || { echo "FAIL: brownfield.md missing the narrowed 'gitignore-like patterns' wording (Codex BLOCKER 2 fix)" >&2; exit 1; }

echo "PASS: brownfield.md fully populated (W-4 + I-1 + BLOCKER-2 mirrors enforced)"
