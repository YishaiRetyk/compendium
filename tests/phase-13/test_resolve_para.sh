#!/usr/bin/env bash
# FAITH-02: #para<n> resolves the n-th blank-line-delimited body paragraph.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-pa.md" <<'EOF'
---
id: src-pa
title: "PA"
type: source
status: active
path: sources/2026/2026-04/pa/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: article
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/pa/source.md" <<'EOF'
PARA_ONE first paragraph body.

PARA_TWO second paragraph body.

PARA_THREE third paragraph body.
EOF

write_page "$REPO" "wiki/concepts/pp.md" <<'EOF'
---
id: pp
title: "PP"
type: concept
status: active
privacy: cloud_safe
---
A claim [prov:src-pa#para2|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "para resolve run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'PARA_TWO'; then
    echo "FAIL: #para2 did not resolve to the second paragraph" >&2
    echo "$out" >&2; exit 1
fi
if printf '%s' "$out" | grep -q 'PARA_ONE'; then
    echo "FAIL: #para2 leaked the first paragraph" >&2; echo "$out" >&2; exit 1
fi
echo "PASS: #para<n> resolves the n-th blank-line paragraph"
