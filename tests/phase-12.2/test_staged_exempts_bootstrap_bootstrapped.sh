#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 7: new wiki/concepts/foo.md with
# bootstrap_stage: bootstrapped frontmatter and zero [prov:] markers ->
# brownfield exempt (D-11); bin/lint.sh --strict --staged --category
# provenance exits 0.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo (bootstrapped)"
type: concept
status: active
summary: "Brownfield-bootstrapped concept; exempt from provenance gate."
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
bootstrap_stage: bootstrapped
bootstrap_date: 2026-05-04
---

Brownfield-imported concept body with no [prov:] markers; exempt because bootstrap_stage is bootstrapped.
EOF
(cd "$REPO" && git add wiki/concepts/foo.md)

set +e
(cd "$REPO" && bash "$REPO_ROOT/bin/lint.sh" --strict --staged --category provenance "$REPO/wiki/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 0 "$rc" "exempt: bootstrap_stage: bootstrapped"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: exempt: bootstrap_stage: bootstrapped"
