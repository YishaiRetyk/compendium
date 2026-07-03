#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 3: modified existing wiki-cloud/concepts/foo.md (status M,
# not A) without [prov:] markers -> bin/lint.sh --strict --staged --category
# provenance exits 0. Only status-A pages gate.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

# Step 1: create page WITHOUT [prov:] and commit it as part of seed history.
write_page "$REPO" "wiki-cloud/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
status: active
summary: "Test concept that already exists in seed history."
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

Original foo body, no provenance.
EOF
(cd "$REPO" && git add wiki-cloud/concepts/foo.md && \
    git -c commit.gpgsign=false commit -q -m "seed: add foo concept (no prov)")

# Step 2: modify the existing page (NOT add a [prov:]), stage it.
write_page "$REPO" "wiki-cloud/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo"
type: concept
status: active
summary: "Test concept that already exists in seed history."
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

Modified foo body, still no provenance, but status is M not A.
EOF
(cd "$REPO" && git add wiki-cloud/concepts/foo.md)

set +e
(cd "$REPO" && invoke_tool_compat lint --strict --staged --category provenance "$REPO/wiki-cloud/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 0 "$rc" "passes: modified existing (status M), no [prov:] required"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: passes: modified existing (status M), no [prov:] required"
