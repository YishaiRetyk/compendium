#!/usr/bin/env bash
# PRIV-04 (review HIGH #5): lint must NOT require/validate 'privacy' as a
# base field. Tests: 'privacy' is NOT in BASE_FIELDS list; VALID_PRIVACY enum
# is removed; 'Invalid privacy' enum check is removed.
# Post-MIG-02 form: the negative source assertions ("the code no longer
# contains X") are re-pointed at the PORTED module src/compendium/lint.py --
# the post-port source of truth (bin/lint.sh becomes a thin shim with no
# BASE_FIELDS/enum internals to grep). Each negative proof keeps its original
# intent (impl-assertion inventory row, defer-to-MIG-02 -> done).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

LINT_PY="$REPO_ROOT/src/compendium/lint.py"
test -f "$LINT_PY" || { echo "FAIL: src/compendium/lint.py missing" >&2; exit 1; }

# lint.py BASE_FIELDS must NOT include 'privacy'
# The BASE_FIELDS list typically appears as: BASE_FIELDS = [ 'id', 'title', ..., 'privacy', ...]
if grep -qE "'privacy'" "$LINT_PY" 2>/dev/null; then
    # Check if it's in the BASE_FIELDS context specifically
    python3 - "$LINT_PY" <<'PYEOF'
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
    print("FAIL: could not locate BASE_FIELDS list in src/compendium/lint.py", file=sys.stderr)
    sys.exit(1)
PYEOF
    rc=$?
    if [ "$rc" -ne 0 ]; then
        FAIL=1
    fi
else
    # No 'privacy' literal anywhere in the module: the BASE_FIELDS list itself
    # must still exist (guards against a vacuous pass if the list is renamed).
    grep -q 'BASE_FIELDS' "$LINT_PY" \
        || { echo "FAIL: BASE_FIELDS list not found in src/compendium/lint.py" >&2; FAIL=1; }
fi

# VALID_PRIVACY set MUST be removed
if grep -q 'VALID_PRIVACY' "$LINT_PY"; then
    echo "FAIL: src/compendium/lint.py still contains 'VALID_PRIVACY' set (PRIV-04 HIGH #5)" >&2
    FAIL=1
fi

# 'Invalid privacy' enum check MUST be removed
if grep -q 'Invalid privacy' "$LINT_PY"; then
    echo "FAIL: src/compendium/lint.py still contains 'Invalid privacy' enum check (PRIV-04 HIGH #5)" >&2
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: lint no longer requires/validates 'privacy' as a base field (PRIV-04)"
