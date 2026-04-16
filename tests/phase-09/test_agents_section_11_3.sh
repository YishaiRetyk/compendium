#!/usr/bin/env bash
# AGENTS.md §11.3 has CI-mode subsection documenting all new flags + escape-hatch.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

A="$REPO_ROOT/AGENTS.md"
SECTION="$(awk '/^### 11\.3/,/^### 11\.[0-9]/' "$A" | head -n -1)"

# CI mode subsection present
echo "$SECTION" | grep -qi "CI mode" \
    || { echo "FAIL: §11.3 missing 'CI mode' subsection" >&2; exit 1; }

# All new flags documented
for flag in --format --ci --strict --skip-category --require-version --version --count-skips; do
    echo "$SECTION" | grep -q -- "$flag" \
        || { echo "FAIL: §11.3 missing flag '$flag'" >&2; exit 1; }
done

# Escape-hatch marker documented
echo "$SECTION" | grep -q "lint:expect-inferred" \
    || { echo "FAIL: §11.3 missing lint:expect-inferred marker doc" >&2; exit 1; }
echo "$SECTION" | grep -q "lint:expect-tentative" \
    || { echo "FAIL: §11.3 missing lint:expect-tentative marker doc" >&2; exit 1; }
# Immediately-above-line rule
echo "$SECTION" | grep -qi "immediately above\|line above\|line immediately" \
    || { echo "FAIL: §11.3 missing adjacency rule (immediately above)" >&2; exit 1; }

# Severity remap table (at least 3 of the known categories)
for cat in yaml orphan provenance stale gap contradiction; do
    echo "$SECTION" | grep -q "$cat" \
        || { echo "FAIL: §11.3 severity remap missing category '$cat'" >&2; exit 1; }
done

# Source-of-truth designation (per Codex MEDIUM review -- prevents spec duplication drift)
echo "$SECTION" | grep -qi "source of truth\|authoritative specification" \
    || { echo "FAIL: §11.3 CI mode should designate itself as source of truth for CI contracts" >&2; exit 1; }

echo "PASS: AGENTS.md §11.3 CI-mode subsection complete"
