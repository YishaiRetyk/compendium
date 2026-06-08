#!/usr/bin/env bash
# test_sync_claude.sh -- Phase 07 Plan 03 (TMPL-10, D-03)
# Asserts bin/sync-claude.sh, CLAUDE.md byte-equality, hook + installer wiring.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

PASS=0
FAIL=0

report() {
  if [ "$2" -eq 0 ]; then
    echo "PASS $1"
    PASS=$((PASS + 1))
  else
    echo "FAIL $1"
    FAIL=$((FAIL + 1))
  fi
}

# t1: --check on clean tree exits 0
if bash bin/sync-claude.sh --check >/dev/null 2>&1; then
  report t1_check_clean 0
else
  report t1_check_clean 1
fi

# t2: inject drift into a sandbox copy and assert --check exits 2
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT
mkdir -p "$SANDBOX/bin"
cp bin/sync-claude.sh "$SANDBOX/bin/sync-claude.sh"
cp AGENTS.md "$SANDBOX/AGENTS.md"
cp CLAUDE.md "$SANDBOX/CLAUDE.md"
printf '\n# injected drift\n' >> "$SANDBOX/CLAUDE.md"
set +e
(cd "$SANDBOX" && bash bin/sync-claude.sh --check >/dev/null 2>&1)
DRIFT_EXIT=$?
set -e
if [ "$DRIFT_EXIT" -eq 2 ]; then
  report t2_drift_detected 0
else
  report t2_drift_detected 1
fi

# t3: plain run syncs byte-identical
if bash bin/sync-claude.sh >/dev/null && cmp -s AGENTS.md CLAUDE.md; then
  report t3_sync_byte_identical 0
else
  report t3_sync_byte_identical 1
fi

# t4: hook + installer executable
if [ -x .githooks/pre-commit ] && [ -x bin/install-hooks.sh ]; then
  report t4_hook_and_installer_executable 0
else
  report t4_hook_and_installer_executable 1
fi

# t5: hook on clean tree exits 0
if bash .githooks/pre-commit >/dev/null 2>&1; then
  report t5_hook_clean_exits_0 0
else
  report t5_hook_clean_exits_0 1
fi

# t6: --help shows --check
if bash bin/sync-claude.sh --help 2>&1 | grep -q -- '--check'; then
  report t6_help_mentions_check 0
else
  report t6_help_mentions_check 1
fi

# t7: install-hooks.sh references core.hooksPath
if grep -q 'core.hooksPath .githooks' bin/install-hooks.sh; then
  report t7_installer_config_line 0
else
  report t7_installer_config_line 1
fi

# t8: hook references sync-claude.sh
if grep -q 'sync-claude.sh' .githooks/pre-commit; then
  report t8_hook_references_script 0
else
  report t8_hook_references_script 1
fi

echo ""
echo "test_sync_claude: $PASS pass / $FAIL fail"
[ "$FAIL" -eq 0 ]
