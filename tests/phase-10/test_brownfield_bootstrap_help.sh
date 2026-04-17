#!/usr/bin/env bash
# Plan 10-03 Task 2: bootstrap --help surfaces all 4 flags.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY="2026-04-17"

out=$(bash "$REPO_ROOT/bin/brownfield.sh" bootstrap --help)
[[ "$out" == *"--apply"*   ]] || { echo "FAIL: --help missing --apply"   >&2; exit 1; }
[[ "$out" == *"--dry-run"* ]] || { echo "FAIL: --help missing --dry-run" >&2; exit 1; }
[[ "$out" == *"--verbose"* ]] || { echo "FAIL: --help missing --verbose" >&2; exit 1; }
[[ "$out" == *"--root"*    ]] || { echo "FAIL: --help missing --root"    >&2; exit 1; }

echo "PASS: bootstrap help advertises all 4 flags"
