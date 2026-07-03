#!/usr/bin/env bash
# PRIV-05 W1 tripwire (review MEDIUM #1 — moved to Wave 0):
# check-neutrality source_local_only_wiki() predicate re-keyed from
# 'privacy: local_only' frontmatter grep to wiki-local/ path walk.
# Tests: (i) static-assert dead frontmatter regex is GONE; (ii) function walks wiki-local/;
# (iii) git-history paths preserved literal; (iv) behavioral: local term in wiki-local/ +
# PUBLIC_PATH still surfaces as a leak.
# Post-MIG-03: the static cases (i)–(iii) read the PYTHON module source
# (src/compendium/check_neutrality.py — the ported source of truth); the bash
# bin/check-neutrality.sh becomes a thin shim with no scanner internals to grep.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

NEUTRALITY="$REPO_ROOT/src/compendium/check_neutrality.py"   # noqa: direct-bin (source-read of the ported Python module, post-MIG-03; inventoried as done)
test -f "$NEUTRALITY" || { echo "FAIL: src/compendium/check_neutrality.py missing" >&2; exit 1; }

# (i) Static: dead frontmatter regex MUST be GONE from the leak-source function
# The old predicate 'privacy:\s*local_only' is the thing being removed
if grep -q "privacy:[[:space:]]*local_only" "$NEUTRALITY"; then
    echo "FAIL (i): src/compendium/check_neutrality.py still contains 'privacy: local_only' frontmatter regex (W1 tripwire)" >&2
    FAIL=1
fi

# (ii) Static: function must now walk wiki-local/ (not just wiki/)
if ! grep -q 'wiki-local' "$NEUTRALITY"; then
    echo "FAIL (ii): src/compendium/check_neutrality.py does not reference 'wiki-local' (leak-source predicate not re-keyed)" >&2
    FAIL=1
fi

# (iii) Static: git-history literal paths MUST be preserved (these are DELETED historical pages)
# These are the known-deleted local_only wiki paths from source_git_history()
if ! grep -q 'wiki/overviews/personal-decision-patterns.md' "$NEUTRALITY"; then
    echo "FAIL (iii): src/compendium/check_neutrality.py no longer contains 'wiki/overviews/personal-decision-patterns.md' (git-history path deleted!)" >&2
    FAIL=1
fi
if ! grep -q 'wiki/sources/src-2026-04-10-personal-decision-journal.md' "$NEUTRALITY"; then
    echo "FAIL (iii): src/compendium/check_neutrality.py no longer contains 'wiki/sources/src-2026-04-10-personal-decision-journal.md' (git-history path deleted!)" >&2
    FAIL=1
fi

# (iv) Behavioral: personal term in wiki-local/ source + leaked to PUBLIC_PATH -> check-neutrality catches it
repo="$(make_bare_repo)"

# Place a distinctive personal term in wiki-local/sources/
mkdir -p "$repo/wiki-local/sources"
cat > "$repo/wiki-local/sources/personal-source.md" <<'EOF'
---
id: personal-source
title: "Personal Source"
type: source
status: active
summary: "A local personal source."
created_at: 2026-06-04
updated_at: 2026-06-04
sources: []
epistemic_status: sourced
tags: []
domains: []
supersedes:
superseded_by:
aliases: []
has_contradictions: false
knowledge_domain: personal-goals
---

# Personal Source

Contains the highly-distinctive term: xkdistinctivetermyz9987
EOF

# Add a denylist entry so check-neutrality knows this is a personal term
cat > "$repo/.neutrality-denylist.txt" <<'EOF'
# Phase-15 test denylist
xkdistinctivetermyz9987
EOF

# Leak the personal term into docs/ (a PUBLIC_PATH)
mkdir -p "$repo/docs"
cat > "$repo/docs/leaked.md" <<'EOF'
# Leaked Doc

This document contains xkdistinctivetermyz9987 which is a local personal term.
EOF

set +e
out_b="$( invoke_tool_compat check-neutrality --root "$repo" 2>&1 )"
rc_b=$?
set -e

# After re-key, check-neutrality walks wiki-local/ for local terms and catches the leak
if [ "$rc_b" -eq 0 ]; then
    echo "FAIL (iv): behavioral: local term in wiki-local/sources/ + leaked to docs/ should trigger leak, got exit=0" >&2
    echo "output: $out_b" >&2
    cleanup_fixture_repo "$repo"
    FAIL=1
else
    # Leak detected (non-zero exit) -- check it mentions the leaked term or the file
    if ! echo "$out_b" | grep -qiE 'xkdistinctivetermyz9987|leaked\.md|wiki-local'; then
        echo "FAIL (iv): leak detected (exit=$rc_b) but output does not mention the term/file/wiki-local" >&2
        echo "output: $out_b" >&2
        cleanup_fixture_repo "$repo"
        FAIL=1
    fi
fi

cleanup_fixture_repo "$repo" 2>/dev/null || true

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: check-neutrality leak-source predicate re-keyed; git-history paths preserved; behavioral leak caught (PRIV-05 W1 tripwire)"
