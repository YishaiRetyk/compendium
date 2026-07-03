#!/usr/bin/env bash
# FAITH-03 / SC-6: the audit JSON is a superset of lint's 4 keys
# (severity, category, path, message).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT
SEED="$(cd "$REPO" && git rev-parse HEAD)"

write_page "$REPO" "wiki-cloud/sources/src-j.md" <<'EOF'
---
id: src-j
title: "J"
type: source
status: active
path: sources/2026/2026-04/j/source.md
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF
write_page "$REPO" "sources/2026/2026-04/j/source.md" <<'EOF'
## Introduction

Body text.
EOF
write_page "$REPO" "wiki-cloud/concepts/j.md" <<'EOF'
---
id: j
title: "J"
type: concept
status: active
---
A claim [prov:src-j#sec:introduction|direct|2026-04-15]
EOF

(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" invoke_tool_compat audit-claims --since "$SEED" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "json compat run" || { echo "$out" >&2; exit 1; }

printf '%s' "$out" | python3 -c '
import json, sys
d = json.load(sys.stdin)
lint_keys = {"severity","category","path","message"}
assert d, "empty output"
for f in d:
    missing = lint_keys - set(f.keys())
    assert not missing, f"finding missing lint keys: {missing}"
    assert f["severity"] in ("warning","info"), "bad severity: " + str(f["severity"])
    assert f["severity"] != "error", "audit must never emit error severity"
print("compat-ok")
' || { echo "FAIL: lint-superset compat" >&2; echo "$out" >&2; exit 1; }

echo "PASS: audit JSON carries lint's 4 keys; never error severity"
