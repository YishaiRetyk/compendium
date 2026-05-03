#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 10: a blocked commit + git commit --no-verify
# succeeds. Sanity check on git's own --no-verify flag (D-09); this test
# asserts the contract documented in AGENTS.md §3, not new code.
#
# Strategy: clone $REPO_ROOT into a throwaway tmp dir so .githooks/ is
# present (same approach as test_hook_ordering_sync_then_gate.sh).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

TMP="$(mktemp -d -t phase12-2-noverify-XXXXXX)"
trap 'cleanup_fixture_repo "$TMP"' EXIT
git clone -q "$REPO_ROOT" "$TMP"

(cd "$TMP" && git config user.email "fixture@example.com" && \
    git config user.name "Fixture")

# Stage a greenfield concept page with no [prov:] -- normally blocked by the
# hook, but --no-verify must bypass it.
write_page "$TMP" "wiki/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
status: active
summary: "No-verify smoke test concept."
created_at: 2026-05-04
updated_at: 2026-05-04
sources: []
epistemic_status: tentative
tags: []
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: ""
---

No-verify smoke test body without [prov:] markers; --no-verify must bypass.
EOF
(cd "$TMP" && git add wiki/concepts/foo.md)

set +e
(cd "$TMP" && git -c core.hooksPath=.githooks -c commit.gpgsign=false \
    commit --no-verify -m "test: no-verify bypass smoke" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 0 "$rc" "no-verify bypass: blocked commit lands"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: no-verify bypass: blocked commit lands"
