#!/usr/bin/env bash
# EXPECTED_BY: 11-01
# tests/phase-11/test_hashlib_not_sha256sum.sh — REVIEWS item 8: Phase 11
# code MUST use Python hashlib (macOS-portable) rather than shell
# sha256sum. Scope: bin/brownfield.sh + schema/brownfield/migrations/*.sh.
# Comment lines that mention sha256sum as a no-go are permitted.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

files=("$REPO_ROOT/bin/brownfield.sh")
for f in "$REPO_ROOT"/schema/brownfield/migrations/*.sh; do
    files+=("$f")
done

MATCHES=""
for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    # Grab all lines mentioning sha256sum; ignore pure comment lines (first
    # non-whitespace char is '#').
    while IFS= read -r line; do
        # Skip comment-only lines
        trimmed="${line#"${line%%[![:space:]]*}"}"
        if [[ "$trimmed" == \#* ]]; then
            continue
        fi
        MATCHES+="$f: $line"$'\n'
    done < <(grep -n 'sha256sum' "$f" 2>/dev/null || true)
done

if [ -n "$MATCHES" ]; then
    echo "FAIL: sha256sum shell usage found (should use Python hashlib per REVIEWS item 8):" >&2
    echo "$MATCHES" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
