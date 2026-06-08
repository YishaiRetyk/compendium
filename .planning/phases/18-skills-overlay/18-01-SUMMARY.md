---
phase: 18-skills-overlay
plan: "01"
subsystem: tooling
tags: [bash, skills, claude-code, gen-skills, pre-commit, ci, neutrality]

# Dependency graph
requires:
  - phase: 18-skills-overlay/18-00
    provides: .gitignore .claude/* file-glob fix so .claude/skills/ files are trackable + RED test harness
  - phase: 17-workflow-extraction
    provides: schema/workflows/{ingest,query,lint,reflect}.md files that SKILL.md bodies point to
provides:
  - bin/gen-skills.sh: pure-bash deterministic generator with --check drift gate + structural assertions
  - .claude/skills/{ingest,query,lint,reflect}/SKILL.md: generated pointer-only skill routers
  - .githooks/pre-commit: three-block ordering (sync-claude -> gen-skills -> lint)
  - bin/check-neutrality.sh: .claude/skills/ added to PUBLIC_PATHS (D-10)
  - .github/workflows/lint.yml: skills-check CI job (hard-fail, no auto-fix)
affects:
  - 18-02
  - any future phase adding skills

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Generator + --check drift gate: third instance of the sync-claude idiom in this repo"
    - "case-based get_desc() function for bash 3.2 portability (vs declare -A which requires bash >=4)"
    - "D-07: independent structural assertions in --check are NOT redundant with regenerate-diff (catch fattened templates)"
    - "Exact-file git add in pre-commit auto-fix (not blanket `git add .claude/skills/`) for deterministic staging"

key-files:
  created:
    - bin/gen-skills.sh
    - .claude/skills/ingest/SKILL.md
    - .claude/skills/query/SKILL.md
    - .claude/skills/lint/SKILL.md
    - .claude/skills/reflect/SKILL.md
  modified:
    - .githooks/pre-commit
    - bin/check-neutrality.sh
    - .github/workflows/lint.yml

key-decisions:
  - "case-based get_desc() used instead of declare -A: macOS ships bash 3.2 which lacks associative arrays; case form is bash 3.2 safe and satisfies D-01 inline/zero-dep/single-file intent"
  - "D-07 comment is load-bearing: structural assertions in --check catch fattened templates; pure regenerate-diff would miss them (committed == fattened-template passes diff). Comment prevents future 'simplification' that would break the guard."
  - "Exact-file staging in pre-commit auto-fix: git add .claude/skills/ingest/SKILL.md etc. (not blanket .claude/skills/) prevents stray non-SKILL.md file from being auto-staged, keeping dir-purity assertion as the sole gate for stray content"
  - "skills-check CI job has draft-PR guard (matching sibling strict job) per REVIEWS.md LOW recommendation"

patterns-established:
  - "Generator pattern: bin/gen-skills.sh is structural twin of bin/sync-claude.sh; reuses CHECK_ONLY flag, cmp -s byte comparison, mktemp scratch dir, trap cleanup"
  - "Two-layer SOT model: artifact SOT = generator template (bin/gen-skills.sh); behavioral SOT = schema/workflows/{op}.md"
  - "Skill body = 2 post-frontmatter lines: one blank + one pointer; 2 <= 3 constraint satisfied"

requirements-completed:
  - SKILL-01
  - SKILL-02

# Metrics
duration: 4min
completed: 2026-06-08
---

# Phase 18 Plan 01: Skills Overlay Core Delivery Summary

**Deterministic skill generator (bin/gen-skills.sh) with --check drift gate + 6 structural assertions, four committed SKILL.md pointer-only routers, and wiring into pre-commit and CI; PHASE 18 TESTS: 10/10**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-08T17:48:47Z
- **Completed:** 2026-06-08T17:52:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Created `bin/gen-skills.sh`: pure-bash zero-dep deterministic generator (structural twin of sync-claude.sh) with `--check` mode performing regenerate-diff + 6 independent structural assertions (D-06/D-07)
- Generated and committed all four `.claude/skills/{ingest,query,lint,reflect}/SKILL.md` pointer-only routers (2 body lines each, all structural assertions green)
- Wired `gen-skills.sh --check` into `.githooks/pre-commit` between sync-claude and lint (D-03 ordering), with exact-file re-staging in auto-fix path
- Extended `bin/check-neutrality.sh` PUBLIC_PATHS with `.claude/skills` (D-10), protecting description strings from vault term leaks
- Added `skills-check` CI job to `.github/workflows/lint.yml` (hard-fail, no auto-fix, draft-PR guard)
- PHASE 18 TESTS: 10/10 (all tests green after Plans 00 + 01)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create bin/gen-skills.sh and generate four SKILL.md routers** - `835472d` (feat)
2. **Task 2: Wire --check into pre-commit hook, extend neutrality gate, add CI job** - `9e74841` (feat)

**Plan metadata:** (SUMMARY commit - see below)

## Files Created/Modified

- `bin/gen-skills.sh` - Pure-bash deterministic skill generator with --check mode; case-based get_desc() for bash 3.2 portability; 6 structural assertions; D-07 comment
- `.claude/skills/ingest/SKILL.md` - Generated ingest skill router pointing to schema/workflows/ingest.md
- `.claude/skills/query/SKILL.md` - Generated query skill router pointing to schema/workflows/query.md
- `.claude/skills/lint/SKILL.md` - Generated lint skill router pointing to schema/workflows/lint.md
- `.claude/skills/reflect/SKILL.md` - Generated reflect skill router pointing to schema/workflows/reflect.md
- `.githooks/pre-commit` - Added gen-skills --check block between sync-claude and lint; exact-file staging in auto-fix path
- `bin/check-neutrality.sh` - PUBLIC_PATHS extended with .claude/skills (D-10); comment updated
- `.github/workflows/lint.yml` - Added skills-check job; updated required checks comment

## Decisions Made

- **case-based get_desc() vs declare -A**: macOS ships bash 3.2 which lacks associative arrays. Used case-based function instead — same inline/zero-dep/single-file intent as D-01's declare -A example, but bash 3.2 portable. Documented in script comment.
- **Exact-file git add in pre-commit auto-fix**: The pre-commit hook stages `.claude/skills/ingest/SKILL.md` etc. individually rather than `git add .claude/skills/`. This prevents a stray non-SKILL.md file from being auto-staged, keeping the dir-purity structural assertion as the sole gate for stray content.
- **D-07 comment retained in hook**: The hook's skills block includes the D-07 rationale comment explaining why structural assertions are NOT redundant with regenerate-diff. This is load-bearing documentation that prevents future "simplification".

## Deviations from Plan

None - plan executed exactly as written. The case-based `get_desc()` approach (instead of `declare -A`) was anticipated and pre-specified in the plan's `<action>` block with the exact implementation provided.

## Issues Encountered

None.

## Known Stubs

None - all four SKILL.md files have real descriptions and working pointers to existing schema/workflows/*.md files. The pointer targets (schema/workflows/{ingest,query,lint,reflect}.md) all exist and are verified by the --check structural assertion.

## Threat Flags

No new security-relevant surface introduced beyond what the plan's threat model covers. The skills-check CI job is a hard-fail gate (no new attack surface). The description strings in bin/gen-skills.sh are hardcoded in a case statement (not user-controlled; no injection surface).

## Self-Check

**Created files exist:**

- `bin/gen-skills.sh` FOUND
- `.claude/skills/ingest/SKILL.md` FOUND
- `.claude/skills/query/SKILL.md` FOUND
- `.claude/skills/lint/SKILL.md` FOUND
- `.claude/skills/reflect/SKILL.md` FOUND
- `.planning/phases/18-skills-overlay/18-01-SUMMARY.md` FOUND (this file)

**Commits exist:**

- `835472d` - feat(18-01): create bin/gen-skills.sh and generate four SKILL.md routers
- `9e74841` - feat(18-01): wire gen-skills --check into pre-commit hook, neutrality gate, and CI

**Verification:**

- `bash bin/gen-skills.sh --check` exits 0
- `bash bin/check-neutrality.sh` exits 0
- `bash bin/sync-claude.sh --check` exits 0
- `bash tests/phase-18/run.sh` emits PHASE 18 TESTS: 10/10
- `git ls-files .claude/skills/` lists all four SKILL.md files

## Self-Check: PASSED

## Next Phase Readiness

Plan 01 complete. Plan 02 can proceed:
- Plan 02: author decision record `wiki-cloud/decisions/dr-2026-06-08-skills-overlay.md` + `docs/reference/skills.md` adopter documentation (D-09, D-11)

No blockers.

---
*Phase: 18-skills-overlay*
*Completed: 2026-06-08*
