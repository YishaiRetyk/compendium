#!/usr/bin/env bash
# Covers: D-10 -- bin/check-neutrality.sh covers .claude/skills in scanned paths
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
script="$REPO_ROOT/bin/check-neutrality.sh"   # noqa: direct-bin (source-read; inventoried, defer-to-MIG-03)
grep -q '\.claude/skills' "$script" || { echo "FAIL: .claude/skills not in check-neutrality.sh PUBLIC_PATHS"; exit 1; }
echo "PASS: check-neutrality.sh covers .claude/skills"
