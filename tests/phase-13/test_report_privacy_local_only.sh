#!/usr/bin/env bash
# REVIEW HIGH-B: the GENERATED audit-report.md AND audit-state.md carry
# privacy: local_only and NEVER privacy: cloud_safe.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-pr.md" <<'EOF'
---
id: src-pr
title: "PR"
type: source
status: active
path: sources/2026/2026-04/pr/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/pr/source.md" <<'EOF'
## Introduction

Body text.
EOF
write_page "$REPO" "wiki/concepts/pr.md" <<'EOF'
---
id: pr
title: "PR"
type: concept
status: active
---
A claim [prov:src-pr#sec:introduction|direct|2026-04-15]
EOF

set +e
(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --format report >/dev/null 2>&1)
rc=$?
set -e
assert_exit_code 0 "$rc" "report privacy run" || exit 1

report="$REPO/wiki/maintenance/audit-report.md"
state="$REPO/wiki/maintenance/audit-state.md"

for f in "$report" "$state"; do
    if [ ! -f "$f" ]; then echo "FAIL: $f not generated" >&2; exit 1; fi
    if ! grep -q 'privacy: local_only' "$f"; then
        echo "FAIL: $f is not privacy: local_only" >&2; cat "$f" >&2; exit 1
    fi
    if grep -q 'privacy: cloud_safe' "$f"; then
        echo "FAIL: $f carries privacy: cloud_safe (egress hazard)" >&2; exit 1
    fi
done
echo "PASS: generated audit-report.md + audit-state.md are privacy: local_only"
