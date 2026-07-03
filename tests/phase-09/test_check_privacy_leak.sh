#!/usr/bin/env bash
# CI-07 / Phase 15: wiki-local/ PATH in docs/ (public path) -> exit 2.
# A file with wiki-local/ in its PATH under a public dir triggers the structural guard.
# A file with 'privacy: local_only' frontmatter but NO wiki-local/ in path -> exit 0.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FIXTURE="$(make_fixture_repo privacy-leak-public)"
trap 'cleanup_fixture_repo "$FIXTURE"' EXIT

# 1. Leak case: docs/wiki-local/leaked.md has wiki-local/ in path -> exit 2
# (The fixture already has docs/wiki-local/leaked.md from test setup.)
set +e
invoke_tool_compat check-privacy --root "$FIXTURE" 2>/tmp/pv-err >/dev/null
RC=$?
set -e
if [ "$RC" = "0" ]; then
    echo "FAIL: wiki-local/ path in docs/ should exit 2 (structural leak guard)" >&2
    exit 1
fi
if [ "$RC" != "2" ]; then
    echo "FAIL: expected exit 2, got $RC" >&2
    cat /tmp/pv-err >&2
    exit 1
fi
grep -q "wiki-local" /tmp/pv-err \
    || { echo "FAIL: stderr should mention wiki-local: $(cat /tmp/pv-err)" >&2; exit 1; }

# 2. Frontmatter-only mention (docs/sample.md has privacy: local_only frontmatter but
# NO wiki-local/ in its path) -> should NOT trigger the new structural path guard.
# Remove the wiki-local path trigger so we test only the non-triggering case.
rm -rf "$FIXTURE/docs/wiki-local"

set +e
invoke_tool_compat check-privacy --root "$FIXTURE" 2>/dev/null
RC_CLEAN=$?
set -e
if [ "$RC_CLEAN" != "0" ]; then
    echo "FAIL: docs/sample.md with privacy: local_only frontmatter (no wiki-local/ in path) should NOT trigger structural guard (exit $RC_CLEAN)" >&2
    exit 1
fi

echo "PASS: check-privacy structural path guard: wiki-local/ in path -> exit 2; frontmatter-only -> exit 0"
