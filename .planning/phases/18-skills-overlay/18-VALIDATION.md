---
phase: 18
slug: skills-overlay
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-08
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | bash (established repo pattern: `tests/phase-XX/test_*.sh` + `run.sh` aggregator) |
| **Config file** | none — `tests/phase-18/run.sh` serves as the aggregator (Wave 0 gap) |
| **Quick run command** | `bash tests/phase-18/run.sh` |
| **Full suite command** | `bash tests/phase-18/run.sh` (same — no separate full mode for this phase) |
| **Estimated runtime** | ~5–10 seconds (pure bash, no network, no npm/pip) |

---

## Sampling Rate

- **After every task commit:** Run `bash tests/phase-18/run.sh`
- **After every plan wave:** Run `bash tests/phase-18/run.sh`
- **Before `/gsd-verify-work`:** Full suite must be green (10/10)
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-00-01 | 00 | 0 | SKILL-01, SKILL-02 | T-18-00-01 | .claude/skills/ un-ignores correctly; no unintended `.claude/` surface expansion | unit | `bash tests/phase-18/test_skills_git_tracked.sh` | ❌ W0 | ⬜ pending |
| 18-00-02 | 00 | 0 | SKILL-01, SKILL-02 | T-18-00-02, T-18-00-03 | RED harness runs without crashing; test_skills_git_tracked passes; others RED | integration | `bash tests/phase-18/run.sh` | ❌ W0 | ⬜ pending |
| 18-01-01 | 01 | 1 | SKILL-01 | T-18-01-01, T-18-01-02, T-18-01-04 | Generator creates exactly 4 files; second run is idempotent; body ≤3 lines; dir purity; frontmatter valid | unit | `bash tests/phase-18/test_gen_skills_creates_files.sh && bash tests/phase-18/test_gen_skills_idempotent.sh && bash tests/phase-18/test_skill_body_thin.sh && bash tests/phase-18/test_skill_dir_purity.sh && bash tests/phase-18/test_skill_frontmatter.sh` | ❌ W0 | ⬜ pending |
| 18-01-01 | 01 | 1 | SKILL-02 | T-18-01-01, T-18-01-05 | `--check` exits 0 clean; exits 1 on drift in any of the 4 files | unit | `bash tests/phase-18/test_gen_skills_check_clean.sh && bash tests/phase-18/test_gen_skills_check_drift.sh` | ❌ W0 | ⬜ pending |
| 18-01-01 | 01 | 1 | SKILL-02 | T-18-01-03 | SKILL.md files are git-tracked (not gitignored) | unit | `bash tests/phase-18/test_skills_git_tracked.sh` | ❌ W0 | ⬜ pending |
| 18-01-02 | 01 | 1 | SKILL-02 (D-03) | T-18-01-01, T-18-01-02 | Pre-commit hook ordering: sync-claude → gen-skills → lint | integration | `bash tests/phase-18/test_hook_ordering_skills.sh` | ❌ W0 | ⬜ pending |
| 18-01-02 | 01 | 1 | SKILL-02 (D-10) | T-18-01-03 | check-neutrality.sh scans .claude/skills/ | unit | `bash tests/phase-18/test_neutrality_covers_skills.sh` | ❌ W0 | ⬜ pending |
| 18-02-01 | 02 | 2 | SKILL-01, SKILL-02 (D-09) | T-18-02-01, T-18-02-02 | DR frontmatter valid; index.md wikilink correct format; check-neutrality exits 0 | unit | `grep -c 'dr-2026-06-08-skills-overlay' wiki-cloud/index.md` | N/A (new file) | ⬜ pending |
| 18-02-02 | 02 | 2 | SKILL-01, SKILL-02 (D-11) | T-18-02-01, T-18-02-03 | docs/reference/skills.md neutral; ROADMAP plan entries confirmed | unit | `bash bin/check-neutrality.sh && grep '18-00-PLAN.md' .planning/ROADMAP.md` | N/A (new file) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The following test files must be created in Plan 00 before any implementation runs. All start in RED state (generator does not yet exist).

- [ ] `tests/phase-18/run.sh` — aggregator; emits `PHASE 18 TESTS: $PASS/$((PASS+FAIL))`
- [ ] `tests/phase-18/lib.sh` — shared fixtures: REPO_ROOT resolver, assert_exit_code helper
- [ ] `tests/phase-18/test_gen_skills_creates_files.sh` — covers SKILL-01 file creation (4 SKILL.md files)
- [ ] `tests/phase-18/test_gen_skills_idempotent.sh` — covers SKILL-01 idempotency
- [ ] `tests/phase-18/test_skill_body_thin.sh` — covers SKILL-01 ≤3 body lines + pointer content
- [ ] `tests/phase-18/test_skill_dir_purity.sh` — covers SKILL-01 directory purity (L2 loads all .md)
- [ ] `tests/phase-18/test_skill_frontmatter.sh` — covers SKILL-01 frontmatter: name + third-person description
- [ ] `tests/phase-18/test_gen_skills_check_clean.sh` — covers SKILL-02 `--check` clean path (exit 0)
- [ ] `tests/phase-18/test_gen_skills_check_drift.sh` — covers SKILL-02 `--check` drift detection (exit 1)
- [ ] `tests/phase-18/test_skills_git_tracked.sh` — covers SKILL-02 committed-not-gitignored (Plan 00 Task 1 fix)
- [ ] `tests/phase-18/test_hook_ordering_skills.sh` — covers D-03 pre-commit ordering assertion
- [ ] `tests/phase-18/test_neutrality_covers_skills.sh` — covers D-10 neutrality surface extension

**Note:** `test_skills_git_tracked.sh` is the one Wave 0 test expected to PASS immediately after Plan 00 Task 1 (.gitignore fix). All others will FAIL/SKIP in RED state until Plan 01 lands.

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (10 test scripts + run.sh + lib.sh)
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
