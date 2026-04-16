#!/usr/bin/env bash
# Cross-link integrity: ci.md -> PRIVACY.md/AGENTS.md/lint.yml; index.md -> ci.md + CONTRIBUTING.md
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CI="$REPO_ROOT/docs/reference/ci.md"
IDX="$REPO_ROOT/docs/reference/index.md"

# ci.md outbound links
grep -q "PRIVACY\.md" "$CI" || { echo "FAIL: ci.md missing link to PRIVACY.md" >&2; exit 1; }
grep -q "AGENTS\.md" "$CI" || { echo "FAIL: ci.md missing link to AGENTS.md" >&2; exit 1; }
grep -q "lint\.yml\|workflows/lint" "$CI" || { echo "FAIL: ci.md missing link to .github/workflows/lint.yml" >&2; exit 1; }
grep -q "CONTRIBUTING\.md" "$CI" || { echo "FAIL: ci.md missing link to CONTRIBUTING.md" >&2; exit 1; }

# index.md cross-links
test -f "$IDX" || { echo "FAIL: $IDX missing" >&2; exit 1; }
grep -q "ci\.md" "$IDX" || { echo "FAIL: docs/reference/index.md missing ci.md link" >&2; exit 1; }
grep -q "CONTRIBUTING\.md" "$IDX" \
    || { echo "FAIL: docs/reference/index.md should link to CONTRIBUTING.md" >&2; exit 1; }

echo "PASS: docs cross-links integrity"
