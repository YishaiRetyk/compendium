#!/usr/bin/env bash
# tests/phase-10/test_ingest_strip_no_warn_when_absent.sh
# Phase 10 Plan 04 (BRWN-10, false-positive guard) — asserts bin/ingest.sh
# does NOT emit a "Note: stripped ..." stderr warning when the source file
# carries no bootstrap_stage / bootstrap_date frontmatter. Body must land
# unchanged in DEST_FILE.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

tmp="$(mktemp -d -t phase10-ingest-clean-XXXXXX)"
cd "$tmp"
git init -q -b main
git -c commit.gpgsign=false -c user.email='fixture@example.com' -c user.name='Fixture' \
    commit --allow-empty -q -m 'fixture seed'

mkdir -p inbox
cat > inbox/source.md <<'EOF'
---
type: entity
title: "Greenfield Ingest"
---

# Greenfield Ingest

Body content — no brownfield sentinel fields in frontmatter.
EOF

stderr_out="$(invoke_tool_compat ingest inbox/source.md 2>&1 >/dev/null || true)"

# 1) Stderr MUST NOT contain the D-21 "Note: stripped" template.
if echo "$stderr_out" | grep -q "Note: stripped"; then
    echo "FAIL: false-positive D-21 strip warning on greenfield source" >&2
    echo "stderr was: $stderr_out" >&2
    exit 1
fi

# 2) DEST_FILE exists and retains the body.
dest="$(find sources -type f -name source.md | head -1)"
[ -n "$dest" ] || { echo "FAIL: ingest did not write DEST_FILE" >&2; exit 1; }
grep -q 'Body content' "$dest" \
    || { echo "FAIL: body lost from greenfield ingest" >&2; exit 1; }

cd - >/dev/null
rm -rf "$tmp"
echo "PASS: ingest.sh emits no strip warning on greenfield source"
