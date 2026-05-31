#!/usr/bin/env bash
# REVIEW HIGH-1: --local-verifier <cmd> == --verifier <cmd> --allow-local. A bare
# --verifier on the SAME fixture leaves the local_only claim skipped-privacy
# (proving a plain verifier is NOT treated as local). Locality is flag-only.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

write_page "$REPO" "wiki/sources/src-lv.md" <<'EOF'
---
id: src-lv
title: "LV"
type: source
status: active
path: sources/2026/2026-04/lv/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: local_only
---
EOF
write_page "$REPO" "sources/2026/2026-04/lv/source.md" <<'EOF'
## Introduction

LV_INTRO content.
EOF

write_page "$REPO" "wiki/concepts/lv.md" <<'EOF'
---
id: lvc
title: "LVc"
type: concept
status: active
privacy: cloud_safe
---
A claim [prov:src-lv#sec:introduction|direct|2026-04-15]
EOF

VERIFIER="$(make_fake_verifier "$REPO" supports "ok")"
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

# Plain --verifier (cloud, no opt-in) -> skipped-privacy.
set +e
out1="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --verifier "$VERIFIER" --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "bare verifier run" || { echo "$out1" >&2; exit 1; }
b="$(printf '%s' "$out1" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-lv" and f.get("verdict")=="skipped-privacy"))')"
[ "$b" -ge 1 ] || { echo "FAIL: a bare --verifier was implicitly treated as local" >&2; echo "$out1" >&2; exit 1; }

# --local-verifier (sugar) -> real verdict.
set +e
out2="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --local-verifier "$VERIFIER" --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "local-verifier run" || { echo "$out2" >&2; exit 1; }
l="$(printf '%s' "$out2" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-lv" and f.get("verdict")=="supports"))')"
[ "$l" -ge 1 ] || { echo "FAIL: --local-verifier did not admit the local_only claim" >&2; echo "$out2" >&2; exit 1; }

echo "PASS: --local-verifier == --verifier + --allow-local; bare --verifier stays cloud (HIGH-1)"
