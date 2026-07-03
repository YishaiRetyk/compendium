#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 1: greenfield wiki-cloud/concepts/foo.md, status A,
# zero [prov:] markers -> bin/lint.sh --strict --staged --category provenance
# exits 1.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki-cloud/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
status: active
summary: "Test concept with no provenance."
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

Foo concept body without any provenance markers.
EOF
(cd "$REPO" && git add wiki-cloud/concepts/foo.md)

set +e
(cd "$REPO" && invoke_tool_compat lint --strict --staged --category provenance "$REPO/wiki-cloud/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 1 "$rc" "blocked: greenfield concept without [prov:]"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
if ! grep -qi "prov" /tmp/wgate-out.$$ /tmp/wgate-err.$$; then
    echo "FAIL: error output should mention provenance" >&2
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: blocked: greenfield concept without [prov:]"
