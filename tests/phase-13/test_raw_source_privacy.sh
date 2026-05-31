#!/usr/bin/env bash
# REVIEW MEDIUM (subsumed by HIGH-A): a cloud_safe wiki PAGE citing a cloud_safe
# source SUMMARY whose RAW source file frontmatter says privacy: local_only -->
# strictest-wins folds in the raw frontmatter, effective privacy is local_only,
# and the claim is skipped-privacy without --allow-local. Also unit-asserts the
# resolver directly.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Direct resolver unit assertion.
python3 - "$REPO_ROOT" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/bin/lib')
from privacy_resolve import resolve_effective_claim_privacy as e
assert e({'privacy':'cloud_safe'}, 'wiki/concepts/x.md', {'privacy':'cloud_safe'}, {'privacy':'local_only'}, 'sources/2026/x.md') == 'local_only', 'raw-source local_only folds in'
print('OK')
PY

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

# cloud_safe SOURCE SUMMARY...
write_page "$REPO" "wiki/sources/src-rs.md" <<'EOF'
---
id: src-rs
title: "RS"
type: source
status: active
path: sources/2026/2026-04/rs/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
# ...but the RAW source file's OWN frontmatter says local_only.
write_page "$REPO" "sources/2026/2026-04/rs/source.md" <<'EOF'
---
privacy: local_only
---
## Introduction

RAW_LOCAL_MARKER content.
EOF

# cloud_safe claim PAGE.
write_page "$REPO" "wiki/concepts/rs.md" <<'EOF'
---
id: rsc
title: "RSc"
type: concept
status: active
privacy: cloud_safe
---
A claim [prov:src-rs#sec:introduction|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "raw-source-privacy run" || { echo "$out" >&2; exit 1; }

hit="$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-rs" and f.get("verdict")=="skipped-privacy"))')"
[ "$hit" -ge 1 ] || { echo "FAIL: raw-source local_only frontmatter was NOT folded into effective privacy" >&2; echo "$out" >&2; exit 1; }
if printf '%s' "$out" | grep -q 'RAW_LOCAL_MARKER'; then
    echo "FAIL: raw local_only passage leaked" >&2; echo "$out" >&2; exit 1; fi

echo "PASS: raw-source frontmatter local_only folds into effective privacy (MEDIUM, subsumed by HIGH-A)"
