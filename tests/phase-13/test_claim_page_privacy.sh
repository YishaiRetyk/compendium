#!/usr/bin/env bash
# REVIEW HIGH-A: a privacy: local_only wiki PAGE citing a cloud_safe source has
# its CLAIM withheld (FAITH-04 governs local_only CLAIMS, not only source
# passages). The page/source carry a DISTINCTIVE sentinel slug; absent --allow-local
# the claim text, passage marker, AND metadata slugs are ABSENT from cloud-facing
# worklist stdout (HIGH-C). WITH --allow-local they appear. Also unit-asserts the
# resolver directly.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# Direct resolver unit assertion (HIGH-A row).
python3 - "$REPO_ROOT" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + '/bin/lib')
from privacy_resolve import resolve_effective_claim_privacy as e
assert e({'privacy':'local_only'}, 'wiki/concepts/x.md', {'privacy':'cloud_safe'}, None, 'sources/2026/x.md') == 'local_only', 'local page + cloud source -> local_only'
print('OK')
PY

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

# cloud_safe SOURCE with a distinctive sentinel slug in id/path.
write_page "$REPO" "wiki/sources/src-cpsentinel.md" <<'EOF'
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
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/cpsentinel/source.md" <<'EOF'
## cppagesentinelsec

CLAIMPAGE_PASSAGE_MARKER content.
EOF

# local_only PAGE citing the cloud_safe source, distinctive sentinel path.
write_page "$REPO" "wiki/concepts/cppagesentinel.md" <<'EOF'
---
id: cppagesentinel
title: "CPPageSentinel"
type: concept
status: active
privacy: local_only
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
    echo "FAIL: local PAGE claim text leaked (HIGH-A)" >&2; echo "$wl1" >&2; exit 1; fi
if printf '%s' "$wl1" | grep -q 'CLAIMPAGE_PASSAGE_MARKER'; then
    echo "FAIL: passage leaked for a local PAGE's claim (HIGH-A)" >&2; echo "$wl1" >&2; exit 1; fi
if printf '%s' "$wl1" | grep -q 'cppagesentinel'; then
    echo "FAIL: local PAGE source_id/path/locator slug leaked (HIGH-A + HIGH-C)" >&2; echo "$wl1" >&2; exit 1; fi
printf '%s' "$wl1" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert any(r.get("verdict")=="skipped-privacy" and r.get("redacted") is True for r in d), "no redacted record"' || { echo "FAIL: no redacted skipped-privacy record" >&2; echo "$wl1" >&2; exit 1; }

# WITH --allow-local: marker + metadata appear.
set +e
wl2="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --allow-local --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "claim-page allow-local emit" || { echo "$wl2" >&2; exit 1; }
printf '%s' "$wl2" | grep -q 'CLAIMPAGE_PASSAGE_MARKER' || { echo "FAIL: --allow-local did not admit the local PAGE's claim" >&2; echo "$wl2" >&2; exit 1; }
printf '%s' "$wl2" | grep -q 'cppagesentinel' || { echo "FAIL: --allow-local did not admit the local PAGE metadata" >&2; echo "$wl2" >&2; exit 1; }

echo "PASS: local_only PAGE citing a cloud_safe source has its CLAIM withheld (HIGH-A) + metadata redacted (HIGH-C)"
