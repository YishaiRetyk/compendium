#!/usr/bin/env bash
# FAITH-04: --allow-local admits the local_only claim so it gets a REAL verdict
# (from the verifier) instead of skipped-privacy.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

write_page "$REPO" "wiki/sources/src-al.md" <<'EOF'
---
id: src-al
title: "AL"
type: source
status: active
path: sources/2026/2026-04/al/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: local_only
---
EOF
write_page "$REPO" "sources/2026/2026-04/al/source.md" <<'EOF'
## Introduction

LOCAL_INTRO content.
EOF

write_page "$REPO" "wiki/concepts/al.md" <<'EOF'
---
id: alc
title: "ALc"
type: concept
status: active
privacy: cloud_safe
---
A claim [prov:src-al#sec:introduction|direct|2026-04-15]
EOF

VERIFIER="$(make_fake_verifier "$REPO" supports "looks good")"
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

# WITHOUT --allow-local: skipped-privacy.
set +e
out1="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --verifier "$VERIFIER" --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "no-allow-local run" || { echo "$out1" >&2; exit 1; }
v1="$(printf '%s' "$out1" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-al" and f.get("verdict")=="skipped-privacy"))')"
[ "$v1" -ge 1 ] || { echo "FAIL: expected skipped-privacy without --allow-local" >&2; echo "$out1" >&2; exit 1; }

# WITH --allow-local: real verdict 'supports'.
set +e
out2="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --verifier "$VERIFIER" --allow-local --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "allow-local run" || { echo "$out2" >&2; exit 1; }
v2="$(printf '%s' "$out2" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-al" and f.get("verdict")=="supports"))')"
[ "$v2" -ge 1 ] || { echo "FAIL: --allow-local did not produce a real verdict" >&2; echo "$out2" >&2; exit 1; }

echo "PASS: --allow-local admits the local_only claim for a real verdict"
