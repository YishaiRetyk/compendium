---
phase: 18-skills-overlay
fixed_at: 2026-06-08T19:55:00Z
review_path: .planning/phases/18-skills-overlay/18-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 18: Code Review Fix Report

**Fixed at:** 2026-06-08T19:55:00Z
**Source review:** .planning/phases/18-skills-overlay/18-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (WR-01 through WR-06; CR: 0; IN-01/02/03 out of scope under `critical_warning`)
- Fixed: 6
- Skipped: 0

All work was done in an isolated detached worktree (`/tmp/sv-18-reviewfix-*`) and
fast-forwarded onto `main` after validation. `main` was at the worktree's base
commit (`0cf92bb`) throughout — no foreground commits raced the fixer, so the
fast-forward was clean. After every change the drift gate (`bash bin/gen-skills.sh
--check`, exit 0) and the phase-18 suite (`PHASE 18 TESTS: 10/10`) were green. The
generator was run only from the repo root to avoid reproducing the WR-02 corruption.

Pre-existing context: `tests/phase-09/run.sh` reports 23/30 both before (at base
`0cf92bb`) and after these fixes — the 7 failing phase-09 tests are unrelated to
this phase and pre-date the fixes (verified by running the suite against the base
commit in a scratch worktree). The phase-09 test the brief flagged as relevant,
`test_lint_workflow.sh`, passes.

## Fixed Issues

### WR-01 + WR-02: gen-skills.sh resolved paths relative to cwd; phase-18 tests did not cd to repo root

**Files modified:** `bin/gen-skills.sh`, `tests/phase-18/run.sh`, `tests/phase-18/test_gen_skills_creates_files.sh`, `tests/phase-18/test_gen_skills_check_clean.sh`, `tests/phase-18/test_gen_skills_check_drift.sh`
**Commit:** cf3d9e0
**Applied fix:** Committed as a coupled pair (the test fix removes the pollution
risk, the script fix removes the root cause).
- WR-01: Anchored the generator to the repo root before any relative-path use:
  `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`,
  `REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"`, `cd "$REPO_ROOT"`, plus a loud
  guard that fails with a clear error if `schema/workflows/ingest.md` is absent at
  the resolved root (catches a misresolved root instead of silently writing a stray
  tree). Verified live: running `--check` from `/tmp` now correctly checks the real
  repo (exit 0, "OK") and creates no `/tmp/.claude` tree.
- WR-02: Added `cd "$REPO_ROOT"` to `run.sh` (after computing `SCRIPT_DIR`, deriving
  `REPO_ROOT` from `$SCRIPT_DIR/../..`) and to each of the three cwd-sensitive tests
  (`test_gen_skills_creates_files.sh`, `test_gen_skills_check_clean.sh`,
  `test_gen_skills_check_drift.sh`) right after they source `lib.sh` (which defines
  `$REPO_ROOT`). This pins the restore traps and the generator invocations to the
  repo root so the drift-test cleanup can never corrupt a committed SKILL.md.

### WR-03 + WR-05: pre-commit auto-fix loop non-convergent; gate stderr swallowed

**Files modified:** `.githooks/pre-commit`
**Commit:** 892ac27
**Applied fix:** Committed as a coupled pair (same file; WR-05 explicitly compounds
WR-03).
- WR-03: After the auto-regenerate + restage step, re-run `bash bin/gen-skills.sh
  --check` once. If it still fails (e.g. a stray non-SKILL.md file tripping
  dir-purity, or a dead `schema/workflows/<op>.md` pointer — failures regenerate
  cannot fix), print an actionable error ("Skills gate still failing after
  regenerate … remove any stray files from `.claude/skills/<op>/` …") and exit 1,
  instead of the misleading "Re-run commit" message that implies the next attempt
  will succeed. The loop now converges or tells the user exactly what to do.
- WR-05: Dropped `2>/dev/null` on both `bash bin/gen-skills.sh --check` and
  `bash bin/sync-claude.sh --check` so genuine non-drift diagnostics (mktemp
  failure, assertion messages, dead-pointer message) reach the user. Behavior is
  otherwise identical (same control flow, same auto-fix path).

### WR-04: hook-ordering test asserted ordering against comment lines, not invocations

**Files modified:** `tests/phase-18/test_hook_ordering_skills.sh`
**Commit:** 36c459e
**Applied fix:** Replaced the loose `grep -n 'sync-claude' | head -1` (etc.) with
anchored matches on the actual gate-invocation lines:
`grep -nE '^\s*if ! bash bin/sync-claude\.sh'`,
`'^\s*if ! bash bin/gen-skills\.sh'`, `'^\s*if ! bash bin/lint\.sh'`. The
`bash bin/` prefix excludes the explanatory comment blocks that also name these
tools, so the test now verifies the order the three gates actually execute. The
PASS line confirms it now reports the real invocation line numbers
(sync 8 < gen-skills 23 < lint 56) rather than comment lines.

### WR-06: stray non-SKILL.md files in skill dirs were git-trackable

**Files modified:** `.gitignore`
**Commit:** c0115c2
**Applied fix:** Achieved the full mechanical fix (not just documentation). Added
`.claude/skills/*/*` to re-ignore ALL contents of each op directory, placed BEFORE
`!.claude/skills/*/SKILL.md` which re-includes only SKILL.md. Order matters: the
broad re-ignore must precede the leaf re-include. This was validated empirically in
a throwaway repo and then in the real working tree:
- All four `SKILL.md` files remain trackable (`git check-ignore` returns non-zero).
- A stray `STRAY.txt` is now ignored (`git check-ignore` returns 0).
- `git add .claude/skills/` now stages only the four SKILL.md files and skips
  strays — so the dir-purity gate can no longer be defeated at the commit boundary
  by an accidentally-committed sibling.
- `bash tests/phase-18/test_skills_git_tracked.sh` passes.

Note on the brief's git-limitation contingency: the review and brief anticipated
that git might be unable to re-include only SKILL.md without exposing siblings,
falling back to the WR-03 actionable-error backstop plus a docs note. That fallback
proved unnecessary — the `.claude/skills/*/*` re-ignore followed by the
`!…/SKILL.md` re-include resolves it cleanly while keeping the four SKILL.md
trackable, so no brittle/breaking `.gitignore` change was needed and the
`docs/reference/skills.md` "git add .claude/skills/" instruction remains correct
and safe.

## Skipped Issues

None — all six in-scope warnings were fixed.

---

_Fixed: 2026-06-08T19:55:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
