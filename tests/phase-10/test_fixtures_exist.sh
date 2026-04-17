#!/usr/bin/env bash
# tests/phase-10/test_fixtures_exist.sh
# Wave-1 smoke test: asserts every BRWN-21 fixture directory is present with
# the correct sub-artifacts per the D-07 dual golden contract.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

PARSEABLE=(clean-frontmatter no-frontmatter crlf dataview-inline frontmatter-with-comments)
UNPARSEABLE=(tabs-in-yaml duplicate-yaml-keys)

for f in "${PARSEABLE[@]}"; do
    assert_file_exists "$REPO_ROOT/tests/phase-10/fixtures/$f/input/page.md" "parseable fixture input missing: $f"
    assert_file_exists "$REPO_ROOT/tests/phase-10/fixtures/$f/expected/page.md" "parseable fixture expected missing: $f"
done

for f in "${UNPARSEABLE[@]}"; do
    assert_file_exists "$REPO_ROOT/tests/phase-10/fixtures/$f/input/page.md" "unparseable fixture input missing: $f"
    assert_file_exists "$REPO_ROOT/tests/phase-10/fixtures/$f/expected-skipped-entry.md" "unparseable fixture skip-artifact missing: $f"
done

# CRLF guard: the crlf fixture input MUST contain literal \r\n bytes.
if ! grep -q $'\r' "$REPO_ROOT/tests/phase-10/fixtures/crlf/input/page.md"; then
    echo "FAIL: crlf/input/page.md should contain CR bytes but doesn't" >&2
    exit 1
fi

echo "OK: all 7 fixtures present with required sub-artifacts"
