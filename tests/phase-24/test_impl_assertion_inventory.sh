#!/usr/bin/env bash
# Phase 24 (TEST-04, REVIEWS HIGH#7): the impl-assertion inventory GUARD.
# Re-runs the mechanical discovery of implementation-asserting tests (tests that read a
# bin/<tool>.sh script or .githooks/pre-commit as SOURCE/data with grep/sed/awk/cat, or
# assert on its content) and FAILS if any discovered test file is NOT accounted for in
# tests/impl-assertion-inventory.md. "No UNCLASSIFIED impl-asserting test remains" is
# thereby mechanically enforced — a newly added source-grep must be classified or the
# suite goes red. A rare legitimate source-read may carry `# noqa: direct-bin` inline.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INVENTORY="$REPO_ROOT/tests/impl-assertion-inventory.md"

[ -f "$INVENTORY" ] || { echo "FAIL: tests/impl-assertion-inventory.md missing (REVIEWS HIGH#7)" >&2; exit 1; }

# Mechanical discovery: non-comment lines in any suite test that use a text tool
# (grep/sed/awk/cat) with a bin script or the pre-commit hook as the DATA argument.
# Invocation lines (`bash …/bin/<tool>.sh`, `invoke_tool <tool>`) are behavior-level
# and excluded; `# noqa: direct-bin` marks reviewed exceptions.
discover() {
    grep -rnE '(grep|sed|awk|cat)[^|>]*((\$REPO_ROOT"?/|[^a-zA-Z_/.])(bin/[a-z_0-9-]+\.sh|\.githooks/pre-commit))' \
        "$REPO_ROOT"/tests/phase-*/test_*.sh 2>/dev/null \
      | grep -vE '^[^:]+:[0-9]+:[[:space:]]*#' \
      | grep -vE 'bash ("?\$REPO_ROOT"?/)?(bin/|\.githooks/)' \
      | grep -v 'invoke_tool ' \
      | grep -v 'noqa: direct-bin' \
      | cut -d: -f1 | sort -u
}

RC=0
found_any=0
while IFS= read -r f; do
    [ -n "$f" ] || continue
    found_any=1
    base="$(basename "$f")"
    if ! grep -q "$base" "$INVENTORY"; then
        echo "UNCLASSIFIED impl-asserting test: $f (not listed in tests/impl-assertion-inventory.md)" >&2
        grep -nE '(grep|sed|awk|cat)[^|>]*(bin/[a-z_0-9-]+\.sh|\.githooks/pre-commit)' "$f" \
            | grep -vE '^[0-9]+:[[:space:]]*#' | head -3 >&2 || true
        RC=1
    fi
done < <(discover)

[ "$found_any" = "1" ] || echo "note: discovery found zero impl-asserting lines (heuristic may need review)"
[ "$RC" = "0" ] && echo "PASS: every discovered impl-asserting test is classified in the inventory"
exit "$RC"
