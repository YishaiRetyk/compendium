#!/usr/bin/env bash
# Phase 15 structural source-tier privacy test (reframed from raw-source frontmatter to summary-page tier).
# FAITH-04 / review HIGH #2: a cloud page citing a source whose SUMMARY lives under
# wiki-local/sources/ must resolve local_only and have its claim withheld.
# (The old case -- raw source frontmatter privacy: local_only folds in -- is GONE because
# the privacy field is stripped and raw sources/ is cloud-safe-only by structural rule.)
# This test asserts the SOURCE-TIER privacy that review HIGH #2 demands survives the collapse.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Direct resolver unit assertion: structural source-tier contract (Phase 15).
python3 - "$REPO_ROOT" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/bin/lib')
from privacy_resolve import resolve_effective_claim_privacy as e

# A cloud page citing a source whose SUMMARY is under wiki-local/sources/ -> local_only
# This is the load-bearing review HIGH #2 case.
assert e(None, 'wiki-cloud/concepts/foo.md', None, None, 'wiki-local/sources/src-local.md') == 'local_only', \
    'wiki-cloud/ page + wiki-local/sources/ summary -> local_only (source-tier privacy survives)'

# Confirm: raw sources/ path (NOT summary) does NOT make a claim local
assert e(None, 'wiki-cloud/concepts/foo.md', None, None, 'sources/2026/2026-04/local-raw/source.md') == 'cloud_safe', \
    'wiki-cloud/ page + raw sources/ path -> cloud_safe (raw sources/ is cloud-safe-only)'

print('OK: source-tier structural contract verified (review HIGH #2)')
PY

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

# SOURCE SUMMARY under wiki-local/sources/ (structural local-only by directory).
# No privacy: frontmatter field (stripped in Phase 15).
write_page "$REPO" "wiki-local/sources/src-rs.md" <<'EOF'
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
---
EOF
# Raw source file is cloud-safe (no privacy: field; under sources/)
write_page "$REPO" "sources/2026/2026-04/rs/source.md" <<'EOF'
## Introduction

RAW_LOCAL_MARKER content.
EOF

# cloud-tier wiki-cloud/ CLAIM PAGE (structural cloud-safe by directory).
write_page "$REPO" "wiki-cloud/concepts/rs.md" <<'EOF'
---
id: rsc
title: "RSc"
type: concept
status: active
---
A claim [prov:src-rs#sec:introduction|direct|2026-04-15]
EOF

(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" invoke_tool_compat audit-claims --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "source-tier-privacy run" || { echo "$out" >&2; exit 1; }

# The claim should be skipped-privacy because its source SUMMARY is under wiki-local/
hit="$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-rs" and f.get("verdict")=="skipped-privacy"))')"
[ "$hit" -ge 1 ] || { echo "FAIL: source SUMMARY under wiki-local/sources/ was NOT recognized as local_only (review HIGH #2 regression)" >&2; echo "$out" >&2; exit 1; }
if printf '%s' "$out" | grep -q 'RAW_LOCAL_MARKER'; then
    echo "FAIL: local source passage leaked" >&2; echo "$out" >&2; exit 1; fi

echo "PASS: wiki-cloud/ page citing wiki-local/sources/ summary -> source-tier-local claim withheld (HIGH #2)"
