#!/usr/bin/env bash
# tests/phase-10/test_lint_brownfield_stale_30d.sh
# Phase 10 Plan 04 (BRWN-09) — asserts `bin/lint.sh --category brownfield`
# flags bootstrapped-old.md (bootstrap_date >30 days ago) as stale, does NOT
# flag bootstrapped-fresh.md (bootstrap_date within 30 days), and emits a
# summary-info line with the bootstrapped + stale counts.
#
# To guarantee the test stays stable as calendar dates advance, the fresh
# fixture's bootstrap_date is rewritten in the tmp copy to "today". The
# "old" fixture keeps its hardcoded 2026-01-01 which is far-in-the-past
# relative to any plausible test-execution date.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

tmp="$(mktemp -d -t phase10-lint-bf-XXXXXX)"
mkdir -p "$tmp/wiki-cloud/concepts" "$tmp/wiki-cloud/sources" "$tmp/wiki-cloud/maintenance"
cp "$REPO_ROOT/tests/phase-10/fixtures/bootstrapped-vault/wiki-cloud/concepts/bootstrapped-old.md"   "$tmp/wiki-cloud/concepts/"
cp "$REPO_ROOT/tests/phase-10/fixtures/bootstrapped-vault/wiki-cloud/concepts/bootstrapped-fresh.md" "$tmp/wiki-cloud/concepts/"

# Rewrite the fresh fixture's bootstrap_date to "today" so the test stays
# stable regardless of when it runs.
TODAY="$(date -u +%Y-%m-%d)"
python3 -c "
import sys, re
p = '$tmp/wiki-cloud/concepts/bootstrapped-fresh.md'
c = open(p).read()
c = re.sub(r'^bootstrap_date:.*$', 'bootstrap_date: $TODAY', c, count=1, flags=re.MULTILINE)
c = re.sub(r'^created_at:.*$',    'created_at: $TODAY',    c, count=1, flags=re.MULTILINE)
c = re.sub(r'^updated_at:.*$',    'updated_at: $TODAY',    c, count=1, flags=re.MULTILINE)
open(p,'w').write(c)
"

# Minimal wiki index + log so lint has no structural complaints unrelated to brownfield.
printf '# Index\n' > "$tmp/wiki-cloud/index.md"
printf '# Log\n'   > "$tmp/wiki-cloud/log.md"

out="$(bash "$REPO_ROOT/bin/lint.sh" --dry-run --category brownfield "$tmp/wiki-cloud" 2>&1 || true)"

# 1) Output flags bootstrapped-old.md as stale (>30 days).
echo "$out" | grep -E 'bootstrapped-old\.md.*bootstrapped [0-9]+ days ago' -q \
    || { echo "FAIL: bootstrapped-old.md not flagged as stale" >&2; echo "---out---" >&2; echo "$out" >&2; exit 1; }

# 2) bootstrapped-fresh.md NOT flagged as stale.
if echo "$out" | grep -E 'bootstrapped-fresh\.md.*bootstrapped [0-9]+ days ago' -q; then
    echo "FAIL: bootstrapped-fresh.md was incorrectly flagged as stale" >&2
    echo "---out---" >&2
    echo "$out" >&2
    exit 1
fi

# 3) Summary-info line reports 2 bootstrapped pages, 1 stale.
echo "$out" | grep -qF 'bootstrapped pages: 2; stale (>30d): 1' \
    || { echo "FAIL: missing summary-info line 'bootstrapped pages: 2; stale (>30d): 1'" >&2; echo "---out---" >&2; echo "$out" >&2; exit 1; }

rm -rf "$tmp"
echo "PASS: lint --category brownfield flags stale bootstraps + reports counts"
