#!/usr/bin/env bash
# FAITH-03 / SC-5: no wiki entity/concept/etc. page is mutated by a run.
# Only wiki-cloud/maintenance/audit-*.md may be written.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki-cloud/sources/src-m.md" <<'EOF'
---
id: src-m
title: "M"
type: source
status: active
path: sources/2026/2026-04/m/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/m/source.md" <<'EOF'
## Introduction

Body text.
EOF
write_page "$REPO" "wiki-cloud/concepts/m.md" <<'EOF'
---
id: m
title: "M"
type: concept
status: active
---
A claim [prov:src-m#sec:introduction|direct|2026-04-15]
EOF

(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m "fixture")

set +e
(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --format json >/dev/null 2>&1)
rc=$?
set -e
assert_exit_code 0 "$rc" "no-mutation run" || exit 1

# git status: only wiki-cloud/maintenance/ (and wiki-cloud/log.md if any) may be dirty.
changed="$(cd "$REPO" && git status --porcelain -- 'wiki-cloud/concepts' 'wiki-cloud/sources' 'wiki-cloud/entities' 'wiki-cloud/overviews' 'wiki-cloud/comparisons')"
if [ -n "$changed" ]; then
    echo "FAIL: audit mutated a wiki content page:" >&2
    echo "$changed" >&2; exit 1
fi
echo "PASS: no wiki content page mutated (only maintenance artifacts written)"
