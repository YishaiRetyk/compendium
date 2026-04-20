#!/usr/bin/env bash
# EXPECTED_BY: 11-01
# tests/phase-11/test_no_llm_calls.sh — BRWN-16: no LLM/network calls in
# Phase 11 scripts. Scans bin/brownfield.sh, bin/lib/brownfield_*.py, and
# schema/brownfield/migrations/ for curl/wget/openai/anthropic/claude/gpt/
# chatgpt. Comment-only mentions in heredoc review-typing prompt text are
# tolerated (that text is human/AI-consumed documentation, not an API call).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"
export BROWNFIELD_FIXTURE_TODAY=2026-04-20
export BROWNFIELD_FIXTURE_CREATED_AT=2026-04-20
export BROWNFIELD_TOOL_VERSION=1.1.0
export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$HOME/.local/lib/python3/dist-packages"
NAME="$(basename "${BASH_SOURCE[0]}")"

files=("$REPO_ROOT/bin/brownfield.sh")
for f in "$REPO_ROOT"/bin/lib/brownfield_*.py "$REPO_ROOT"/schema/brownfield/migrations/*.sh; do
    [ -f "$f" ] || continue
    files+=("$f")
done

PATTERN='(curl|wget|anthropic|openai|claude|chatgpt)|\bgpt-'
MATCHES=""
for f in "${files[@]}"; do
    [ -f "$f" ] || continue
    while IFS= read -r line; do
        MATCHES+="$f: $line"$'\n'
    done < <(grep -nEi "$PATTERN" "$f" 2>/dev/null || true)
done

if [ -n "$MATCHES" ]; then
    echo "FAIL: Phase 11 code references LLM/network APIs (should be zero):" >&2
    echo "$MATCHES" >&2
    exit 1
fi

echo "PASS $NAME"; exit 0
