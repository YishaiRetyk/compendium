#!/usr/bin/env bash
# tests/phase-10/test_lint_ci_downgrade_bootstrapped.sh
# Phase 10 Plan 04 (BRWN-08, --ci only per I-1 scope) — asserts
# `bin/lint.sh --ci` downgrades a yaml-category error to `info` when the
# containing page is bootstrapped (`bootstrap_stage: bootstrapped`). Uses
# --format json so the severity is machine-checkable.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

tmp="$(mktemp -d -t phase10-lint-ci-dg-XXXXXX)"
mkdir -p "$tmp/wiki-cloud/concepts" "$tmp/wiki-cloud/sources"
# Copy the bootstrapped-old.md fixture (has type: "" → yaml error).
cp "$REPO_ROOT/tests/phase-10/fixtures/bootstrapped-vault/wiki-cloud/concepts/bootstrapped-old.md" "$tmp/wiki-cloud/concepts/"
printf '# Index\n[[Old Bootstrapped Page]]\n' > "$tmp/wiki-cloud/index.md"
printf '# Log\n' > "$tmp/wiki-cloud/log.md"

json="$(invoke_tool_compat lint --ci --format json "$tmp/wiki-cloud" 2>/dev/null || true)"

# Use python3 to locate the finding for bootstrapped-old.md and assert
# severity is 'info' (downgraded from the default yaml-error severity).
python3 - <<PY
import json, sys
data = json.loads('''$json''')
hits = [f for f in data if 'bootstrapped-old.md' in f.get('path', '')]
if not hits:
    print('FAIL: no findings for bootstrapped-old.md', file=sys.stderr)
    print(json.dumps(data, indent=2), file=sys.stderr)
    sys.exit(1)
# BRWN-08 allowlist is {yaml, provenance, orphan}. Any allowlist-category
# finding on the bootstrapped page must be severity=info, NOT error.
for f in hits:
    if f['category'] in {'yaml', 'provenance', 'orphan'} and f['severity'] != 'info':
        print(f'FAIL: expected severity=info, got {f["severity"]} for allowlist category {f["category"]!r}', file=sys.stderr)
        print(json.dumps(f, indent=2), file=sys.stderr)
        sys.exit(1)
# Sanity: at least one allowlist-category hit is required to prove we're
# actually exercising the downgrade branch (not silently skipping).
allowlist_hits = [f for f in hits if f['category'] in {'yaml', 'provenance', 'orphan'}]
if not allowlist_hits:
    print('FAIL: no allowlist-category findings on bootstrapped-old.md — downgrade branch not exercised', file=sys.stderr)
    print(json.dumps(data, indent=2), file=sys.stderr)
    sys.exit(1)
print('PASS: --ci downgrades allowlist findings on bootstrapped pages to info')
PY

rm -rf "$tmp"
