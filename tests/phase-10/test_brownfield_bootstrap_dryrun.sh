#!/usr/bin/env bash
# Plan 10-03 Task 2: dry-run writes REPORT.md, emits 5 counts, does NOT write APPLIED.md,
# does NOT mutate inputs, and leaves committed expected/page.md byte-unchanged (W-2).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"

tmp=$(make_fixture_repo clean-frontmatter)
trap '[ -n "${tmp:-}" ] && [ -d "$tmp" ] && rm -rf "$tmp"' EXIT

before_input=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
before_expected=$(sha256sum "$tmp/expected/page.md" | cut -d' ' -f1)

# W-2 isolation: root at $tmp/input, NOT $tmp — avoids walking the expected/ subtree.
set +e
out=$(bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --root "$tmp/input" 2> dry.err)
rc=$?
set -e
[ "$rc" -eq 0 ] || { echo "FAIL: dry-run exit=$rc (want 0)" >&2; cat dry.err >&2; exit 1; }

for label in "Parsed:" "Would bootstrap:" "Collisions:" "Schema warnings:" "Skipped:"; do
    grep -qF "$label" dry.err || { echo "FAIL: dry-run stderr missing label '$label'" >&2; cat dry.err >&2; exit 1; }
done
grep -qF "(dry-run) Pass --apply to execute." dry.err \
    || { echo "FAIL: dry-run missing trailing invite string" >&2; cat dry.err >&2; exit 1; }
rm -f dry.err

assert_file_exists "$tmp/input/.brownfield/REPORT.md" "dry-run REPORT.md missing"

if [ -f "$tmp/input/.brownfield/APPLIED.md" ]; then
    echo "FAIL: dry-run created APPLIED.md (should not)" >&2
    exit 1
fi

after_input=$(sha256sum "$tmp/input/page.md" | cut -d' ' -f1)
after_expected=$(sha256sum "$tmp/expected/page.md" | cut -d' ' -f1)
[ "$before_input" = "$after_input" ] \
    || { echo "FAIL: dry-run mutated input/page.md (T-10-03-01)" >&2; exit 1; }
[ "$before_expected" = "$after_expected" ] \
    || { echo "FAIL: dry-run mutated expected/page.md (W-2 isolation violated)" >&2; exit 1; }

# Expected/ copy inside tmp must also byte-match the committed fixture expected/.
assert_byte_equal \
    "$REPO_ROOT/tests/phase-10/fixtures/clean-frontmatter/expected/page.md" \
    "$tmp/expected/page.md" \
    "dry-run visited expected/ subtree — W-2 isolation violated"

echo "PASS: bootstrap dry-run shape + no-mutation + W-2 isolation"
