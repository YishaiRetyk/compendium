#!/usr/bin/env bash
# FAITH-02: #img<n> -> skipped-nontext.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-im.md" <<'EOF'
---
id: src-im
title: "IM"
type: source
status: active
path: sources/2026/2026-04/im/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: image
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/im/source.md" <<'EOF'
## Figures

Figure 2 shows a diagram.
EOF

write_page "$REPO" "wiki/concepts/im.md" <<'EOF'
---
id: im
title: "IM"
type: concept
status: active
---
A claim about a figure [prov:src-im#img2|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "img resolve run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'skipped-nontext'; then
    echo "FAIL: #img did not map to skipped-nontext" >&2; echo "$out" >&2; exit 1
fi
echo "PASS: #img<n> -> skipped-nontext"
