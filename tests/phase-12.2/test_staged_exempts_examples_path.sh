#!/usr/bin/env bash
# WGATE-02 / D-20 scenario 6: new examples/example-domain/concepts/foo.md
# with zero [prov:] markers -> path-prefix exempt (D-14); bin/lint.sh
# --strict --staged --category provenance exits 0.
#
# Per CLAUDE.md §3 template-public file rule: tests/phase-12.2/ ships to
# public paths, so use the abstract placeholder `example-domain` (not a
# real vault term).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "examples/example-domain/concepts/foo.md" <<'EOF'
---
id: foo
title: "Foo (example)"
type: concept
status: active
summary: "Test concept under examples/ path; exempt from provenance gate."
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
example: true
---

Examples/-pathed concept body with no [prov:] markers; exempt by path prefix.
EOF
(cd "$REPO" && git add examples/example-domain/concepts/foo.md)

set +e
(cd "$REPO" && bash "$REPO_ROOT/bin/lint.sh" --strict --staged --category provenance "$REPO/wiki/" "$REPO/examples/" >/tmp/wgate-out.$$ 2>/tmp/wgate-err.$$)
rc=$?
set -e

if ! assert_exit_code 0 "$rc" "exempt: examples/ path-prefix"; then
    cat /tmp/wgate-out.$$ /tmp/wgate-err.$$ >&2 || true
    rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
    exit 1
fi
rm -f /tmp/wgate-out.$$ /tmp/wgate-err.$$
echo "PASS: exempt: examples/ path-prefix"
