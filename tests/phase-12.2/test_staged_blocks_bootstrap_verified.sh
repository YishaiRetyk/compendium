#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 8: new wiki/concepts/foo.md with
# bootstrap_stage: verified frontmatter and zero [prov:] markers ->
# NOT exempt (D-12: verified is first-class wiki content);
# bin/lint.sh --strict --staged --category provenance exits 1.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo (verified)"
type: concept
status: active
summary: "Verified-stage concept; NOT exempt from provenance gate."
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
bootstrap_stage: verified
bootstrap_date: 2026-05-04
---

Verified-stage concept body with no [prov:] markers; NOT exempt — gate must fire.
EOF
(cd "$REPO" && git add wiki/concepts/foo.md)

set +e
(cd "$REPO" && bash "$REPO_ROOT/bin/lint.sh" --strict --staged --category provenance "$REPO/wiki/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 1 "$rc" "blocked: bootstrap_stage: verified is NOT exempt"; then
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
echo "PASS: blocked: bootstrap_stage: verified is NOT exempt"
