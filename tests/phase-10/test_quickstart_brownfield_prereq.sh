#!/usr/bin/env bash
# test_quickstart_brownfield_prereq.sh — asserts docs/quickstart.md §0 carries
# the ruamel.yaml prerequisite note scoped to brownfield onboarding with a
# forward-link to docs/reference/brownfield.md.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

qs="$REPO_ROOT/docs/quickstart.md"
grep -qF "pip install ruamel.yaml" "$qs" \
    || { echo "FAIL: quickstart missing ruamel.yaml install command" >&2; exit 1; }
grep -qF "brownfield onboarding" "$qs" \
    || { echo "FAIL: quickstart missing 'brownfield onboarding' scope qualifier" >&2; exit 1; }
grep -qF "reference/brownfield.md" "$qs" \
    || { echo "FAIL: quickstart missing forward-link to reference/brownfield.md" >&2; exit 1; }
echo "PASS: quickstart brownfield prereq note"
