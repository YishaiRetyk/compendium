#!/usr/bin/env bash
# FAITH-03: each finding carries all 6 required fields
# (path, line, source_id, locator, verdict, rationale).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

write_page "$REPO" "wiki/sources/src-o.md" <<'EOF'
---
id: src-o
title: "O"
type: source
status: active
path: sources/2026/2026-04/o/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/o/source.md" <<'EOF'
## Introduction

Body text.
EOF
write_page "$REPO" "wiki/concepts/o.md" <<'EOF'
---
id: o
title: "O"
type: concept
status: active
---
A claim [prov:src-o#sec:introduction|direct|2026-04-15]
EOF

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "schema run" || { echo "$out" >&2; exit 1; }

printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
req = {"path","line","source_id","locator","verdict","rationale","severity","category","message"}
# find a non-meta finding (an actual resolved claim)
claim = [f for f in d if f.get("source_id")]
assert claim, "no resolved-claim finding present"
for f in d:
    missing = req - set(f.keys())
    assert not missing, f"finding missing keys: {missing}"
# verdict must be in the declared enum (no out-of-enum tokens)
enum = {"supports","weak","contradicts","insufficient","insufficient-locator","skipped-privacy","skipped-nontext"}
for f in d:
    assert f["verdict"] in enum, "out-of-enum verdict: " + str(f["verdict"])
print("schema-ok")
' || { echo "FAIL: output schema check" >&2; echo "$out" >&2; exit 1; }

echo "PASS: findings carry all 6 required fields, verdicts within declared enum"
