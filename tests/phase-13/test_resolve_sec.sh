#!/usr/bin/env bash
# FAITH-02: #sec: slices heading->next-same-or-higher-heading from the RAW file.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-s.md" <<'EOF'
---
id: src-s
title: "S"
type: source
status: active
path: sources/2026/2026-04/s/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/s/source.md" <<'EOF'
## Introduction

UNIQUE_INTRO_MARKER intro paragraph.

## Results

UNIQUE_RESULTS_MARKER results paragraph.
EOF

write_page "$REPO" "wiki/concepts/p.md" <<'EOF'
---
id: p
title: "P"
type: concept
status: active
privacy: cloud_safe
---
A claim [prov:src-s#sec:introduction|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "sec resolve run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'UNIQUE_INTRO_MARKER'; then
    echo "FAIL: #sec:introduction did not resolve to the intro passage" >&2
    echo "$out" >&2; exit 1
fi
if printf '%s' "$out" | grep -q 'UNIQUE_RESULTS_MARKER'; then
    echo "FAIL: #sec:introduction leaked the Results section (over-sliced)" >&2
    echo "$out" >&2; exit 1
fi
echo "PASS: #sec: slices heading->next-heading from the raw file"
