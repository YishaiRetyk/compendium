#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 2: greenfield wiki/concepts/foo.md with at least
# one [prov:src#sec:x] marker -> bin/lint.sh --strict --staged --category
# provenance exits 0.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
status: active
summary: "Test concept with provenance marker."
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

Foo concept body with provenance [prov:src-2026-04-15-x#sec:intro|direct|2026-05-04] backing the claim.
EOF
(cd "$REPO" && git add wiki/concepts/foo.md)

set +e
(cd "$REPO" && bash "$REPO_ROOT/bin/lint.sh" --strict --staged --category provenance "$REPO/wiki/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 0 "$rc" "passes: greenfield concept with [prov:]"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: passes: greenfield concept with [prov:]"
