#!/usr/bin/env bash
# REVIEW HIGH-2 (interim guard): --emit-worklist withholds local_only passages
# absent --allow-local. With --allow-local, the local_only passage is admitted.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

# cloud_safe source
write_page "$REPO" "wiki/sources/src-cloud.md" <<'EOF'
---
id: src-cloud
title: "Cloud"
type: source
status: active
path: sources/2026/2026-04/cloud/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/cloud/source.md" <<'EOF'
## Introduction

CLOUD_PASSAGE_MARKER content.
EOF

# local_only source
write_page "$REPO" "wiki/sources/src-local.md" <<'EOF'
---
id: src-local
title: "Local"
type: source
status: active
path: sources/2026/2026-04/local/source.md
content_hash: "sha256:bbbb"
compiled_against_hash: "sha256:bbbb"
ingested_at: 2026-04-15
source_type: paper
privacy: local_only
---
EOF
write_page "$REPO" "sources/2026/2026-04/local/source.md" <<'EOF'
## Introduction

LOCAL_PASSAGE_MARKER secret content.
EOF

write_page "$REPO" "wiki/concepts/cloudclaim.md" <<'EOF'
---
id: cloudclaim
title: "CloudClaim"
type: concept
status: active
---
Cloud claim [prov:src-cloud#sec:introduction|direct|2026-04-15]
EOF
write_page "$REPO" "wiki/concepts/localclaim.md" <<'EOF'
---
id: localclaim
title: "LocalClaim"
type: concept
status: active
---
Local claim [prov:src-local#sec:introduction|direct|2026-04-15]
EOF

(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

# Run 1: WITHOUT --allow-local
set +e
wl1="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --since "$SEED" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "worklist no-allow-local run" || { echo "$wl1" >&2; exit 1; }

printf '%s' "$wl1" | grep -q 'CLOUD_PASSAGE_MARKER' || {
    echo "FAIL: cloud_safe passage missing from worklist" >&2; echo "$wl1" >&2; exit 1; }
if printf '%s' "$wl1" | grep -q 'LOCAL_PASSAGE_MARKER'; then
    echo "FAIL: local_only passage leaked into worklist without --allow-local" >&2
    echo "$wl1" >&2; exit 1
fi
printf '%s' "$wl1" | grep -q 'skipped-privacy' || {
    echo "FAIL: no skipped-privacy record for the withheld local source" >&2
    echo "$wl1" >&2; exit 1; }

# Run 2: WITH --allow-local
set +e
wl2="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --allow-local --since "$SEED" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "worklist allow-local run" || { echo "$wl2" >&2; exit 1; }

printf '%s' "$wl2" | grep -q 'LOCAL_PASSAGE_MARKER' || {
    echo "FAIL: --allow-local did not admit the local_only passage" >&2
    echo "$wl2" >&2; exit 1; }

echo "PASS: --emit-worklist partitions local_only out absent --allow-local; opt-in admits it"
