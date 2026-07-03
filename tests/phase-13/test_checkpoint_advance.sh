#!/usr/bin/env bash
# D-15: the audit-state.md checkpoint advances even on a NO-FINDING run.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

REPO="$(make_bare_repo)"
trap 'cleanup_fixture_repo "$REPO"' EXIT

# A wiki with NO auditable claims (no [prov:] anywhere) -> no findings.
write_page "$REPO" "wiki-cloud/concepts/empty.md" <<'EOF'
---
id: empty
title: "Empty"
type: concept
status: active
---
No provenance markers here at all.
EOF
(cd "$REPO" && git add -A && git -c commit.gpgsign=false commit -q -m "fixture")
HEAD_SHA="$(cd "$REPO" && git rev-parse --short HEAD)"

set +e
(cd "$REPO" && AUDIT_REPO_ROOT="$REPO" invoke_tool_compat audit-claims --format report >/dev/null 2>&1)
rc=$?
set -e
assert_exit_code 0 "$rc" "no-finding run" || exit 1

state="$REPO/wiki-local/maintenance/audit-state.md"
if [ ! -f "$state" ]; then
    echo "FAIL: audit-state.md was not written on a no-finding run" >&2; exit 1
fi
if ! grep -q "last_audit_commit: $HEAD_SHA" "$state"; then
    echo "FAIL: last_audit_commit did not advance to HEAD ($HEAD_SHA)" >&2
    cat "$state" >&2; exit 1
fi
echo "PASS: checkpoint advances (last_audit_commit set) even on a no-finding run"
