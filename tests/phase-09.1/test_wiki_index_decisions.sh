#!/usr/bin/env bash
# I-13: wiki-cloud/index.md contains ## Decisions heading AND references the new DR.
# Note: wiki-cloud/index.md currently has no ## Decisions section (PATTERNS.md Note 2);
# Wave 1 must CREATE this section.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

IDX="$REPO_ROOT/wiki-cloud/index.md"
test -f "$IDX" || { echo "FAIL: $IDX missing" >&2; exit 1; }

grep -q '^## Decisions' "$IDX" \
    || { echo "FAIL: wiki-cloud/index.md missing '## Decisions' heading (PATTERNS Note 2: Wave 1 must create it)" >&2; exit 1; }

grep -q 'dr-2026-04-16-progressive-disclosure-extraction' "$IDX" \
    || { echo "FAIL: wiki-cloud/index.md missing dr-2026-04-16-progressive-disclosure-extraction reference" >&2; exit 1; }

echo "PASS: wiki-cloud/index.md has Decisions section with new DR entry"
