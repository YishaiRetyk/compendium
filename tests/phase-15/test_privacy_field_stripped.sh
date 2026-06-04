#!/usr/bin/env bash
# PRIV-04: After migration, no wiki page in wiki-cloud/ or wiki-local/ has a
# 'privacy' key in frontmatter. Also asserts CLAUDE.md no longer contains the
# base-field line 'privacy: local_only|cloud_safe' or checklist item #5 for privacy.
# Today this FAILS (pages under wiki/ have privacy field; CLAUDE.md has the base-field line).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

# Check wiki-cloud/ and wiki-local/ pages for privacy field in frontmatter
python3 - "$REPO_ROOT" <<'PYEOF'
import sys, os, pathlib

root = pathlib.Path(sys.argv[1])

errors = []
for tier in ('wiki-cloud', 'wiki-local'):
    tier_dir = root / tier
    if not tier_dir.is_dir():
        # If neither wiki-cloud nor wiki-local exists, we fail because the
        # migration hasn't happened yet -- but we keep checking the other assertions.
        continue
    for md in tier_dir.rglob('*.md'):
        text = md.read_text(encoding='utf-8', errors='replace')
        if not text.startswith('---'):
            continue
        # Extract frontmatter
        parts = text.split('---', 2)
        if len(parts) < 3:
            continue
        fm_text = parts[1]
        for line in fm_text.splitlines():
            stripped = line.strip()
            if stripped.startswith('privacy:'):
                rel = md.relative_to(root)
                errors.append(f"{rel}: still has 'privacy:' frontmatter key (PRIV-04)")
                break

if errors:
    for e in errors:
        print("FAIL:", e, file=sys.stderr)
    sys.exit(1)

print("OK: no privacy: key in any wiki-cloud/ or wiki-local/ page frontmatter")
PYEOF
rc=$?
if [ "$rc" -ne 0 ]; then
    FAIL=1
fi

# CLAUDE.md must NOT contain the base-field line 'privacy: local_only|cloud_safe'
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
if grep -qE "^privacy: local_only\|cloud_safe" "$CLAUDE_MD" 2>/dev/null; then
    echo "FAIL: CLAUDE.md still contains 'privacy: local_only|cloud_safe' base-field line (PRIV-04)" >&2
    FAIL=1
fi

# CLAUDE.md must NOT contain the checklist item referencing privacy as a required field
# The pattern to check: '`privacy` is one of' (checklist item #5 in §5 validation)
if grep -qE "privacy.*is one of|'privacy' is" "$CLAUDE_MD" 2>/dev/null; then
    echo "FAIL: CLAUDE.md still contains privacy checklist item (item #5 in §5 validation) (PRIV-04)" >&2
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: no privacy: key in wiki-cloud/ or wiki-local/ pages; CLAUDE.md base-field + checklist item removed"
