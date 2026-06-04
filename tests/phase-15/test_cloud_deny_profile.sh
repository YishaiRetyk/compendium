#!/usr/bin/env bash
# PRIV-03: .claude/settings.cloud.json exists, is valid JSON, and contains
# permissions.deny == ["Read(./wiki-local/**)"].
# Also asserts docs/reference/privacy-model.md contains a fail-direction table
# naming key surfaces (fail-open, git show, python).
# Today this FAILS (.claude/settings.cloud.json absent; fail-direction table absent).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

# --- Static assertion 1: .claude/settings.cloud.json exists ---
SETTINGS="$REPO_ROOT/.claude/settings.cloud.json"
if [ ! -f "$SETTINGS" ]; then
    echo "FAIL: $SETTINGS does not exist (PRIV-03)" >&2
    FAIL=1
fi

# --- Static assertion 2: settings.cloud.json is valid JSON ---
if [ -f "$SETTINGS" ]; then
    python3 - "$SETTINGS" <<'PYEOF'
import sys, json, pathlib
try:
    data = json.loads(pathlib.Path(sys.argv[1]).read_text())
except json.JSONDecodeError as e:
    sys.exit(f"FAIL: .claude/settings.cloud.json is not valid JSON: {e}")
PYEOF
    rc=$?
    if [ "$rc" -ne 0 ]; then
        FAIL=1
    fi
fi

# --- Static assertion 3: permissions.deny contains "Read(./wiki-local/**)" ---
if [ -f "$SETTINGS" ]; then
    python3 - "$SETTINGS" <<'PYEOF'
import sys, json, pathlib
data = json.loads(pathlib.Path(sys.argv[1]).read_text())
perms = data.get("permissions", {})
deny = perms.get("deny", [])
expected = "Read(./wiki-local/**)"
if expected not in deny:
    sys.exit(f"FAIL: permissions.deny does not contain '{expected}' (got {deny!r}) (PRIV-03)")
print(f"OK: permissions.deny contains '{expected}'")
PYEOF
    rc=$?
    if [ "$rc" -ne 0 ]; then
        FAIL=1
    fi
fi

# --- Static assertion 4: docs/reference/privacy-model.md contains fail-direction table ---
PRIVACY_MODEL="$REPO_ROOT/docs/reference/privacy-model.md"
if [ ! -f "$PRIVACY_MODEL" ]; then
    echo "FAIL: docs/reference/privacy-model.md does not exist (needed for fail-direction table) (PRIV-03)" >&2
    FAIL=1
else
    # Must contain 'fail-open' (honest labeling of the deny-profile limitation)
    if ! grep -qi 'fail-open' "$PRIVACY_MODEL"; then
        echo "FAIL: docs/reference/privacy-model.md does not contain 'fail-open' (fail-direction table absent)" >&2
        FAIL=1
    fi
    # Must document that git show is NOT blocked (the honest non-covered surface)
    if ! grep -qi 'git show' "$PRIVACY_MODEL"; then
        echo "FAIL: docs/reference/privacy-model.md does not contain 'git show' surface documentation" >&2
        FAIL=1
    fi
    # Must document the python/subprocess surface (not blocked by Read deny)
    if ! grep -qi 'python' "$PRIVACY_MODEL"; then
        echo "FAIL: docs/reference/privacy-model.md does not document python/subprocess surface" >&2
        FAIL=1
    fi
fi

# MANUAL / headless-spike:
# The following three live behavioral surfaces should be verified manually or via
# a headless claude -p session when the Wave 2 executor implements test_cloud_deny_profile:
#
# Surface 1 (Read tool -- DENIED by deny profile):
#   claude -p --settings ./.claude/settings.cloud.json \
#     "Use the Read tool to read wiki-local/maintenance/audit-state.md"
#   Expected: Permission denied / tool blocked
#
# Surface 2 (Bash cat -- DENIED by deny profile on supported versions):
#   claude -p --settings ./.claude/settings.cloud.json \
#     'Run: cat wiki-local/maintenance/audit-state.md'
#   Expected: Permission denied or file not found (deny covers recognized Bash file commands)
#
# Surface 3 (git show -- NOT DENIED, fail-open surface):
#   claude -p --settings ./.claude/settings.cloud.json \
#     'Run: git show HEAD:wiki-local/maintenance/audit-state.md'
#   Expected: Shows file content (git objects are NOT protected by the Read deny)
#   This is the honest fail-open disclosure -- document in the fail-direction table.

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: .claude/settings.cloud.json valid + deny profile correct + fail-direction table present (PRIV-03)"
