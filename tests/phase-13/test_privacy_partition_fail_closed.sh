#!/usr/bin/env bash
# LOAD-BEARING (D-02 + REVIEW HIGH-A): a cloud verifier MECHANICALLY never receives
# a local_only passage OR a local_only-PAGE's claim text. Three claims:
#   (a) cloud_safe page citing a cloud_safe source  -> reaches the verifier
#   (b) cloud_safe page citing a local_only source   -> withheld (source privacy)
#   (c) local_only page citing a cloud_safe source   -> withheld (HIGH-A: claim privacy)
# Recording verifier appends every stdin payload to verifier-saw.log. Assert the
# log contains (a)'s marker, NOT (b)'s nor (c)'s, and skipped-privacy findings for
# both (b) and (c).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

# cloud_safe source
write_page "$REPO" "wiki-cloud/sources/src-fc-cloud.md" <<'EOF'
---
id: src-fc-cloud
title: "FCcloud"
type: source
status: active
path: sources/2026/2026-04/fccloud/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
---
EOF
write_page "$REPO" "sources/2026/2026-04/fccloud/source.md" <<'EOF'
## Introduction

FC_CLOUD_PASSAGE content.
EOF

# local_only source (structural: summary under wiki-local/sources/)
write_page "$REPO" "wiki-local/sources/src-fc-local.md" <<'EOF'
---
id: src-fc-local
title: "FClocal"
type: source
status: active
path: sources/2026/2026-04/fclocal/source.md
content_hash: "sha256:bbbb"
compiled_against_hash: "sha256:bbbb"
ingested_at: 2026-04-15
source_type: paper
---
EOF
write_page "$REPO" "sources/2026/2026-04/fclocal/source.md" <<'EOF'
## Introduction

FC_LOCAL_SOURCE_PASSAGE content.
EOF

# (a) cloud page + cloud source
write_page "$REPO" "wiki-cloud/concepts/fca.md" <<'EOF'
---
id: fca
title: "FCa"
type: concept
status: active
---
FC_A_CLAIM here [prov:src-fc-cloud#sec:introduction|direct|2026-04-15]
EOF

# (b) cloud page + local source
write_page "$REPO" "wiki-cloud/concepts/fcb.md" <<'EOF'
---
id: fcb
title: "FCb"
type: concept
status: active
---
FC_B_CLAIM here [prov:src-fc-local#sec:introduction|direct|2026-04-15]
EOF

# (c) local page + cloud source (HIGH-A) (structural: page under wiki-local/concepts/)
write_page "$REPO" "wiki-local/concepts/fcc.md" <<'EOF'
---
id: fcc
title: "FCc"
type: concept
status: active
---
FC_C_CLAIM here [prov:src-fc-cloud#sec:introduction|direct|2026-04-15]
EOF

RECORDER="$(make_recording_verifier "$REPO" supports)"
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --verifier "$RECORDER" --since "$SEED" --sample 50 --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "fail-closed partition run" || { echo "$out" >&2; exit 1; }

LOG="$REPO/verifier-saw.log"
[ -f "$LOG" ] || { echo "FAIL: recorder never invoked (verifier-saw.log missing)" >&2; echo "$out" >&2; exit 1; }

# (1) cloud_safe (a) passage REACHED the verifier.
grep -q 'FC_CLOUD_PASSAGE' "$LOG" || { echo "FAIL: cloud passage (a) did not reach the verifier" >&2; cat "$LOG" >&2; exit 1; }
# (2) local_only SOURCE (b) passage NEVER reached the verifier.
if grep -q 'FC_LOCAL_SOURCE_PASSAGE' "$LOG"; then
    echo "FAIL: local_only SOURCE passage (b) reached the cloud verifier" >&2; cat "$LOG" >&2; exit 1; fi
# (3) local_only PAGE (c) claim text NEVER reached the verifier (HIGH-A).
if grep -q 'FC_C_CLAIM' "$LOG"; then
    echo "FAIL: local_only PAGE claim text (c) reached the cloud verifier (HIGH-A)" >&2; cat "$LOG" >&2; exit 1; fi
# also: (c)'s passage (the cloud source passage) must not be tied to the withheld claim;
# since (a) shares the same source, FC_CLOUD_PASSAGE legitimately appears for (a) only.

# (4) skipped-privacy findings for BOTH (b) and (c).
b="$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-fc-local" and f.get("verdict")=="skipped-privacy"))')"
c="$(printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("path","").endswith("fcc.md") and f.get("verdict")=="skipped-privacy"))')"
[ "$b" -ge 1 ] || { echo "FAIL: no skipped-privacy for (b) local source" >&2; echo "$out" >&2; exit 1; }
[ "$c" -ge 1 ] || { echo "FAIL: no skipped-privacy for (c) local page" >&2; echo "$out" >&2; exit 1; }

echo "PASS: cloud verifier never sees local source passage NOR local-page claim; (b)+(c) skipped-privacy (D-02 + HIGH-A)"
