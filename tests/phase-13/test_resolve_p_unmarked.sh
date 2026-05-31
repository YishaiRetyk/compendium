#!/usr/bin/env bash
# FAITH-02 / D-06: #p against an UNMARKED source -> insufficient-locator
# (NEVER feed the whole document).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-pu.md" <<'EOF'
---
id: src-pu
title: "PU"
type: source
status: active
path: sources/2026/2026-04/pu/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
# NO <!-- page: N --> markers anywhere.
write_page "$REPO" "sources/2026/2026-04/pu/source.md" <<'EOF'
WHOLE_DOC_MARKER paragraph one.

Another paragraph two.
EOF

write_page "$REPO" "wiki/concepts/pu.md" <<'EOF'
---
id: pu
title: "PU"
type: concept
status: active
---
A claim [prov:src-pu#p8|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "p-unmarked resolve run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'insufficient-locator'; then
    echo "FAIL: #p against unmarked source did not degrade to insufficient-locator" >&2
    echo "$out" >&2; exit 1
fi
# And the worklist must NOT carry the document text.
set +e
wl="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --format json 2>/dev/null)"
set -e
if printf '%s' "$wl" | grep -q 'WHOLE_DOC_MARKER'; then
    echo "FAIL: unmarked #p leaked the whole document into the worklist" >&2
    echo "$wl" >&2; exit 1
fi
echo "PASS: #p unmarked source -> insufficient-locator, never whole-document"
