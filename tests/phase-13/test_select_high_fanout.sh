#!/usr/bin/env bash
# FAITH-01: high-fanout selector picks claims on pages with many inbound wikilinks.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki-cloud/sources/src-f.md" <<'EOF'
---
id: src-f
title: "F"
type: source
status: active
path: sources/2026/2026-04/f/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/f/source.md" <<'EOF'
## Introduction

Body text.
EOF

# Hub page with a claim; two other pages link to it (fanout = 2).
write_page "$REPO" "wiki-cloud/concepts/hub.md" <<'EOF'
---
id: hub
title: "Hub"
type: concept
status: active
---
A hub claim [prov:src-f#sec:introduction|direct|2026-04-15]
EOF
write_page "$REPO" "wiki-cloud/concepts/linker-a.md" <<'EOF'
---
id: linker-a
title: "Linker A"
type: concept
status: active
---
See the [[Hub]] for details. No prov here.
EOF
write_page "$REPO" "wiki-cloud/concepts/linker-b.md" <<'EOF'
---
id: linker-b
title: "Linker B"
type: concept
status: active
---
Also see the [[Hub]]. No prov here.
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --select fanout --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "fanout selector run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'hub.md'; then
    echo "FAIL: high-fanout selector did not pick the hub page (2 inbound links)" >&2
    echo "$out" >&2; exit 1
fi
echo "PASS: high-fanout selector picks claims on high-inbound-link pages"
