#!/usr/bin/env bash
# T-13-04: a source path: containing ../ that escapes repo_root is rejected/skipped;
# the file outside the repo is NEVER opened (degrades to insufficient-locator).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

# Plant a secret OUTSIDE the repo root that a traversal would read.
SECRET_DIR="$(mktemp -d -t phase13secret-XXXXXX)"
trap 'cleanup_fixture_repo "$REPO"; rm -rf "$SECRET_DIR"' EXIT
printf 'TRAVERSAL_SECRET_TEXT\n' > "$SECRET_DIR/secret.md"

# Source page path: escapes the repo via ../ to reach the secret.
ESCAPE_REL="../$(basename "$SECRET_DIR")/secret.md"
write_page "$REPO" "wiki/sources/src-tr.md" <<EOF
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

write_page "$REPO" "wiki/concepts/tr.md" <<'EOF'
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
out="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --emit-worklist --since "$SEED" --format json 2>/dev/null)"
findings="$(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" bash "$REPO_ROOT/bin/audit-claims.sh" --since "$SEED" --format json 2>/dev/null)"
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
