#!/usr/bin/env bash
# PRIV-04 (review HIGH #4): generated maintenance-file templates must NOT emit
# a 'privacy:' key. Tests: static-grep the template heredocs in audit-claims.sh
# and lint.sh for 'privacy:' lines.
# Today this FAILS (audit-claims.sh ~line 863/936 emit 'privacy: local_only';
# lint.sh ~line 2434 emits 'privacy: cloud_safe').
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

AUDIT_CLAIMS="$REPO_ROOT/bin/audit-claims.sh"
LINT_SH="$REPO_ROOT/bin/lint.sh"

test -f "$AUDIT_CLAIMS" || { echo "FAIL: bin/audit-claims.sh missing" >&2; exit 1; }
test -f "$LINT_SH" || { echo "FAIL: bin/lint.sh missing" >&2; exit 1; }

# audit-claims.sh: must NOT emit 'privacy: local_only' in the audit-state template
# The audit-state template heredoc generates wiki/maintenance/audit-state.md
if grep -nE "^privacy: local_only" "$AUDIT_CLAIMS" > /dev/null 2>&1; then
    lines="$(grep -nE '^privacy: local_only' "$AUDIT_CLAIMS")"
    echo "FAIL: bin/audit-claims.sh still has 'privacy: local_only' in generated template (PRIV-04 HIGH #4):" >&2
    echo "$lines" >&2
    FAIL=1
fi

# audit-claims.sh: must NOT emit 'privacy: local_only' in the audit-report template
# (checks both state and report heredocs together with the above grep)
# Also check for any 'privacy:' line in template heredocs more broadly
python3 - "$AUDIT_CLAIMS" <<'PYEOF'
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
    print(f"FAIL: bin/audit-claims.sh has {len(errors)} frontmatter 'privacy:' line(s) in generated templates (PRIV-04):", file=sys.stderr)
    for e in errors:
        print(e, file=sys.stderr)
    sys.exit(1)

print(f"OK: bin/audit-claims.sh has no frontmatter 'privacy:' lines in generated templates")
PYEOF
rc=$?
if [ "$rc" -ne 0 ]; then
    FAIL=1
fi

# lint.sh: must NOT emit 'privacy: cloud_safe' in the lint-report template (~line 2434)
python3 - "$LINT_SH" <<'PYEOF'
import sys, re, pathlib

text = pathlib.Path(sys.argv[1]).read_text(encoding='utf-8', errors='replace')

errors = []
for i, line in enumerate(text.splitlines(), 1):
    if re.match(r'^privacy:\s+\S', line):
        errors.append(f"  line {i}: {line.rstrip()!r}")

if errors:
    print(f"FAIL: bin/lint.sh has {len(errors)} frontmatter 'privacy:' line(s) in generated templates (PRIV-04 HIGH #4):", file=sys.stderr)
    for e in errors:
        print(e, file=sys.stderr)
    sys.exit(1)

print(f"OK: bin/lint.sh has no frontmatter 'privacy:' lines in generated templates")
PYEOF
rc=$?
if [ "$rc" -ne 0 ]; then
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: bin/audit-claims.sh + bin/lint.sh generated templates emit no 'privacy:' key (PRIV-04)"
