#!/usr/bin/env bash
# COLAB-01/05/06: CONTRIBUTING.md exists with D-23 scope -- PR workflow,
# attribution, merge-conflict recipes, privacy review. NO CoC / governance.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

C="$REPO_ROOT/CONTRIBUTING.md"
test -f "$C" || { echo "FAIL: CONTRIBUTING.md missing at repo root" >&2; exit 1; }

# PR workflow steps
for step in "fork" "branch" "bin/ingest.sh" "bin/lint.sh" "PR"; do
    grep -qi "$step" "$C" || { echo "FAIL: CONTRIBUTING.md missing PR-workflow step '$step'" >&2; exit 1; }
done

# Attribution section with source-of-truth claim
grep -qi "source of truth\|authoritative" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing 'source of truth' / 'authoritative' attribution" >&2; exit 1; }
grep -q "\.git-author-map\.txt" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing .git-author-map.txt reference" >&2; exit 1; }
grep -q "contributor::" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing contributor:: documentation" >&2; exit 1; }

# Merge-conflict recipes
grep -q "wiki-cloud/log\.md" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing wiki-cloud/log.md conflict recipe" >&2; exit 1; }
grep -q "wiki-cloud/index\.md" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing wiki-cloud/index.md conflict recipe" >&2; exit 1; }
grep -qi "sort.*timestamp\|by timestamp\|chronological" "$C" \
    || { echo "FAIL: log.md recipe missing sort-by-timestamp rule" >&2; exit 1; }
grep -qi "alphabetize" "$C" \
    || { echo "FAIL: index.md recipe missing 'alphabetize' rule" >&2; exit 1; }

# .gitattributes merge=union as opt-in (D-24)
grep -q "merge=union" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing merge=union snippet" >&2; exit 1; }
grep -qiE "not committed|do NOT commit|opt[ -]in" "$C" \
    || { echo "FAIL: .gitattributes snippet missing 'not committed default' / 'opt-in' qualifier" >&2; exit 1; }

# Privacy
grep -q "PRIVACY.md" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing PRIVACY.md link" >&2; exit 1; }

# CI reference
grep -q "docs/reference/ci\.md" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing docs/reference/ci.md link" >&2; exit 1; }

# Source-of-truth link: AGENTS.md §11.3 is authoritative for the category->severity mapping (Codex MEDIUM review)
grep -qi "AGENTS\.md.*11\.3\|source of truth.*AGENTS" "$C" \
    || { echo "FAIL: CONTRIBUTING.md severity-tier section must link to AGENTS.md §11.3 as source of truth (not duplicate the table)" >&2; exit 1; }
if grep -qE "^\| \`yaml\` \|" "$C"; then
    echo "FAIL: CONTRIBUTING.md should NOT reproduce the full category->severity table -- link to AGENTS.md §11.3 instead (spec-duplication guard, Codex MEDIUM review)" >&2
    exit 1
fi

# Escape-hatch marker doc (CI-06 linkage)
grep -q "lint:expect-inferred\|lint:expect-tentative" "$C" \
    || { echo "FAIL: CONTRIBUTING.md missing escape-hatch marker documentation" >&2; exit 1; }

# D-23 scope constraint: no governance / CoC / release cadence
if grep -qi "Code of Conduct\|CoC\b" "$C"; then
    echo "FAIL: CONTRIBUTING.md contains 'Code of Conduct' -- D-23 excludes governance" >&2
    exit 1
fi
if grep -qi "release cadence\|release schedule" "$C"; then
    echo "FAIL: CONTRIBUTING.md contains release cadence -- D-23 excludes it" >&2
    exit 1
fi

echo "PASS: CONTRIBUTING.md structure + scope"
