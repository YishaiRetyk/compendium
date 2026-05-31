#!/usr/bin/env bash
# FAITH-01: stale-source selector picks claims whose source has content_hash drift.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-stale.md" <<'EOF'
---
id: src-stale
title: "Stale Source"
type: source
status: active
path: sources/2026/2026-04/stale/source.md
content_hash: "sha256:NEW"
compiled_against_hash: "sha256:OLD"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF

write_page "$REPO" "sources/2026/2026-04/stale/source.md" <<'EOF'
## Introduction

A paragraph that drifted.
EOF

write_page "$REPO" "wiki/concepts/drifted.md" <<'EOF'
---
id: drifted
title: "Drifted"
type: concept
status: active
---
A claim on a drifted source [prov:src-stale#sec:introduction|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --select stale --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "stale selector run" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'src-stale'; then
    echo "FAIL: stale-source claim not selected" >&2; echo "$out" >&2; exit 1
fi
if ! printf '%s' "$out" | grep -q 'selected=1'; then
    echo "FAIL: expected selected=1" >&2; echo "$out" >&2; exit 1
fi
echo "PASS: stale-source selector picks hash-drift claims"
