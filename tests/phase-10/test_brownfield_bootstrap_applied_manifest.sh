#!/usr/bin/env bash
# Plan 10-03 Task 2: APPLIED.md is the append-only execution manifest (D-06).
# Two runs on the same vault produce two `## Run ` headers.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"

FIXTURE="clean-frontmatter"
tmp=$(make_fixture_repo "$FIXTURE")
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$tmp/input" >/dev/null 2>&1

applied="$tmp/input/.brownfield/APPLIED.md"
assert_file_exists "$applied" "APPLIED.md missing after --apply"
assert_grep "^## Run " "$applied" "APPLIED.md missing '## Run' header"
assert_grep "page.md" "$applied" "APPLIED.md missing touched-file path"

# Second --apply run appends a second `## Run ` block (D-06 append-only).
# Sleep 1 second so the UTC timestamp differs and the block header is unique.
sleep 1
bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$tmp/input" >/dev/null 2>&1

run_count=$(grep -c '^## Run ' "$applied" || true)
if [ "$run_count" -ne 2 ]; then
    echo "FAIL: APPLIED.md has $run_count '## Run' headers after 2 runs (want 2)" >&2
    cat "$applied" >&2
    exit 1
fi

echo "PASS: APPLIED.md append-only manifest records 2 runs"
