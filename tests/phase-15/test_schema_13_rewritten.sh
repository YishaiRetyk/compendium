#!/usr/bin/env bash
# PRIV-02: After migration, CLAUDE.md §13 contains asymmetric-model language and
# does NOT contain the 7-row Privacy Decision Table or the Three-Level Precedence
# heading. Today this FAILS (table + precedence still present).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
test -f "$CLAUDE_MD" || { echo "FAIL: CLAUDE.md missing" >&2; exit 1; }

FAIL=0

# Asymmetric-model language MUST be present in §13
if ! grep -qi 'wiki-local' "$CLAUDE_MD"; then
    echo "FAIL: CLAUDE.md §13 does not contain 'wiki-local' (asymmetric-model language absent)" >&2
    FAIL=1
fi

# At least one of the key asymmetric-model terms must be present
if ! grep -qiE 'asymmetric|one-way permeab|cloud sessions|cannot read' "$CLAUDE_MD"; then
    echo "FAIL: CLAUDE.md §13 does not contain asymmetric/one-way-permeable/cloud-session language" >&2
    FAIL=1
fi

# 'Privacy Decision Table' MUST NOT be present (7-row table removed)
if grep -q 'Privacy Decision Table' "$CLAUDE_MD"; then
    echo "FAIL: CLAUDE.md still contains 'Privacy Decision Table' heading (must be removed by PRIV-02)" >&2
    FAIL=1
fi

# 'Three-Level Precedence' MUST NOT be present
if grep -q 'Three-Level Precedence' "$CLAUDE_MD"; then
    echo "FAIL: CLAUDE.md still contains 'Three-Level Precedence' heading (must be removed by PRIV-02)" >&2
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: CLAUDE.md §13 has asymmetric-model language; Privacy Decision Table + Three-Level Precedence removed"
