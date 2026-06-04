#!/usr/bin/env bash
# PRIV-01: After migration, wiki-cloud/ and wiki-local/maintenance/ exist;
# wiki/ does NOT exist; audit control-plane files are under wiki-local/maintenance/.
# Today this FAILS (wiki/ still present, wiki-cloud/ absent).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

FAIL=0

# wiki-cloud/ must exist
if [ ! -d "$REPO_ROOT/wiki-cloud" ]; then
    echo "FAIL: $REPO_ROOT/wiki-cloud/ does not exist (PRIV-01)" >&2
    FAIL=1
fi

# wiki-local/maintenance/ must exist
if [ ! -d "$REPO_ROOT/wiki-local/maintenance" ]; then
    echo "FAIL: $REPO_ROOT/wiki-local/maintenance/ does not exist (PRIV-01)" >&2
    FAIL=1
fi

# wiki/ must NOT exist (replaced by wiki-cloud/)
if [ -d "$REPO_ROOT/wiki" ]; then
    echo "FAIL: $REPO_ROOT/wiki/ still exists (must be renamed to wiki-cloud/) (PRIV-01)" >&2
    FAIL=1
fi

# audit-report.md must be at wiki-local/maintenance/audit-report.md
if [ ! -f "$REPO_ROOT/wiki-local/maintenance/audit-report.md" ]; then
    echo "FAIL: wiki-local/maintenance/audit-report.md does not exist (PRIV-01 audit-control-plane)" >&2
    FAIL=1
fi

# audit-state.md must be at wiki-local/maintenance/audit-state.md
if [ ! -f "$REPO_ROOT/wiki-local/maintenance/audit-state.md" ]; then
    echo "FAIL: wiki-local/maintenance/audit-state.md does not exist (PRIV-01 audit-control-plane)" >&2
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    exit 1
fi

echo "PASS: wiki-cloud/ + wiki-local/maintenance/ exist; wiki/ gone; audit files relocated"
