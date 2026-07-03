#!/usr/bin/env bash
# PRIV-04 (review HIGH #4): generated maintenance-file templates must NOT emit
# a 'privacy:' key. Tests: static-grep the report/checkpoint template strings
# in the PORTED modules src/compendium/audit_claims.py and
# src/compendium/lint.py for 'privacy:' lines.
# Post-MIG-02 form: re-pointed from the bash heredocs at the Python modules --
# the post-port source of truth (the .sh files become thin shims with no
# template bodies to grep). The ported template f-strings keep their interior
# lines at column 0, so the original column-0 'privacy:' probes carry over
# unchanged (impl-assertion inventory row, defer-to-MIG-02 -> done).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

AUDIT_PY="$REPO_ROOT/src/compendium/audit_claims.py"
LINT_PY="$REPO_ROOT/src/compendium/lint.py"

test -f "$AUDIT_PY" || { echo "FAIL: src/compendium/audit_claims.py missing" >&2; exit 1; }
test -f "$LINT_PY" || { echo "FAIL: src/compendium/lint.py missing" >&2; exit 1; }

# audit_claims.py: must NOT emit 'privacy: local_only' in the audit-state template
# The audit-state template generates wiki-local/maintenance/audit-state.md
if grep -nE "^privacy: local_only" "$AUDIT_PY" > /dev/null 2>&1; then
    lines="$(grep -nE '^privacy: local_only' "$AUDIT_PY")"
    echo "FAIL: src/compendium/audit_claims.py still has 'privacy: local_only' in generated template (PRIV-04 HIGH #4):" >&2
    echo "$lines" >&2
    FAIL=1
fi

# audit_claims.py: must NOT emit 'privacy: local_only' in the audit-report template
# (checks both state and report templates together with the above grep)
# Also check for any 'privacy:' line in the template strings more broadly
python3 - "$AUDIT_PY" <<'PYEOF'
import sys, re, pathlib

text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')

# Find lines with 'privacy:' that appear to be frontmatter assignments
# (at column 0, looks like 'privacy: <value>')
errors = []
for i, line in enumerate(text.splitlines(), 1):
    # Only flag lines that look like frontmatter 'privacy:' assignments
    if re.match(r'^privacy:\s+\S', line):
        errors.append(f"  line {i}: {line.rstrip()!r}")

if errors:
    print(f"FAIL: src/compendium/audit_claims.py has {len(errors)} frontmatter 'privacy:' line(s) in generated templates (PRIV-04):", file=sys.stderr)
    for e in errors:
        print(e, file=sys.stderr)
    sys.exit(1)

print(f"OK: src/compendium/audit_claims.py has no frontmatter 'privacy:' lines in generated templates")
PYEOF
rc=$?
if [ "$rc" -ne 0 ]; then
    FAIL=1
fi

# lint.py: must NOT emit 'privacy: cloud_safe' in the lint-report template
python3 - "$LINT_PY" <<'PYEOF'
import sys, re, pathlib

text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')

errors = []
for i, line in enumerate(text.splitlines(), 1):
    if re.match(r'^privacy:\s+\S', line):
        errors.append(f"  line {i}: {line.rstrip()!r}")

if errors:
    print(f"FAIL: src/compendium/lint.py has {len(errors)} frontmatter 'privacy:' line(s) in generated templates (PRIV-04 HIGH #4):", file=sys.stderr)
    for e in errors:
        print(e, file=sys.stderr)
    sys.exit(1)

print(f"OK: src/compendium/lint.py has no frontmatter 'privacy:' lines in generated templates")
PYEOF
rc=$?
if [ "$rc" -ne 0 ]; then
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: src/compendium/audit_claims.py + src/compendium/lint.py generated templates emit no 'privacy:' key (PRIV-04)"
