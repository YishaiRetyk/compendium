#!/usr/bin/env bash
# Phase 15 structural claim-page privacy test (rewritten from per-page frontmatter to path-prefix).
# FAITH-04: a wiki PAGE under wiki-local/ citing a cloud_safe source summary has its
# CLAIM withheld (FAITH-04 governs local_only claims by PAGE TIER, not frontmatter field).
# Also unit-asserts the collapsed resolver directly using the path-prefix contract.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Direct resolver unit assertion (structural path-prefix contract, Phase 15).
python3 - "$REPO_ROOT" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/bin/lib')
from privacy_resolve import resolve_effective_claim_privacy as e

# A page under wiki-local/ -> local_only (regardless of source tier)
assert e(None, 'wiki-local/concepts/x.md', None, None, 'wiki-cloud/sources/src-cloud.md') == 'local_only', \
    'wiki-local/ page + wiki-cloud/ source summary -> local_only'

print('OK: structural resolver contract verified')
PY

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

# cloud_safe SOURCE SUMMARY under wiki-cloud/sources/ with a distinctive sentinel slug.
write_page "$REPO" "wiki-cloud/sources/src-cpsentinel.md" <<'EOF'
---
id: src-cpsentinel
title: "CPSentinel"
type: source
status: active
path: sources/2026/2026-04/cpsentinel/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
---
EOF
write_page "$REPO" "sources/2026/2026-04/cpsentinel/source.md" <<'EOF'
## cppagesentinelsec

CLAIMPAGE_PASSAGE_MARKER content.
EOF

# LOCAL-tier PAGE under wiki-local/concepts/ (structural local-only by directory).
# No privacy: frontmatter field (stripped in Phase 15).
write_page "$REPO" "wiki-local/concepts/cppagesentinel.md" <<'EOF'
---
id: cppagesentinel
title: "CPPageSentinel"
type: concept
status: active
---
CLAIMPAGE_CLAIM_MARKER claim [prov:src-cpsentinel#sec:cppagesentinelsec|direct|2026-04-15]
EOF

(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

# WITHOUT --allow-local: claim text, passage, AND metadata slugs withheld.
set +e
wl1="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "claim-page no-allow-local emit" || { echo "$wl1" >&2; exit 1; }

if printf '%s' "$wl1" | grep -q 'CLAIMPAGE_CLAIM_MARKER'; then
    echo "FAIL: wiki-local/ PAGE claim text leaked (FAITH-04 breach)" >&2; echo "$wl1" >&2; exit 1; fi
if printf '%s' "$wl1" | grep -q 'CLAIMPAGE_PASSAGE_MARKER'; then
    echo "FAIL: passage leaked for a wiki-local/ PAGE's claim (FAITH-04 breach)" >&2; echo "$wl1" >&2; exit 1; fi
if printf '%s' "$wl1" | grep -q 'cppagesentinel'; then
    echo "FAIL: wiki-local/ PAGE source_id/path/locator slug leaked (HIGH-C)" >&2; echo "$wl1" >&2; exit 1; fi
printf '%s' "$wl1" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert any(r.get("verdict")=="skipped-privacy" and r.get("redacted") is True for r in d), "no redacted record"' || { echo "FAIL: no redacted skipped-privacy record" >&2; echo "$wl1" >&2; exit 1; }

# WITH --allow-local: marker + metadata appear.
set +e
wl2="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --allow-local --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "claim-page allow-local emit" || { echo "$wl2" >&2; exit 1; }
printf '%s' "$wl2" | grep -q 'CLAIMPAGE_PASSAGE_MARKER' || { echo "FAIL: --allow-local did not admit the wiki-local/ PAGE's claim" >&2; echo "$wl2" >&2; exit 1; }
printf '%s' "$wl2" | grep -q 'cppagesentinel' || { echo "FAIL: --allow-local did not admit the wiki-local/ PAGE metadata" >&2; echo "$wl2" >&2; exit 1; }

echo "PASS: wiki-local/ tier PAGE citing a wiki-cloud/ source has its CLAIM withheld (FAITH-04 structural)"
