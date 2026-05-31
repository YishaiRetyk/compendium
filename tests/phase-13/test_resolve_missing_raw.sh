#!/usr/bin/env bash
# FAITH-02: summary present, raw file absent -> graceful insufficient-locator,
# never crash.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

# Summary points at a path: whose raw file is NOT on disk.
write_page "$REPO" "wiki/sources/src-mr.md" <<'EOF'
---
id: src-mr
title: "MR"
type: source
status: active
path: sources/2026/2026-04/mr/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
# (no raw file written)

write_page "$REPO" "wiki/concepts/mr.md" <<'EOF'
---
id: mr
title: "MR"
type: concept
status: active
---
A claim [prov:src-mr#sec:introduction|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "missing-raw run does not crash" || { echo "$out" >&2; exit 1; }

if ! printf '%s' "$out" | grep -q 'insufficient-locator'; then
    echo "FAIL: missing raw source did not degrade to insufficient-locator" >&2
    echo "$out" >&2; exit 1
fi
echo "PASS: missing raw file degrades gracefully to insufficient-locator"
