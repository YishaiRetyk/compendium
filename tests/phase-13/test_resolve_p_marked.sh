#!/usr/bin/env bash
# FAITH-02 / D-05: #p8 slices <!-- page: 8 --> .. before <!-- page: 9 -->.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-pm.md" <<'EOF'
---
id: src-pm
title: "PM"
type: source
status: active
path: sources/2026/2026-04/pm/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/pm/source.md" <<'EOF'
<!-- page: 7 -->
PAGE7_MARKER content.

<!-- page: 8 -->
PAGE8_MARKER target content.

<!-- page: 9 -->
PAGE9_MARKER content.
EOF

write_page "$REPO" "wiki/concepts/pm.md" <<'EOF'
---
id: pmpage
title: "PMpage"
type: concept
status: active
---
A claim [prov:src-pm#p8|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "p-marked resolve run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'PAGE8_MARKER'; then
    echo "FAIL: #p8 did not resolve to the page-8 slice" >&2; echo "$out" >&2; exit 1
fi
if printf '%s' "$out" | grep -qE 'PAGE7_MARKER|PAGE9_MARKER'; then
    echo "FAIL: #p8 leaked an adjacent page (over-sliced)" >&2; echo "$out" >&2; exit 1
fi
echo "PASS: #p8 slices the bounded page-8 passage via <!-- page: N --> markers"
