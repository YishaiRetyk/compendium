#!/usr/bin/env bash
# FAITH-04 / D-03: a local_only source with no --allow-local yields a
# {verdict:"skipped-privacy", source_id:<that source>} finding (the accepted
# local-heavy-vault default). The --format json findings stream IS the local-only
# report content (privacy: local_only audit-report.md), so it carries the full
# per-record metadata; the redaction is the --emit-worklist stdout behavior only.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-loc.md" <<'EOF'
---
id: src-loc
title: "Loc"
type: source
status: active
path: sources/2026/2026-04/loc/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: local_only
---
EOF
write_page "$REPO" "sources/2026/2026-04/loc/source.md" <<'EOF'
## Introduction

SECRET_PASSAGE content.
EOF

write_page "$REPO" "wiki/concepts/lc.md" <<'EOF'
---
id: lc
title: "LC"
type: concept
status: active
privacy: cloud_safe
---
A claim [prov:src-loc#sec:introduction|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "skipped-privacy run" || { echo "$out" >&2; exit 1; }

# Assert a skipped-privacy finding exists for src-loc.
hit="$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("verdict")=="skipped-privacy" and f.get("source_id")=="src-loc"))')"
if [ "$hit" -lt 1 ]; then
    echo "FAIL: no skipped-privacy finding for the local_only source" >&2; echo "$out" >&2; exit 1
fi
# The secret passage must NEVER appear (no passage egress for a withheld claim).
if printf '%s' "$out" | grep -q 'SECRET_PASSAGE'; then
    echo "FAIL: local_only passage leaked into findings output" >&2; echo "$out" >&2; exit 1
fi

echo "PASS: local_only source without --allow-local -> skipped-privacy finding (D-03)"
