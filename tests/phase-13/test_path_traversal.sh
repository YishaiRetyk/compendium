#!/usr/bin/env bash
# T-13-04: a source path: containing ../ that escapes repo_root is rejected/skipped;
# the file outside the repo is NEVER opened (degrades to insufficient-locator).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# DETERMINISTIC LAYOUT (Phase 25 25-01 gate finding): the escape path below is
# COMMITTED into fixture page content — deriving it from a mktemp basename made the
# fixture tree (and its capture hash) vary per run. Repo and secret are fixed-name
# children of ONE per-run mktemp parent: isolation lives in the parent, the embedded
# relative path is byte-constant.
PARENT="$(mktemp -d -t phase13trav-XXXXXX)"
REPO_ORIG="$(make_bare_repo)"
REPO="$PARENT/repo"
mv "$REPO_ORIG" "$REPO"
trap 'rm -rf "$PARENT"' EXIT

# Plant a secret OUTSIDE the repo root that a traversal would read.
SECRET_DIR="$PARENT/secret"
mkdir "$SECRET_DIR"
printf 'TRAVERSAL_SECRET_TEXT\n' > "$SECRET_DIR/secret.md"

# Source page path: escapes the repo via ../ to reach the secret.
ESCAPE_REL="../secret/secret.md"
write_page "$REPO" "wiki-cloud/sources/src-tr.md" <<EOF
---
id: src-tr
title: "TR"
type: source
status: active
path: $ESCAPE_REL
content_hash: "sha256:aaaa"
compiled_against_hash: "sha256:aaaa"
ingested_at: 2026-04-15
source_type: paper
privacy: cloud_safe
---
EOF

write_page "$REPO" "wiki-cloud/concepts/tr.md" <<'EOF'
---
id: tr
title: "TR"
type: concept
status: active
---
A claim [prov:src-tr#sec:introduction|direct|2026-04-15]
EOF

SEED="$(cd "$REPO" && git rev-parse HEAD)"
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m fixture)

set +e
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" invoke_tool_compat audit-claims --emit-worklist --since "$SEED" --format json 2>/dev/null)"
findings="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" invoke_tool_compat audit-claims --since "$SEED" --format json 2>/dev/null)"
rc=$?
set -e
assert_exit_code 0 "$rc" "path-traversal run does not crash" || { echo "$out" >&2; exit 1; }

if printf '%s\n%s' "$out" "$findings" | grep -q 'TRAVERSAL_SECRET_TEXT'; then
    echo "FAIL: path traversal read a file outside repo_root" >&2
    echo "$out" >&2; echo "$findings" >&2; exit 1
fi
if ! printf '%s' "$findings" | grep -q 'insufficient-locator'; then
    echo "FAIL: escaping path: did not degrade to insufficient-locator" >&2
    echo "$findings" >&2; exit 1
fi
echo "PASS: ../-escaping path: rejected, secret never read, degrades to insufficient-locator"
