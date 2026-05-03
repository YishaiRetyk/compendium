#!/usr/bin/env bash
# WGATE-04 / D-20 scenario 9: pre-commit hook ordering -- sync-claude resyncs
# first (state-mutating gates run first per D-07), THEN write-gate fires.
#
# Strategy: clone $REPO_ROOT into a throwaway tmp dir so .githooks/,
# bin/sync-claude.sh, bin/lint.sh, AGENTS.md, CLAUDE.md are all present
# in the fixture. This is materially different from tests 1-8 which use
# make_bare_repo (mktemp + git init), because the live hook needs the
# real script chain.
#
# Test stages:
#   (a) introduce CLAUDE.md drift (delete a line)
#   (b) stage a wiki/concepts/foo.md greenfield page with no [prov:]
#   (c) commit via `git -c core.hooksPath=.githooks commit ...` and assert
#       exit 1 with sync-claude message (sync runs first)
#   (d) re-run commit (sync-claude is now clean) and assert exit 1 with
#       the write-gate footer line
#   (e) add [prov:src-X#sec:y] to the page, re-stage, re-commit, assert exit 0
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Clone the live repo into a throwaway tmp dir so the hook chain is real.
TMP="$(mktemp -d -t phase12-2-hook-XXXXXX)"
trap 'cleanup_fixture_repo "$TMP"' EXIT
git clone -q "$REPO_ROOT" "$TMP"

(cd "$TMP" && git config user.email "fixture@example.com" && \
    git config user.name "Fixture")

# Stage (a): introduce CLAUDE.md drift by deleting a line.
# (Using sed -i in-place; the hook's sync-claude --check should catch this.)
if [ -f "$TMP/CLAUDE.md" ]; then
    sed -i.bak '5d' "$TMP/CLAUDE.md" && rm -f "$TMP/CLAUDE.md.bak"
fi

# Stage (b): write a greenfield concept page with no [prov:].
write_page "$TMP" "wiki/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
status: active
summary: "Hook-ordering test concept."
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

Hook-ordering test body without [prov:] markers.
EOF
(cd "$TMP" && git add CLAUDE.md wiki/concepts/foo.md 2>/dev/null || git add wiki/concepts/foo.md)

# Stage (c): commit via the live hook -- sync-claude must fire first and exit 1.
set +e
(cd "$TMP" && git -c core.hooksPath=.githooks -c commit.gpgsign=false \
    commit -m "test: hook ordering stage c" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 1 "$rc" "stage c: sync-claude drift blocks first"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
if ! grep -qi "sync-claude\|CLAUDE.md" /tmp/wgate-out.$$ /tmp/wgate-err.$$; then
    echo "FAIL: stage c output should mention sync-claude or CLAUDE.md" >&2
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi

# Stage (d): re-run commit. sync-claude is now clean (it auto-resynced
# CLAUDE.md and re-staged it on the prior run). The write-gate must fire.
set +e
(cd "$TMP" && git add CLAUDE.md 2>/dev/null; \
    git -c core.hooksPath=.githooks -c commit.gpgsign=false \
    commit -m "test: hook ordering stage d" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 1 "$rc" "stage d: write-gate fires after sync clean"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
if ! grep -qi "prov" /tmp/wgate-out.$$ /tmp/wgate-err.$$; then
    echo "FAIL: stage d output should mention provenance (write-gate footer)" >&2
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi

# Stage (e): fix the page by adding a [prov:] marker; commit must succeed.
write_page "$TMP" "wiki/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
status: active
summary: "Hook-ordering test concept."
created_at: 2026-05-04
updated_at: 2026-05-04
sources:
  - src-2026-04-15-x
epistemic_status: sourced
tags: []
domains: []
supersedes:
superseded_by:
privacy: cloud_safe
aliases: []
has_contradictions: false
knowledge_domain: ""
---

Hook-ordering test body with provenance [prov:src-2026-04-15-x#sec:y|direct|2026-05-04] backing the claim.
EOF
(cd "$TMP" && git add wiki/concepts/foo.md)

set +e
(cd "$TMP" && git -c core.hooksPath=.githooks -c commit.gpgsign=false \
    commit -m "test: hook ordering stage e" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 0 "$rc" "stage e: commit succeeds with [prov:]"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: hook ordering: sync-claude first, then write-gate"
