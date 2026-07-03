#!/usr/bin/env bash
# Phase 24 Plan 06 (D-07/D-08 + N-4): freeze-guard self-test. All cases run in an
# ISOLATED scratch git repo (the guard is copied in and resolves its own repo root from
# $0), so nothing pollutes the working tree and the cases hold on any checkout depth.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Env hygiene: these self-tests assert the gates' DEFAULT behavior — a commit-level
# escape hatch (FREEZE_ALLOW_REBASE on a D-09 commit, PARITY_GATE_SKIP) or GOLDEN_FREEZE
# leaking in from the invoking environment would invert the expected exits.
unset FREEZE_ALLOW_REBASE PARITY_GATE_SKIP GOLDEN_FREEZE


fail() { echo "FAIL: $1" >&2; exit 1; }

SC="$(mktemp -d)"
trap 'rm -rf "$SC"' EXIT
mkdir -p "$SC/bin" "$SC/src/compendium/common" "$SC/tests/lib"
cp "$REPO_ROOT/bin/check-common-freeze.sh" "$SC/bin/"
printf '# mini frozen module\n' > "$SC/src/compendium/common/x.py"
printf '[project]\nname = "mini"\n' > "$SC/pyproject.toml"
printf '# mini runner\n' > "$SC/tests/run-all-suites.sh"
printf '# mini manifest\n' > "$SC/tests/ported.manifest"
printf '# free file\n' > "$SC/notes.md"
(
    cd "$SC"
    git init -q -b main
    git config user.email fixture@example.com
    git config user.name Fixture
    git add -A
    git -c commit.gpgsign=false commit -qm seed
    BASE="$(git rev-parse HEAD)"
    printf '%s\n' "$BASE" > tests/freeze-baseline.sha
    git add tests/freeze-baseline.sha
    git -c commit.gpgsign=false commit -qm "pin baseline"
)
run_guard() { (cd "$SC" && bash bin/check-common-freeze.sh "$@" >/dev/null 2>&1); }

# 1. Clean at the pinned baseline (Plan-06-style files outside the frozen surface) -> 0.
run_guard || fail "clean state: expected 0, got $?"

# 2. Drift: commit a change to a FROZEN file -> 2.
( cd "$SC" && printf '# drift\n' >> src/compendium/common/x.py && git add -A && git -c commit.gpgsign=false commit -qm drift )
rc=0; run_guard || rc=$?
[ "$rc" = "2" ] || fail "frozen drift: expected 2, got $rc"

# 4. Escape hatch on the same drift -> 0 (D-09; requires baseline bump + SUMMARY note — N-7).
rc=0; (cd "$SC" && FREEZE_ALLOW_REBASE=1 bash bin/check-common-freeze.sh >/dev/null 2>&1) || rc=$?
[ "$rc" = "0" ] || fail "escape hatch: expected 0, got $rc"

# (roll the drift back for the remaining cases)
( cd "$SC" && git reset -q --hard HEAD~1 )

# 3. Non-frozen change passes: commit a change to a NON-frozen file -> 0.
( cd "$SC" && printf 'more\n' >> notes.md && printf 'faketool\n' >> tests/ported.manifest && git add -A && git -c commit.gpgsign=false commit -qm nonfrozen )
rc=0; run_guard || rc=$?
[ "$rc" = "0" ] || fail "non-frozen change: expected 0, got $rc"

# 5. Unreachable baseline SKIPs (exit 3), never passes: fabricate an unreachable SHA.
( cd "$SC" && printf 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef\n' > tests/freeze-baseline.sha )
rc=0; run_guard || rc=$?
[ "$rc" = "3" ] || fail "unreachable baseline: expected SKIP 3, got $rc"
( cd "$SC" && git checkout -q -- tests/freeze-baseline.sha )

# 6. Annotated-tag deref: tag at the baseline commit -> resolves via ^{commit} -> clean 0.
( cd "$SC" && git tag -a phase-24-freeze "$(cat tests/freeze-baseline.sha)" -m baseline )
rc=0; run_guard || rc=$?
[ "$rc" = "0" ] || fail "tag deref clean: expected 0, got $rc"

# 7. N-4 tag-vs-SHA mismatch -> FATAL exit 2 (a stale tag must not override a bumped SHA).
( cd "$SC" && git tag -f -a phase-24-freeze HEAD -m "stale tag at a different commit" >/dev/null )
rc=0; run_guard || rc=$?
[ "$rc" = "2" ] || fail "tag-vs-SHA mismatch: expected FATAL 2, got $rc"
( cd "$SC" && git tag -d phase-24-freeze >/dev/null )

echo "PASS: freeze guard (clean=0, drift=2, escape-hatch=0, non-frozen=0, unreachable=3, tag-deref=0, tag-mismatch=2)"
