#!/usr/bin/env bash
# REVIEW HIGH-2 + HIGH-C: --emit-worklist partitions local_only out (passage AND
# metadata) absent --allow-local. The withheld local claim's source_id/path/locator
# DISTINCTIVE slugs must be ABSENT from cloud-facing stdout -- only an aggregate
# {"verdict":"skipped-privacy","redacted":true,"count":N} record appears. cloud_safe
# entries are emitted in full. WITH --allow-local the local marker + metadata appear.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

# cloud_safe source (full slug is fine to leak)
write_page "$REPO" "wiki-cloud/sources/src-cloudy.md" <<'EOF'
---
id: src-cloudy
title: "Cloudy"
type: source
status: active
path: sources/2026/2026-04/cloudy/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
---
EOF
write_page "$REPO" "sources/2026/2026-04/cloudy/source.md" <<'EOF'
## Introduction

CLOUD_OK_MARKER content.
EOF

# local_only source with a DISTINCTIVE sentinel slug (structural: summary under wiki-local/sources/).
write_page "$REPO" "wiki-local/sources/src-zztoplocalsentinel.md" <<'EOF'
---
id: src-zztoplocalsentinel
title: "LocalSentinel"
type: source
status: active
path: sources/2026/2026-04/zztoplocalsentinel/source.md
content_hash: "sha256:bbbb"
compiled_against_hash: "sha256:bbbb"
ingested_at: 2026-04-15
source_type: paper
---
EOF
write_page "$REPO" "sources/2026/2026-04/zztoplocalsentinel/source.md" <<'EOF'
## zzsentinelsection

LOCAL_SECRET_MARKER secret content.
EOF

write_page "$REPO" "wiki-cloud/concepts/cloudy.md" <<'EOF'
---
id: cloudyc
title: "Cloudyc"
type: concept
status: active
---
Cloud claim [prov:src-cloudy#sec:introduction|direct|2026-04-15]
EOF
write_page "$REPO" "wiki-cloud/concepts/zzlocalpage.md" <<'EOF'
---
id: zzlocalpagec
title: "ZzLocalPagec"
type: concept
status: active
---
Local claim [prov:src-zztoplocalsentinel#sec:zzsentinelsection|direct|2026-04-15]
EOF

(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

# Run 1: WITHOUT --allow-local
set +e
wl1="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "no-allow-local emit" || { echo "$wl1" >&2; exit 1; }

# cloud_safe passage present; cloud source_id/path present (unaffected).
printf '%s' "$wl1" | grep -q 'CLOUD_OK_MARKER' || { echo "FAIL: cloud passage missing" >&2; echo "$wl1" >&2; exit 1; }
printf '%s' "$wl1" | grep -q 'src-cloudy' || { echo "FAIL: cloud source_id missing" >&2; echo "$wl1" >&2; exit 1; }

# local passage text ABSENT.
if printf '%s' "$wl1" | grep -q 'LOCAL_SECRET_MARKER'; then
    echo "FAIL: local passage leaked to worklist stdout" >&2; echo "$wl1" >&2; exit 1; fi
# HIGH-C: local source_id / path / locator slugs ABSENT (metadata redaction).
if printf '%s' "$wl1" | grep -q 'zztoplocalsentinel'; then
    echo "FAIL: local source_id/path slug leaked to worklist stdout (HIGH-C)" >&2; echo "$wl1" >&2; exit 1; fi
if printf '%s' "$wl1" | grep -q 'zzsentinelsection'; then
    echo "FAIL: local locator slug leaked to worklist stdout (HIGH-C)" >&2; echo "$wl1" >&2; exit 1; fi
# redacted aggregate record present with a count.
printf '%s' "$wl1" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert any(r.get("verdict")=="skipped-privacy" and r.get("redacted") is True and r.get("count",0)>=1 for r in d), "no redacted aggregate record"' || { echo "FAIL: no redacted aggregate skipped-privacy record" >&2; echo "$wl1" >&2; exit 1; }

# Run 2: WITH --allow-local
set +e
wl2="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --allow-local --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "allow-local emit" || { echo "$wl2" >&2; exit 1; }
printf '%s' "$wl2" | grep -q 'LOCAL_SECRET_MARKER' || { echo "FAIL: --allow-local did not admit local passage" >&2; echo "$wl2" >&2; exit 1; }
printf '%s' "$wl2" | grep -q 'zztoplocalsentinel' || { echo "FAIL: --allow-local did not admit local metadata" >&2; echo "$wl2" >&2; exit 1; }

echo "PASS: --emit-worklist partitions local passage AND metadata; redacts to aggregate count (HIGH-2 + HIGH-C)"
