#!/usr/bin/env bash
# PRIV-05 (review HIGH #2/#3): source-derived-local-claim resolver structural contract.
# After Phase 15, the resolver collapses to a single structural predicate:
# a claim is effective-local_only iff its page OR any contributing source is under wiki-local/.
# This test asserts the POST-collapse contract via direct resolver invocation.
# Today this FAILS (current resolver uses 3-level frontmatter-based ladder;
# calling it with path-only/no-frontmatter args returns wrong answers for the new contract).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

python3 - "$REPO_ROOT" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/bin/lib')
from privacy_resolve import resolve_effective_claim_privacy as e

# Case (i): claim page is under wiki-local/ -> resolves local_only
# After collapse, the predicate: page-or-source under wiki-local/ => local_only
# Test: page_path under wiki-local/ with no frontmatter privacy field (field removed)
result = e(None, 'wiki-local/concepts/bar.md', None, None, 'sources/2026/test.md')
assert result == 'local_only', (
    f"Case (i) FAIL: page under wiki-local/ must resolve local_only, got {result!r}; "
    "review HIGH #2 — FAITH-04 must NOT silently make wiki-local/ pages cloud_safe"
)

# Case (ii): page is under wiki-cloud/, but source SUMMARY is under wiki-local/sources/ -> local_only
# This is the load-bearing case: source-tier-privacy must survive the path-prefix collapse.
# The source SUMMARY page path (not the raw source path) is what the resolver sees.
result = e(None, 'wiki-cloud/concepts/foo.md', None, None, 'wiki-local/sources/src-local.md')
assert result == 'local_only', (
    f"Case (ii) FAIL: wiki-cloud/ page citing wiki-local/sources/ summary must resolve local_only, "
    f"got {result!r}; review HIGH #2/#3 — source-tier-privacy must not be lost"
)

# Case (iii): both page and source are cloud -> resolves cloud_safe
result = e(None, 'wiki-cloud/concepts/foo.md', None, None, 'wiki-cloud/sources/src-cloud.md')
assert result == 'cloud_safe', (
    f"Case (iii) FAIL: wiki-cloud/ page citing wiki-cloud/sources/ must resolve cloud_safe, "
    f"got {result!r}"
)

print("OK: structural resolver contract verified (all 3 cases pass)")
PY
rc=$?
if [ "$rc" -ne 0 ]; then
    exit 1
fi

echo "PASS: test_resolver_structural — path-prefix collapse preserves source-tier privacy (PRIV-05)"
