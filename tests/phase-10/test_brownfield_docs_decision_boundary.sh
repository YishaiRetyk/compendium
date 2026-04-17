#!/usr/bin/env bash
# test_brownfield_docs_decision_boundary.sh — asserts the D-02 decision-boundary
# one-liner and the typed-merge mechanical-vs-judgment quote appear verbatim in
# docs/reference/brownfield.md. Locks the Phase 10-03 handoff contract that the
# docs must quote these strings exactly.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

doc="$REPO_ROOT/docs/reference/brownfield.md"

# Verbatim D-02 decision-boundary one-liner
grep -qF "Skip on parse failure or unsafe structure; merge on parseable metadata; warn whenever preserved values may not satisfy the schema." "$doc" \
    || { echo "FAIL: verbatim D-02 decision-boundary one-liner missing" >&2; exit 1; }

# Typed-merge decision-boundary quote
grep -qF "Brownfield bootstrap preserves existing parseable frontmatter values, injects only absent required sentinel fields" "$doc" \
    || { echo "FAIL: typed-merge mechanical-vs-judgment quote missing" >&2; exit 1; }

echo "PASS: brownfield.md contains D-02 verbatim quotes"
