---
phase: 07-neutral-template-foundation
plan: 05
subsystem: neutrality-enforcement
tags: [ci, denylist, orphan-branch, release, github-template, branch-protection, wave-5]

requires:
  - phase: 07-neutral-template-foundation
    plan: 02
    provides: examples/kahneman/ relocation — consumed by check-neutrality.sh path-exemption
  - phase: 07-neutral-template-foundation
    plan: 03
    provides: bin/sync-claude.sh + CLAUDE.md — consumed by neutrality.yml drift step
  - phase: 07-neutral-template-foundation
    plan: 04
    provides: docs/reference/release.md runbook — the contract release.sh implements
provides:
  - bin/check-neutrality.sh (NEUT-06 Kahneman-only denylist enforcement with deterministic --suggest-denylist, per-file neutrality_exempt frontmatter, self-reference exemption, sanctioned examples/kahneman/ path-strip)
  - .neutrality-denylist.txt (human-reviewed — Kahneman-only category shipped; personal-term category deferred to NEUT-08 follow-up)
  - bin/release.sh (TMPL-11 fresh-temp-dir allowlist staging, orphan-commit publish, --dry-run default, --apply requires interactive 'y', SIGINT/ERR/EXIT cleanup trap, RELEASE_EMAIL defaults to release@example.invalid)
  - .github/workflows/neutrality.yml (pull_request = hard gate; push = advisory; runs check-neutrality + sync-claude --check + full tests/phase-07/run.sh)
  - tests/phase-07/test_neutrality_gate.sh, test_denylist_gate.sh, test_release_dryrun.sh, test_release_allowlist.sh
  - tests/phase-07/fixtures/neutrality/{clean,leak-kahneman,leak-personal}/ + denylist.txt
  - TMPL-01 mechanics proven (is_template toggle + branch protection requiring 'neutrality' status check) on throwaway repo YishaiRetyk/template-smoke-test
  - TMPL-11 single-commit-history assertion VERIFIED on live remote publish
affects:
  - Phase 08 wizard (must preserve denylist cleanliness — neutrality CI now blocks leaks at PR)
  - Phase 09 CI workflow (neutrality.yml is the precedent for PR-hard-gate vs push-advisory pattern)
  - All future PRs (neutrality gate enforced mechanically until denylist is expanded in NEUT-08 follow-up)

tech-stack:
  added: []
  patterns:
    - "Fresh-temp-dir allowlist staging: release.sh never mutates the worktree; creates mktemp dir, git init, copies allowlisted paths, orphan-commits, pushes. Safe-by-construction vs. safe-by-mutation (REVIEWS.md HIGH #1)."
    - "CI hard-gate pattern: pull_request trigger is enforced via branch protection required status check; push trigger exists but is advisory (informational runs on direct push)."
    - "Denylist exemption layering: (1) SELF_REFERENTIAL_EXEMPT skips check-neutrality.sh itself; (2) line-level strip of 'examples/kahneman/...' substrings mirrors 07-03/07-04 precedent; (3) frontmatter 'neutrality_exempt: true' mirrors bin/lint.sh 'example: true' pattern."
    - "Deterministic --suggest-denylist: documented input sources (git log + .planning/notes/), documented extraction rule (word-boundary tokens, case-insensitive, frequency-sorted), same inputs yield byte-identical output."
    - "Allowlist-driven publish: explicit file set in release.sh (no 'exclude everything except' globbing); adding a public file requires editing the allowlist."

key-files:
  created:
    - bin/check-neutrality.sh
    - bin/release.sh
    - .neutrality-denylist.txt
    - .github/workflows/neutrality.yml
    - tests/phase-07/test_neutrality_gate.sh
    - tests/phase-07/test_denylist_gate.sh
    - tests/phase-07/test_release_dryrun.sh
    - tests/phase-07/test_release_allowlist.sh
    - tests/phase-07/fixtures/neutrality/clean/AGENTS.md
    - tests/phase-07/fixtures/neutrality/clean/README.md
    - tests/phase-07/fixtures/neutrality/leak-kahneman/AGENTS.md
    - tests/phase-07/fixtures/neutrality/leak-personal/docs/reference/ci.md
    - tests/phase-07/fixtures/neutrality/denylist.txt
    - .planning/backlog-neutrality-denylist-candidate.txt (untracked — raw material for the deferred NEUT-08 follow-up PR; preserves the 861-line deterministic --suggest-denylist output)
  modified:
    - bin/release.sh (tightened local_only regex — Task 5 fix commit 21e0445 — to exclude schema docs that legitimately mention 'local_only' as an enum value)
    - docs/reference/release.md (smoke grep excludes the runbook's own self-reference — Task 5 fix commit a1b2afd)
    - wiki/decisions/dr-2026-04-15-kahneman-to-examples.md (added neutrality_exempt: true frontmatter — that record IS about Kahneman relocation, so it legitimately mentions the term)

key-decisions:
  - "NEUT-08 (personal-vault denylist coverage) deferred to a follow-up PR per user decision 'approved — minimal'. v1.1 ships the Kahneman-only category only (NEUT-06). Candidate tokens preserved locally at .planning/backlog-neutrality-denylist-candidate.txt (861 lines) for a later hand-curated review pass against .planning/notes/ + git history."
  - "release.sh allowlist is the authoritative public file set — adding a public file to the template is an explicit code change, not a gitignore adjustment. Fresh-temp-dir staging makes mis-curation mechanically impossible (REVIEWS.md HIGH #1)."
  - "CI neutrality.yml uses pull_request as the hard gate + push as advisory. Branch protection on main requires the 'neutrality' status check; direct pushes to main are blocked by branch protection rather than by the workflow's push trigger (which exists only for informational early-warning on feature branches)."
  - "check-neutrality.sh gained three exemptions during Task 2 (Rule 1/2 auto-fix) to let the real-repo Kahneman denylist pass: self-reference exemption, line-level examples/kahneman/ path-strip, and frontmatter neutrality_exempt: true. The first two mirror 07-03 test_agents_neutralized.sh / 07-04 test_no_kahneman_in_public_docs.sh precedents; the third mirrors bin/lint.sh example: true from 07-02."
  - "release.sh local_only regex tightened (Task 5 fix 21e0445) — the initial regex overmatched AGENTS.md line 582 where 'local_only' is documented as the enum value of the privacy: field. Fix excludes enum-documentation contexts; actual privacy: local_only frontmatter still trips the gate."
  - "RELEASE_EMAIL default is release@example.invalid (reserved .invalid TLD per RFC 2606; unambiguously non-routable). Operator-override via env var documented in docs/reference/release.md."
  - "TMPL-01 real public template repo name deferred — TMPL-01 mechanics were proven on YishaiRetyk/template-smoke-test (is_template: true visually confirmed + branch protection requiring 'neutrality' status check verified via gh api). The operator-runbook (docs/reference/release.md) is sufficient for the eventual name-pick; repo naming is not Phase 7's job."

patterns-established:
  - "PR-hard-gate / push-advisory split: pull_request trigger enforces via required-status-check; push trigger runs but does not gate (real enforcement is branch protection). Reused by Phase 9 CI workflows."
  - "Allowlist-based orphan-branch publish: explicit file enumeration in release.sh rather than gitignore-driven exclusion. Surviving artifacts file: the allowlist itself."
  - "Deterministic --suggest-denylist mode: documented-input + documented-extraction-rule guarantees reproducibility. Outputs preserved as .planning/backlog-neutrality-denylist-candidate.txt for the NEUT-08 follow-up review."
  - "Frontmatter-level neutrality_exempt: true for pages that legitimately discuss neutralized terms (decision records about the relocation, for example). Mirrors bin/lint.sh example: true from 07-02."

requirements-completed: [NEUT-06, TMPL-01, TMPL-11]
requirements-deferred: [NEUT-08]

duration: ~65min
completed: 2026-04-15
---

# Phase 07 Plan 05: Neutrality Gates + Release CI Summary

**Shipped the three C-1 mitigation gates: `bin/check-neutrality.sh` (Kahneman-only denylist, deterministic `--suggest-denylist`, three exemption layers), `bin/release.sh` (fresh-temp-dir allowlist staging with orphan-commit publish, `--dry-run` default, cleanup trap), and `.github/workflows/neutrality.yml` (pull_request = hard gate + push = advisory) — with TMPL-01 template mechanics mechanically verified on a throwaway repo and TMPL-11 `git rev-list --all --count == 1` assertion confirmed PASS on a live orphan-branch publish.**

## Performance

- **Duration:** ~65 min (including two Task-5 fix cycles during live verification)
- **Completed:** 2026-04-15
- **Tasks:** 5 (Tasks 1–4 autonomous; Task 5 live human-action checkpoint with two inline fixes)
- **Commits:** 7 (Tasks 1–4 = 5 commits, Task 5 = 2 fix commits)
- **Files created:** 13 + 1 untracked audit-trail artifact

## Task Commits

1. **Task 1 RED — failing tests + fixtures for check-neutrality.sh** — `eb88d72` (test)
2. **Task 1 GREEN — bin/check-neutrality.sh + deterministic --suggest-denylist + fixtures (NEUT-06/08)** — `c8ba41a` (feat)
3. **Task 2 — minimal Kahneman-only denylist + scanner exemptions (NEUT-06; NEUT-08 deferred)** — `e8d8cfd` (feat)
4. **Task 3 — bin/release.sh fresh-temp-dir allowlist staging + dry-run/allowlist tests (TMPL-11, REVIEWS.md HIGH #1/#2/#5)** — `5390008` (feat)
5. **Task 4 — CI workflow (.github/workflows/neutrality.yml, pull_request = hard gate + push = advisory)** — `61ed99a` (ci)
6. **Checkpoint state record — Task 2 decisions + Task 5 entry** — `d27c411` (docs)
7. **Task 5 fix 1 — tighten release.sh local_only regex to exclude schema docs** — `21e0445` (fix)
8. **Task 5 fix 2 — release.md smoke grep excludes runbook self-reference** — `a1b2afd` (fix)

## Task 5 Live Verification Outcome (Human-Action Checkpoint)

### Step A — TMPL-01 GitHub Template Toggle (mechanically verified on throwaway)

- **Throwaway repo:** `YishaiRetyk/template-smoke-test` (made public temporarily for branch-protection test)
- **Template toggle:** `gh api -X PATCH` set `is_template: true` → user visually confirmed the green "Use this template" button
- **Branch protection:** `main` requires status check `neutrality`, `strict: true`, `allow_force_pushes: false` — verified via `gh api repos/YishaiRetyk/template-smoke-test/branches/main/protection`
- **Deferred:** real public template repo name not yet chosen (operator-runbook exists at `docs/reference/release.md`; re-run `bin/release.sh --remote <url> --apply` when name is picked). Throwaway cleanup deferred — gh token lacks `delete_repo` scope; user will delete manually or refresh scope via `gh auth refresh -h github.com -s delete_repo`.

### Step B — TMPL-11 Orphan-Branch Release Smoke (REVIEWS.md HIGH #4 — fully verified)

**Command:** `bash bin/release.sh --remote https://github.com/YishaiRetyk/template-smoke-test.git --apply` (succeeded after Task-5 fix `21e0445`).

Cloned fresh to `/tmp/smoke`:

| Assertion | Result |
|-----------|--------|
| `git rev-list --all --count == 1` (single-commit history) | **PASS** |
| `cmp -s AGENTS.md CLAUDE.md` (sync preserved) | exit 0 |
| Denylist paths 8/8 absent (`.planning`, `.brownfield`, `wiki/entities`, `wiki/concepts`, `wiki/comparisons`, `wiki/overviews`, `wiki/sources`, `wiki/maintenance`) | **PASS** |
| Allowlist essentials 6/6 present (`README.md`, `LICENSE`, `AGENTS.md`, `CLAUDE.md`, `PRIVACY.md`, `examples/kahneman`) | **PASS** |
| `bash bin/check-neutrality.sh --root . --denylist .neutrality-denylist.txt` → exit 0 | **PASS** |

Initial neutrality grep flagged one hit in `docs/reference/release.md:88` — confirmed as the runbook quoting its own grep-command text (legitimate self-reference). Fixed by Task-5 fix `a1b2afd` adding `--exclude=release.md` to the documented smoke command.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] check-neutrality.sh required three exemption layers to make Kahneman denylist pass against the real repo**

- **Found during:** Task 2 first real-repo run.
- **Issue:** Literal `grep kahneman` trips three legitimate mention sites: (a) `bin/check-neutrality.sh` itself (the tool mentions its own denylist tokens), (b) sanctioned `examples/kahneman/...` path references in quickstart/release.md/AGENTS.md pointers, (c) the NEUT-07 decision record that IS about Kahneman relocation.
- **Fix:** Three exemption layers: `SELF_REFERENTIAL_EXEMPT` list skips `bin/check-neutrality.sh`; line-level strip of `examples/kahneman[a-z0-9._/-]*` substrings before re-scanning (mirrors 07-03/07-04 precedent); `neutrality_exempt: true` frontmatter opt-out (applied to `wiki/decisions/dr-2026-04-15-kahneman-to-examples.md`, mirrors 07-02 `example: true`).
- **Commit:** `e8d8cfd`.

**2. [Rule 1 — Bug] release.sh local_only regex overmatched AGENTS.md enum documentation**

- **Found during:** Task 5 live `--apply` invocation.
- **Issue:** Pre-flight local_only scan tripped on AGENTS.md line 582 where `local_only` appears as a documented enum value of the `privacy:` field (e.g. `privacy: local_only|cloud_safe`). This is documentation, not a privacy leak.
- **Fix:** Tightened regex to require `privacy: local_only` in a frontmatter-shape context; excludes pipe-separated enum enumerations and prose-mention forms. Actual `privacy: local_only` frontmatter still trips the gate.
- **Commit:** `21e0445`.

**3. [Rule 1 — Bug] release.md smoke-check grep self-referenced its own pattern text**

- **Found during:** Task 5 live smoke-check on the published clone.
- **Issue:** Neutrality scan inside `/tmp/smoke` flagged `docs/reference/release.md:88` because the runbook literally quotes the grep command `grep -rIn -iE 'kahneman|...'` as an example. That quoted pattern text counts as a Kahneman mention.
- **Fix:** Added `--exclude=release.md` to the documented smoke-check command. The runbook's self-reference is now mechanically exempt from its own scan.
- **Commit:** `a1b2afd`.

---

**Total deviations:** 3 auto-fixed (all Rule 1 — semantically-legitimate-mention false positives in the scanner). **Impact:** no scope creep; each fix is a narrowly-scoped exemption layered onto an existing mechanism, not a rewrite.

## Deferred Issues

**NEUT-08 (personal-vault denylist coverage) — deferred to a follow-up PR per user decision "approved — minimal".**

- v1.1 ships the Kahneman-only denylist category (NEUT-06). The personal-term category is empty.
- Raw material for the deferred review is preserved at `.planning/backlog-neutrality-denylist-candidate.txt` (861-line deterministic `--suggest-denylist` output; untracked because `.planning/` is gitignored).
- When picked up: review the candidate list by hand against `.planning/notes/` + creator git-history, commit the curated tokens to `.neutrality-denylist.txt`, mark NEUT-08 complete.
- Not a blocker for v1.1 ship: neutrality CI still catches Kahneman leaks (the dominant creator-content vector in this codebase); personal-term coverage is defense-in-depth.

**Outstanding non-Phase-7 follow-ups (tracked elsewhere):**

- Throwaway repo cleanup: `gh auth refresh -h github.com -s delete_repo && gh repo delete YishaiRetyk/template-smoke-test --yes` (non-GSD — user task).
- Real public template repo name + push: deferred until operator picks a name. Re-run `bin/release.sh --remote <url> --apply` + re-do the smoke when that happens.

## Known Stubs

None. All artifacts are production surfaces. The deferred NEUT-08 denylist entries are absent by intent (user decision), not stubbed with placeholders.

## Verification

- `bash tests/phase-07/run.sh` → all test scripts PASS (pre-existing 18 from 07-01..04 + 4 new from 07-05: test_neutrality_gate, test_denylist_gate, test_release_dryrun, test_release_allowlist).
- `bash bin/check-neutrality.sh --root . --denylist .neutrality-denylist.txt` on real repo → exit 0 (clean after three exemption layers applied).
- `bash bin/release.sh --remote <throwaway-url> --apply` (Task 5 live) → published + fresh clone → `git rev-list --all --count == 1` PASS.
- CI workflow `.github/workflows/neutrality.yml` present with both pull_request (hard gate) and push (advisory) triggers; runs check-neutrality + sync-claude --check + full tests/phase-07/run.sh.
- Branch protection on throwaway's `main` verified requiring `neutrality` status check (mechanism proven — will be reapplied on the real template repo when named).

## Authentication Gates

- **gh CLI** — user already authenticated (`gh auth status` pre-session). Token scope sufficient for `repos:*` and branch-protection API, insufficient for `delete_repo` — noted for throwaway cleanup follow-up.

## Next Phase Readiness

Phase 7 neutral-template-foundation is COMPLETE. Public control-plane surfaces are Kahneman-clean, mechanically enforced (check-neutrality.sh + CI), and orphan-branch releasable without leaking personal git history. Phase 8 (wizard + manual) can assume:

- A stable `AGENTS.md` substrate with 4 `{{...}}` wizard placeholders.
- A neutrality CI gate that will block any wizard regression that leaks Kahneman tokens into public paths.
- A `docs/manual-setup.md` stub waiting to be populated alongside `bin/init-wizard.sh`.
- A ship-ready orphan-branch release path — Phase 8 will not need to revisit release mechanics.

---
*Phase: 07-neutral-template-foundation*
*Plan: 05 (final plan of Phase 7)*
*Completed: 2026-04-15*

## Self-Check: PASSED

Verified:

- FOUND: bin/check-neutrality.sh
- FOUND: bin/release.sh
- FOUND: .neutrality-denylist.txt
- FOUND: .github/workflows/neutrality.yml
- FOUND: tests/phase-07/test_neutrality_gate.sh
- FOUND: tests/phase-07/test_denylist_gate.sh
- FOUND: tests/phase-07/test_release_dryrun.sh
- FOUND: tests/phase-07/test_release_allowlist.sh
- FOUND commit: eb88d72 (Task 1 RED)
- FOUND commit: c8ba41a (Task 1 GREEN)
- FOUND commit: e8d8cfd (Task 2)
- FOUND commit: 5390008 (Task 3)
- FOUND commit: 61ed99a (Task 4)
- FOUND commit: d27c411 (checkpoint state)
- FOUND commit: 21e0445 (Task 5 fix 1)
- FOUND commit: a1b2afd (Task 5 fix 2)
- TMPL-11 live: single-commit history assertion PASS on throwaway publish
- TMPL-01 mechanics: is_template toggle + branch-protection requiring 'neutrality' status check verified on throwaway
- NEUT-08 explicitly deferred with raw candidate material preserved at .planning/backlog-neutrality-denylist-candidate.txt
