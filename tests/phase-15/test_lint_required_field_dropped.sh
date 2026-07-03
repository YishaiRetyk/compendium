#!/usr/bin/env bash
# PRIV-04 (review HIGH #5): bin/lint.sh must NOT require/validate 'privacy' as a
# base field. Tests: 'privacy' is NOT in BASE_FIELDS list; VALID_PRIVACY enum
# is removed; 'Invalid privacy' enum check is removed.
# Today this FAILS ('privacy' is in BASE_FIELDS at line 381; VALID_PRIVACY and
# 'Invalid privacy' enum check exist at lines ~375/1065-1066).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

LINT_SH="$REPO_ROOT/bin/lint.sh"   # noqa: direct-bin (source-read; inventoried, defer-to-MIG-02)
test -f "$LINT_SH" || { echo "FAIL: bin/lint.sh missing" >&2; exit 1; }

# bin/lint.sh BASE_FIELDS must NOT include 'privacy'
# The BASE_FIELDS list typically appears as: BASE_FIELDS = [ 'id', 'title', ..., 'privacy', ...]
if grep -qE "'privacy'" "$LINT_SH" 2>/dev/null; then
    # Check if it's in the BASE_FIELDS context specifically
    python3 - "$LINT_SH" <<'PYEOF'
import sys, re, pathlib

text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')

# Find BASE_FIELDS assignment -- it's a multi-line list
m = re.search(r'BASE_FIELDS\s*=\s*\[([^\]]+)\]', text, re.DOTALL)
if m:
    fields_block = m.group(1)
    if "'privacy'" in fields_block:
        print(f"FAIL: 'privacy' is still in BASE_FIELDS (PRIV-04 HIGH #5)", file=sys.stderr)
        sys.exit(1)
    print("OK: 'privacy' not in BASE_FIELDS")
else:
    print("WARN: could not locate BASE_FIELDS list -- manual check needed", file=sys.stderr)
    # Don't fail hard if we can't find it; the VALID_PRIVACY check below catches it
PYEOF
    rc=$?
    if [ "$rc" -ne 0 ]; then
        FAIL=1
    fi
fi

# VALID_PRIVACY set MUST be removed
if grep -q 'VALID_PRIVACY' "$LINT_SH"; then
    echo "FAIL: bin/lint.sh still contains 'VALID_PRIVACY' set (PRIV-04 HIGH #5)" >&2
    FAIL=1
fi

# 'Invalid privacy' enum check MUST be removed
if grep -q 'Invalid privacy' "$LINT_SH"; then
    echo "FAIL: bin/lint.sh still contains 'Invalid privacy' enum check (PRIV-04 HIGH #5)" >&2
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: bin/lint.sh no longer requires/validates 'privacy' as a base field (PRIV-04)"
