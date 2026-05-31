#!/usr/bin/env bash
# FAITH-01: recency selector picks claims on git-diff-changed pages since a base ref.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-r.md" <<'EOF'
---
id: src-r
title: "R"
type: source
status: active
path: sources/2026/2026-04/r/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/r/source.md" <<'EOF'
## Introduction

Body text.
EOF

# Commit a baseline page (this is the "since" point).
write_page "$REPO" "wiki/concepts/old.md" <<'EOF'
---
id: old
title: "Old"
type: concept
status: active
---
An old claim [prov:src-r#sec:introduction|direct|2026-04-15]
EOF
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m "baseline")
BASE="$(cd "$REPO" && git rev-parse HEAD)"

# Now add a NEW page and commit it -- this is the recently-modified delta.
write_page "$REPO" "wiki/concepts/fresh.md" <<'EOF'
---
id: fresh
title: "Fresh"
type: concept
status: active
---
A fresh claim [prov:src-r#sec:introduction|direct|2026-04-15]
EOF
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m "add fresh")

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --select recency --since "$BASE" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "recency selector run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'fresh.md'; then
    echo "FAIL: recency selector did not pick the freshly-changed page" >&2
    echo "$out" >&2; exit 1
fi
if printf '%s' "$out" | grep -q 'old.md'; then
    echo "FAIL: recency selector should NOT pick the unchanged baseline page" >&2
    echo "$out" >&2; exit 1
fi
echo "PASS: recency selector picks git-diff-changed claims since base ref"
