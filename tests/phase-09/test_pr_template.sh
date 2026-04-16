#!/usr/bin/env bash
# COLAB-02: PR template has D-29 6-section structure.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

T="$REPO_ROOT/.github/pull_request_template.md"
test -f "$T" || { echo "FAIL: $T missing" >&2; exit 1; }

# All 6 sections
grep -q "^## Summary$" "$T" || { echo "FAIL: missing ## Summary" >&2; exit 1; }
grep -q "^## Ingest type$" "$T" || { echo "FAIL: missing ## Ingest type" >&2; exit 1; }
grep -q "^## Source attribution$" "$T" || { echo "FAIL: missing ## Source attribution" >&2; exit 1; }
grep -q "^## Privacy review$" "$T" || { echo "FAIL: missing ## Privacy review" >&2; exit 1; }
grep -q "^## Lint$" "$T" || { echo "FAIL: missing ## Lint" >&2; exit 1; }
grep -q "^## Expected findings" "$T" || { echo "FAIL: missing ## Expected findings" >&2; exit 1; }

# Ingest type has 6 checkbox items
for item in "new source" "update existing page" "merge pages" "supersede page" "docs-only" "other"; do
    grep -q "\- \[ \] $item" "$T" || { echo "FAIL: Ingest type missing '$item' checkbox" >&2; exit 1; }
done

# Privacy review references PRIVACY.md
grep -q "PRIVACY.md" "$T" || { echo "FAIL: Privacy review missing PRIVACY.md link" >&2; exit 1; }
grep -qE "\- \[ \] I confirm" "$T" || { echo "FAIL: Privacy review missing single checkbox" >&2; exit 1; }

# Lint has collapsible details block
grep -q "<details>" "$T" || { echo "FAIL: Lint missing <details>" >&2; exit 1; }
grep -q "<summary>lint output</summary>" "$T" || { echo "FAIL: Lint missing <summary>lint output</summary>" >&2; exit 1; }

# Expected findings mentions escape-hatch marker
grep -q "lint:expect-inferred" "$T" || { echo "FAIL: Expected findings missing lint:expect-inferred pointer" >&2; exit 1; }

echo "PASS: PR template 6-section structure"
