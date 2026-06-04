#!/usr/bin/env bash
# D-01 contract: the --verifier cmd receives {claim,passage,support_type} on STDIN.
# (1) a verifier that reflects its stdin into the rationale proves claim+passage
#     round-trip via stdin. (2) a malformed-stdout verifier yields a finding (not a
#     crash): exit 0, an insufficient finding present.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

make_fixture() {
    local REPO="$1"
    write_page "$REPO" "wiki-cloud/sources/src-c.md" <<'EOF'
---
id: src-c
title: "C"
type: source
status: active
path: sources/2026/2026-04/c/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
    write_page "$REPO" "sources/2026/2026-04/c/source.md" <<'EOF'
## Introduction

ROUNDTRIP_PASSAGE content.
EOF
    write_page "$REPO" "wiki-cloud/concepts/c.md" <<'EOF'
---
id: cc
title: "Cc"
type: concept
status: active
privacy: cloud_safe
---
ROUNDTRIP_CLAIM here [prov:src-c#sec:introduction|direct|2026-04-15]
EOF
}

# --- (1) stdin round-trip ---
REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"
make_fixture "$REPO"

# Reflector verifier: reads stdin JSON, echoes claim+passage into rationale.
# Reflector builds valid JSON via python (json.dumps escapes/flattens safely).
cat > "$REPO/reflect-verifier.sh" <<'EOF'
#!/usr/bin/env bash
python3 -c 'import json,sys
d=json.load(sys.stdin)
r=(d.get("claim","")+" | "+d.get("passage","")).replace("\n"," ")
print(json.dumps({"verdict":"supports","rationale":r,"sub_claims":[]}))'
EOF
chmod +x "$REPO/reflect-verifier.sh"
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --verifier "$REPO/reflect-verifier.sh" --since "$SEED" --format json 2>/dev/null)"
rc=$?; set -e
assert_exit_code 0 "$rc" "reflect run" || { echo "$out" >&2; exit 1; }
printf '%s' "$out" | grep -q 'ROUNDTRIP_CLAIM' || { echo "FAIL: claim text did not round-trip via stdin" >&2; echo "$out" >&2; exit 1; }
printf '%s' "$out" | grep -q 'ROUNDTRIP_PASSAGE' || { echo "FAIL: passage did not round-trip via stdin" >&2; echo "$out" >&2; exit 1; }
cleanup_fixture_repo "$REPO"; trap - EXIT

# --- (2) malformed stdout -> finding, not crash ---
REPO2="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO2"' EXIT
SEED2="$(cd "$REPO2" && git rev-parse HEAD)"
make_fixture "$REPO2"
cat > "$REPO2/bad-verifier.sh" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
printf 'this is NOT json {{{\n'
EOF
chmod +x "$REPO2/bad-verifier.sh"
(cd "$REPO2" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

set +e
out2="$(cd "$REPO2" && AUDIT_REPO_ROOT="$REPO2" bash "$REPO_ROOT/bin/audit-claims.sh" --verifier "$REPO2/bad-verifier.sh" --since "$SEED2" --format json 2>/dev/null)"
rc2=$?; set -e
assert_exit_code 0 "$rc2" "malformed-verifier run (must not crash)" || { echo "$out2" >&2; exit 1; }
hit="$(printf '%s' "$out2" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(sum(1 for f in d if f.get("source_id")=="src-c" and f.get("verdict")=="insufficient" and "unparseable" in f.get("rationale","")))')"
[ "$hit" -ge 1 ] || { echo "FAIL: malformed verifier stdout did not yield an insufficient finding" >&2; echo "$out2" >&2; exit 1; }

echo "PASS: --verifier stdin round-trip + malformed stdout is a finding (no crash, no eval)"
