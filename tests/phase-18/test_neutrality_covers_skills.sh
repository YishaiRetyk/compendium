#!/usr/bin/env bash
# Covers: D-10 -- check-neutrality covers .claude/skills in scanned paths.
# Post-MIG-03 rewrite (impl-agnostic behavior probe): the old static
# source-grep of bin/check-neutrality.sh for '.claude/skills' is replaced by a
# BEHAVIOR probe -- plant a denylisted term in <repo>/.claude/skills/**/SKILL.md
# and assert the scanner flags it (nonzero exit + output names the term/path).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

# tests/phase-18/lib.sh intentionally omits the bare-repo fixture helpers (its
# other tests run against the live repo tree), so this test carries its own
# copies -- verbatim from tests/phase-15/lib.sh, mktemp prefix bumped to phase18-.
make_bare_repo() {
    local tmp
    tmp="$(mktemp -d -t phase18-XXXXXX)"
    (cd "$tmp" && git init -q -b main && \
        git config user.email "fixture@example.com" && \
        git config user.name "Fixture" && \
        git -c commit.gpgsign=false commit -q --allow-empty -m "seed")
    echo "$tmp"
}
cleanup_fixture_repo() {
    local path="$1"
    if [ -n "$path" ] && [ -d "$path" ] && [[ "$path" == /tmp/* ]]; then
        rm -rf "$path"
    fi
}

FAIL=0
repo="$(make_bare_repo)"

# Denylist a distinctive term...
cat > "$repo/.neutrality-denylist.txt" <<'EOF'
# Phase-18 test denylist
xkskillsleaktermzz4242
EOF

# ...and plant it ONLY under .claude/skills/ (the D-10 scan surface: generated
# skill description strings).
mkdir -p "$repo/.claude/skills/demo"
cat > "$repo/.claude/skills/demo/SKILL.md" <<'EOF'
---
name: demo
description: "This description leaks xkskillsleaktermzz4242 into a generated skill."
---

Demo skill body.
EOF

set +e
out="$( invoke_tool_compat check-neutrality --root "$repo" 2>&1 )"
rc=$?
set -e

if [ "$rc" -eq 0 ]; then
    echo "FAIL: denylisted term planted under .claude/skills/ was not flagged (exit=0 -- D-10 coverage lost)" >&2
    echo "output: $out" >&2
    FAIL=1
else
    if ! echo "$out" | grep -qiE 'xkskillsleaktermzz4242|\.claude/skills'; then
        echo "FAIL: leak flagged (exit=$rc) but output names neither the term nor the .claude/skills path" >&2
        echo "output: $out" >&2
        FAIL=1
    fi
fi

cleanup_fixture_repo "$repo" 2>/dev/null || true

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: check-neutrality.sh covers .claude/skills"
