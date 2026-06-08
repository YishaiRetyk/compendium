---
phase: 18-skills-overlay
reviewed: 2026-06-08T18:16:22Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - bin/gen-skills.sh
  - .githooks/pre-commit
  - bin/check-neutrality.sh
  - .github/workflows/lint.yml
  - .gitignore
  - tests/phase-18/lib.sh
  - tests/phase-18/run.sh
  - tests/phase-18/test_gen_skills_check_clean.sh
  - tests/phase-18/test_gen_skills_check_drift.sh
  - tests/phase-18/test_gen_skills_creates_files.sh
  - tests/phase-18/test_gen_skills_idempotent.sh
  - tests/phase-18/test_hook_ordering_skills.sh
  - tests/phase-18/test_neutrality_covers_skills.sh
  - tests/phase-18/test_skill_body_thin.sh
  - tests/phase-18/test_skill_dir_purity.sh
  - tests/phase-18/test_skill_frontmatter.sh
  - tests/phase-18/test_skills_git_tracked.sh
  - tests/phase-09/test_lint_workflow.sh
  - .claude/skills/ingest/SKILL.md
  - docs/reference/skills.md
findings:
  critical: 0
  warning: 6
  info: 3
  total: 9
status: issues_found
---

# Phase 18: Code Review Report

**Reviewed:** 2026-06-08T18:16:22Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Phase 18 adds a deterministic skill-file generator (`bin/gen-skills.sh`) with a `--check`
drift gate (regenerate-diff + independent structural assertions), wires it into the pre-commit
hook and CI, extends the neutrality gate to scan `.claude/skills`, and ships a 10-test TDD
harness. The core drift-gate logic is sound: the regenerate-diff catches thinning, the
structural assertions catch fattening, the neutrality scan provably covers the generated
description strings (verified live — a denylist term injected into a SKILL.md is caught with
exit 2), and the `.gitignore` negations correctly track the four committed SKILL.md files.

However, the implementation has a **root-cause portability defect**: the generator resolves
every path relative to the current working directory rather than to the repo root. This makes
the script silently write a `.claude/skills/` tree into whatever cwd it is invoked from, and it
makes the test harness cwd-dependent. I reproduced concrete damage from this: running the
phase-18 suite from `/tmp` created a stray `/tmp/.claude/skills/` tree, produced a vacuous PASS
on `test_gen_skills_creates_files.sh`, and — most seriously — the drift-test's restore trap ran
the regenerator from the wrong cwd and **left a literal `DRIFT` line in the committed
`.claude/skills/reflect/SKILL.md` in the real repo**, which only a manual `git checkout`
removed. The tests pass today only because they happen to inherit a repo-root cwd from the
caller.

A secondary cluster concerns the pre-commit hook's auto-fix loop, which cannot converge when a
stray (untracked) file is present in a skill dir, and a hook-ordering test that asserts ordering
against comment lines rather than the actual command invocations.

No security vulnerabilities or data-loss-to-source defects were found. The neutrality coverage,
YAML-safety assertion, and dead-pointer assertion are all correct and verified.

## Warnings

### WR-01: `gen-skills.sh` resolves all paths relative to cwd, not repo root — silently writes to the wrong directory

**File:** `bin/gen-skills.sh:91-99, 110-113, 124, 180-184`
**Issue:** Every path in the script is repo-relative with no anchoring: the generate loop does
`dir=".claude/skills/${op}"; mkdir -p "$dir"`, the check loop reads `committed=".claude/skills/${op}/SKILL.md"`
and `schema/workflows/${op}.md`, and the structural assertions use `.claude/skills/${op}`. The
script never `cd`s to the repo root nor derives it from `BASH_SOURCE`. Invoked from any cwd
other than the repo root, generate mode **creates a `.claude/skills/` tree in that cwd**, and
`--check` reports false `DRIFT: ... missing` for all four files. Verified live:
```
$ cd /tmp && bash <repo>/bin/gen-skills.sh --check
DRIFT: .claude/skills/ingest/SKILL.md missing
DRIFT: .claude/skills/query/SKILL.md missing
...
$ cd /tmp && bash <repo>/bin/gen-skills.sh   # silently created /tmp/.claude/skills/{ingest,query,lint,reflect}/SKILL.md
```
The pre-commit hook and CI both run from the repo root so they work today, but the script is
fragile and its failure mode (writing files into an unexpected directory) is silent and
side-effecting, not a clean error.
**Fix:** Anchor to the repo root at the top of the script, before any path use:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"
```
(or prefix every relative path with `$REPO_ROOT/`). Optionally assert
`schema/workflows/ingest.md` exists up front and fail loudly if the cwd/root is wrong.

### WR-02: Phase-18 tests do not `cd "$REPO_ROOT"` before invoking the generator — cwd-dependent, vacuous passes, and real working-tree corruption

**File:** `tests/phase-18/run.sh:4-13`, `tests/phase-18/test_gen_skills_creates_files.sh:9`, `tests/phase-18/test_gen_skills_check_clean.sh:13-25`, `tests/phase-18/test_gen_skills_check_drift.sh:10-19`
**Issue:** The tests call `bash "$REPO_ROOT/bin/gen-skills.sh"` but never `cd "$REPO_ROOT"`
first (unlike `test_skills_git_tracked.sh:20` which correctly does). Because the generator uses
cwd-relative paths (WR-01), the tests only pass when the caller's cwd is the repo root.
`run.sh` does not `cd` either, so the whole suite inherits the caller's cwd. Reproduced by
running the suite from `/tmp`:
- `test_gen_skills_creates_files.sh` reports **PASS** but actually generated files into
  `/tmp/.claude/skills/` — a vacuous pass that asserts nothing about the repo.
- `test_gen_skills_check_clean.sh` **FAILS** (9/10).
- `test_gen_skills_check_drift.sh`'s restore trap (`trap 'bash "$REPO_ROOT/bin/gen-skills.sh" ...'`)
  ran the regenerator from `/tmp`, so it wrote `/tmp/.claude` instead of restoring the real file
  and **left a literal `DRIFT` line appended to the committed `.claude/skills/reflect/SKILL.md`
  in the actual repo**. The restore trap that is supposed to guarantee a clean tree is itself
  cwd-dependent and provides false safety.
**Fix:** Add `cd "$REPO_ROOT"` at the top of each test (and/or in `run.sh` after computing
`SCRIPT_DIR`), and fix WR-01 so the generator is cwd-independent. Both fixes are needed: the
test fix removes the pollution risk, the script fix removes the root cause.

### WR-03: Pre-commit auto-fix loop cannot converge when a stray untracked file is in a skill dir

**File:** `.githooks/pre-commit:18-33`
**Issue:** When `gen-skills.sh --check` fails because of the dir-purity assertion (a non-`SKILL.md`
entry in a skill dir), the hook prints "Skills drift detected. Auto-regenerating…", runs
`gen-skills.sh` (which does not remove stray files), stages only the four known SKILL.md files,
and exits 1 asking the user to re-run. On the next commit the dir-purity assertion fails again
on the same stray file — the auto-fix never removes it, so the hook is **non-convergent**: every
commit attempt fails with the same misleading "Auto-regenerating…" message and no guidance to
delete the stray file. Reproduced:
```
$ touch .claude/skills/ingest/STRAY.txt
$ bash bin/gen-skills.sh --check     # rc=1: "ASSERT FAIL: ... contains 1 entr(y/ies) other than SKILL.md"
$ bash bin/gen-skills.sh             # regenerates; STRAY.txt persists
$ bash bin/gen-skills.sh --check     # rc=1 again — never converges
```
The code comment (lines 21-26) deliberately avoids a blanket `git add` (correct, to prevent
staging garbage), but the chosen design leaves the user stuck with an unactionable message.
**Fix:** Detect the assertion-failure-vs-diff-failure case and emit an actionable error instead
of looping, e.g. after the regenerate, re-run `--check` once and if it still fails, print the
gate's stderr verbatim and exit 1 with "Skills gate still failing after regenerate — remove
stray files from .claude/skills/<op>/ (see message above)" rather than the "re-run commit"
message that implies the next attempt will succeed.

### WR-04: Hook-ordering test asserts ordering against comment lines, not the actual invocations

**File:** `tests/phase-18/test_hook_ordering_skills.sh:11-16`
**Issue:** The test computes ordering from `grep -n 'gen-skills' | head -1` and
`grep -n 'lint.sh' | head -1`. In `.githooks/pre-commit` the **first** occurrence of
`gen-skills` is the comment on line 14 (not the invocation on line 18) and the first occurrence
of `lint.sh` is the comment on line 36 (not the invocation on line 39). The test therefore
verifies the order of *comments*, not the order in which the three gates actually execute. It
would still pass if someone reordered the real `bash bin/...` invocations while leaving the
comment blocks in place — i.e. it does not test what its name and PASS message claim
("hook ordering correct: sync-claude < gen-skills < lint"). It passes today only incidentally.
**Fix:** Match the invocation lines specifically, e.g. grep for `bash bin/sync-claude.sh`,
`bash bin/gen-skills.sh`, and `bash bin/lint.sh` (the `bash bin/` prefix excludes the comment
mentions), or grep for the `if ! bash bin/...` lines.

### WR-05: `2>/dev/null` on the `--check` gates in the hook masks genuine script failures as "drift"

**File:** `.githooks/pre-commit:6, 18`
**Issue:** Both `bash bin/sync-claude.sh --check 2>/dev/null` and
`bash bin/gen-skills.sh --check 2>/dev/null` discard stderr. A non-drift failure of the gate
(e.g. `mktemp -d` failing, a syntax error introduced by a future edit, `schema/workflows/*.md`
genuinely missing so the dead-pointer assertion fires) is indistinguishable from real drift: the
hook prints "Auto-regenerating…", regenerates, and tells the user to re-run — which will fail
again for the same underlying reason, with the real diagnostic suppressed. This compounds WR-03.
**Fix:** Do not swallow stderr on the gate calls, or capture it and surface it when the
auto-regenerate path does not resolve the failure. At minimum drop `2>/dev/null` on the
`gen-skills.sh --check` call so the dead-pointer / mktemp / assertion messages reach the user.

### WR-06: Stray non-`SKILL.md` files in a skill dir are git-trackable, defeating dir-purity at the commit boundary

**File:** `.gitignore:10-14`
**Issue:** The negation `!.claude/skills/*/` re-includes the entire contents of each skill
directory, so a stray file such as `.claude/skills/ingest/STRAY.txt` is **not** gitignored and
is fully trackable (verified: `git check-ignore` returns non-zero / trackable). A manual
`git add .claude/skills/` would stage it, and once it is committed the dir-purity assertion
(WR-03) blocks every subsequent commit. The `.gitignore` only re-includes what is needed for the
four SKILL.md files but actually re-includes everything under each op dir.
**Fix:** Tighten the negations so only `SKILL.md` is re-included, not the whole directory
contents. Because git cannot re-include a file whose parent directory is excluded, keep
`!.claude/skills/` and `!.claude/skills/*/` for traversal but rely on a final
`!.claude/skills/*/SKILL.md` together with NOT re-including siblings — i.e. ensure no broader
negation makes non-SKILL.md siblings trackable. If the directory-traversal negation
unavoidably exposes siblings, document that the dir-purity gate is the sole backstop and that
`git add .claude/skills/` must never be used (the hook already avoids it; a contributor note in
`docs/reference/skills.md` "Adopter notes" should state this explicitly).

## Info

### IN-01: `lint.yml` header lists inconsistent required-check sets

**File:** `.github/workflows/lint.yml:8, 18`
**Issue:** Line 8 states required check names are `lint`, `privacy-leak`, `strict`; line 18
(branch-protection instructions) lists `lint, privacy-leak, strict, skills-check`. The two lists
disagree on whether `skills-check` is a required check.
**Fix:** Make line 8 match line 18 (add `skills-check`) so the documented required-check set is
internally consistent.

### IN-02: `desc_val=$(grep "^description:" ... )` would silently use multiple lines if a description spanned more than one matching line

**File:** `bin/gen-skills.sh:145, 156`
**Issue:** The YAML-safety and first-person assertions operate on `grep "^description:"` output.
The template guarantees a single description line today, so this is not currently a bug, but if
the body template ever emitted a second `description:`-prefixed line the checks would silently
concatenate them. Low risk given D-01/D-02 fixed template.
**Fix:** Use `grep -m1 "^description:"` (or `head -1`) to pin the assertion to the first
description line and make the intent explicit.

### IN-03: `lib.sh` `assert_exit_code` is `export -f`'d but never invoked across a subshell/`bash -c` boundary

**File:** `tests/phase-18/lib.sh:23`
**Issue:** `export -f assert_exit_code` exports the function to child bash processes, but every
test sources `lib.sh` directly and calls the helper in-process, so the export is unused. Harmless
but slightly misleading about how the helper is consumed.
**Fix:** Drop the `export -f` line, or document why a child-process consumer needs it.

---

_Reviewed: 2026-06-08T18:16:22Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
