#!/usr/bin/env bash
# tests/lib/no-direct-bin-calls.sh — FROZEN shared surface (D-08; Phase 24 Plan 05).
# Gate: the parity suites must invoke every bin tool THROUGH the seam (invoke_tool /
# invoke_tool_compat) — a direct `bash "$REPO_ROOT/bin/<tool>.sh"` call bypasses the
# WIKI_IMPL branch + worktree oracle + channel capture entirely (zero parity signal).
# Scans the enumerated parity suites' test_*.sh for the three direct-call shapes and
# FAILS listing every offender. A rare legitimate non-invocation mention may carry an
# inline `# noqa: direct-bin` marker (e.g. a source-read classified in
# tests/impl-assertion-inventory.md).
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SUITES=(09 09.1 10 11 12.1 12.2 13 15 18 20 22 23 24)
RC=0
for suite in "${SUITES[@]}"; do
    d="$REPO_ROOT/tests/phase-$suite"
    [ -d "$d" ] || continue
    for f in "$d"/test_*.sh; do
        [ -f "$f" ] || continue
        offenders="$(grep -nE 'bash "\$REPO_ROOT/bin/[a-z0-9-]+\.sh"|(^|[^\w"/])"\$REPO_ROOT/bin/[a-z0-9-]+\.sh"|bash \$REPO_ROOT/bin/[a-z0-9-]+\.sh' "$f" 2>/dev/null \
            | grep -vE '^[0-9]+:[[:space:]]*#' \
            | grep -v 'noqa: direct-bin' || true)"
        if [ -n "$offenders" ]; then
            echo "DIRECT BIN CALL (bypasses the parity seam): ${f#"$REPO_ROOT"/}" >&2
            echo "$offenders" | sed 's/^/  /' >&2
            RC=1
        fi
    done
done

[ "$RC" = "0" ] && echo "OK: no direct bin/<tool>.sh call in the parity suites (all seam-routed)"
exit "$RC"
