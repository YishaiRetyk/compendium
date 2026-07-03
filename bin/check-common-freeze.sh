#!/usr/bin/env bash
# bin/check-common-freeze.sh — Phase 24 (D-07/D-08): the frozen-foundation guard.
#
# Diffs the EXPLICIT frozen surface against the pinned Phase-24 baseline and exits 2 on
# any change — the mechanical, per-plan stop that keeps parallel Phase-25 cluster ports
# off the shared surface (worktrees isolate disjoint files; the freeze guards the shared
# files worktrees cannot isolate — D-10). Modeled on the sync-claude/gen-skills --check
# drift gates.
#
# FROZEN surface (INCLUDE): src/compendium/common/, pyproject.toml,
#   tests/lib/invoke_tool.sh, tests/lib/oracle-worktree.sh, tests/lib/normalize.sh,
#   tests/lib/no-direct-bin-calls.sh, tests/conftest.py, tests/goldens/,
#   tests/SUITE_MANIFEST.txt, tests/run-all-suites.sh.
# EXCLUDED (stay editable / controlled mutations): tests/ported.manifest (each Phase-25
#   port APPENDS its tool — one owner per append, D-09), tests/lib/test_*.sh (seam
#   self-tests), tests/phase-24/test_*.sh (characterization TESTS, not the frozen
#   footprints), tests/impl-assertion-inventory.md and tests/oracle-exempt.md/.txt (grow
#   as Phase-25 rewrites/surfaces more). L-2: Phase-25 TEST-06 growth that genuinely
#   needs a new conftest fixture or SUITE_MANIFEST row goes through the D-09
#   ownership-rebase escape hatch (one plan lands it + bumps the baseline; others rebase).
#
# Baseline resolution (matches the oracle in tests/lib/oracle-worktree.sh):
#   phase-24-freeze^{commit} (annotated tag, if reachable) -> tests/freeze-baseline.sha
#   (committed SHA, if reachable). N-4: when BOTH exist they MUST be equal — a stale tag
#   must not silently override a bumped SHA (exit 2). UNREACHABLE baseline -> SKIP with
#   the DISTINCT exit 3 (never a vacuous 0).
#
# Exit codes: 0 clean | 2 frozen-surface drift or tag/SHA mismatch | 3 SKIP (unreachable).
# Escape hatch (D-09): FREEZE_ALLOW_REBASE=1 (or --allow-rebase) exits 0 even on changes —
# using it REQUIRES bumping tests/freeze-baseline.sha + `git tag -f phase-24-freeze` in the
# SAME plan AND recording its use in that plan's SUMMARY (N-7).
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bin/check-common-freeze.sh [--staged] [--allow-rebase]

Fails (exit 2) if the frozen Phase-24 foundation surface changed vs the pinned baseline.
  --staged        Diff the STAGED changes (pre-commit mode) instead of baseline..HEAD
  --allow-rebase  D-09 ownership-rebase escape hatch (also: FREEZE_ALLOW_REBASE=1)
Exit: 0 clean | 2 drift or tag-vs-SHA mismatch | 3 SKIP (baseline unreachable — not a pass)
EOF
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

STAGED=0
ALLOW="${FREEZE_ALLOW_REBASE:-0}"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --staged) STAGED=1; shift ;;
        --allow-rebase) ALLOW=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "ERROR: unknown arg: $1" >&2; usage >&2; exit 2 ;;
    esac
done

FROZEN_PATHS=(
    src/compendium/common/
    pyproject.toml
    tests/lib/invoke_tool.sh
    tests/lib/oracle-worktree.sh
    tests/lib/normalize.sh
    tests/lib/no-direct-bin-calls.sh
    tests/conftest.py
    tests/goldens/
    tests/SUITE_MANIFEST.txt
    tests/run-all-suites.sh
)
# NOTE: tests/ported.manifest is deliberately NOT in FROZEN_PATHS (controlled per-port append).

# --- Baseline resolution (^{commit} deref — a bare annotated-tag rev-parse returns the TAG object) ---
TAG_SHA=""
FILE_SHA=""
if TAG_SHA="$(git rev-parse -q --verify 'phase-24-freeze^{commit}' 2>/dev/null)"; then :; else TAG_SHA=""; fi
if [ -f tests/freeze-baseline.sha ]; then
    FILE_SHA="$(tr -d '[:space:]' < tests/freeze-baseline.sha)"
    if [ -n "$FILE_SHA" ] && git rev-parse -q --verify "${FILE_SHA}^{commit}" >/dev/null 2>&1; then :; else FILE_SHA=""; fi
fi
if [ -n "$TAG_SHA" ] && [ -n "$FILE_SHA" ] && [ "$TAG_SHA" != "$FILE_SHA" ]; then
    echo "FREEZE FATAL: phase-24-freeze^{commit} ($TAG_SHA) != tests/freeze-baseline.sha ($FILE_SHA) — a stale tag must not override a bumped SHA." >&2
    echo "  Re-tag with 'git tag -f phase-24-freeze <sha>' or fix tests/freeze-baseline.sha." >&2
    exit 2
fi
BASELINE="${TAG_SHA:-$FILE_SHA}"
if [ -z "$BASELINE" ] || ! git rev-parse -q --verify "${BASELINE}^{commit}" >/dev/null 2>&1; then
    echo "SKIP: freeze baseline unreachable in this checkout (NOT a pass)" >&2
    exit 3
fi

# --- Diff the frozen surface (stderr NEVER swallowed) ---
if [ "$STAGED" = "1" ]; then
    CHANGED="$(git diff --cached --name-only "${BASELINE}^{commit}" -- "${FROZEN_PATHS[@]}")"
else
    CHANGED="$(git diff --name-only "${BASELINE}^{commit}..HEAD" -- "${FROZEN_PATHS[@]}")"
fi

if [ -n "$CHANGED" ]; then
    if [ "$ALLOW" = "1" ]; then
        echo "FREEZE OVERRIDDEN (FREEZE_ALLOW_REBASE — D-09 ownership-rebase): the following frozen paths changed:" >&2
        printf '  %s\n' $CHANGED >&2
        echo "  REQUIRED: bump tests/freeze-baseline.sha + 'git tag -f phase-24-freeze' in this same plan and record the override in its SUMMARY (N-7)." >&2
        exit 0
    fi
    echo "FROZEN SURFACE CHANGED vs baseline ${BASELINE} (D-07/D-08 — exit 2):" >&2
    printf '  %s\n' $CHANGED >&2
    exit 2
fi

echo "OK: frozen surface unchanged vs baseline ${BASELINE}"
exit 0
