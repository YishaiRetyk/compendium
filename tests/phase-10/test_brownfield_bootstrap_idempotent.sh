#!/usr/bin/env bash
# Plan 10-03 Task 2: BRWN-03 idempotency across a multi-file vault.
# Composes clean-frontmatter + no-frontmatter inputs into a single vault root
# (can't use make_fixture_repo directly since we need a custom vault shape).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"

vault=$(mktemp -d -t phase10-idempotent-XXXXXX)
trap '[ -n "${vault:-}" ] && [ -d "$vault" ] && rm -rf "$vault"' EXIT

cp "$REPO_ROOT/tests/phase-10/fixtures/clean-frontmatter/input/page.md" "$vault/clean.md"
cp "$REPO_ROOT/tests/phase-10/fixtures/no-frontmatter/input/page.md"    "$vault/no-fm.md"

snap() {
    (cd "$1" && find . -type f -not -path './.brownfield/*' -exec sha256sum {} + | sort)
}

# First --apply run: populates frontmatter on both files.
bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$vault" >/dev/null 2>&1
before="$(snap "$vault")"

# Second --apply run: must be byte-equal (D-10 per-file bootstrap_stage guard).
bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --apply --root "$vault" >/dev/null 2>&1
after="$(snap "$vault")"

if [ "$before" != "$after" ]; then
    echo "FAIL: bootstrap --apply is not idempotent (BRWN-03 violated)" >&2
    echo "--- before ---" >&2; echo "$before" >&2
    echo "--- after ----" >&2; echo "$after" >&2
    exit 1
fi

echo "PASS: bootstrap idempotent across multi-file vault"
