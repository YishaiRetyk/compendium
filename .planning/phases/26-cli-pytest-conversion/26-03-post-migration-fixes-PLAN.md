---
phase: 26-cli-pytest-conversion
plan: 03
type: execute
wave: 2
depends_on: [02]
requirements: [CUT-02]
files_modified:
  - src/compendium/lint.py (read-only --staged/--ci)
  - src/compendium/audit_claims.py (same guard if it writes on a validation path)
  - tests/test_lint_readonly_modes.py (new)
  - .planning/todos/pending/2026-07-03-hook-lint-clobbers-wiki-report.md (retire)
  - (optional) src/compendium/{search,validate_op,release}.py — cheap 25-REVIEW items
autonomous: true
---

<objective>
The user's headline concern: kill the pre-commit lint-clobber. Now collision-free (26-02
retired the frozen-bash oracle that pinned the buggy write behavior). Make lint's
non-interactive validation modes READ-ONLY, and fold in the cheap, safe deferred
25-REVIEW faithful-bash fixes.
</objective>

<context>
- The clobber (25-REVIEW F15, and the filed todo): `src/compendium/lint.py` ~L2696–2706
  writes `wiki-cloud/maintenance/lint-report.md` + appends a `## [date] lint | wiki-cloud
  health check` entry to `wiki-cloud/log.md` on every non-dry-run/text call — INCLUDING
  the hook's `--strict --staged`. A read-only check must not mutate the repo.
- Fix (26-CONTEXT spec): gate that write block additionally on `not STAGED_MODE and not
  CI_MODE`. Only a plain interactive `bin/lint.sh` maintenance run writes the report/log.
  Check audit_claims.py for an analogous checkpoint-write on `--verifier`/validation
  paths and apply the same read-only-on-validation principle.
- This is a SANCTIONED behavior change now (the parity bar retired in 26-02). It is also
  the correct design regardless of parity.
- Optional cheap 25-REVIEW faithful-bash items to fold in IF low-risk and clearly
  correct (do NOT over-reach): `open(..., encoding='utf-8')` at the validate_op /
  check_privacy read sites (C-locale crash guard); the release.py SIGTERM cleanup
  (signal handler around staging). The search byte-vs-char and audit except→None items
  are behavior-nuanced — leave to a dedicated pass, note in the SUMMARY, do NOT bundle.
</context>

<tasks>
1. Gate the lint report+log write on `not STAGED_MODE and not CI_MODE`. Apply the
   analogous read-only guard in audit_claims.py if present.
2. tests/test_lint_readonly_modes.py: assert `lint --staged` and `lint --ci` leave
   log.md + lint-report.md byte-unchanged in a fixture, AND that a plain `lint` run DOES
   write them (the interactive write path stays alive). Run it green.
3. Retire the `2026-07-03-hook-lint-clobbers-wiki-report` todo (move to done/ or delete
   with a note in the SUMMARY).
4. (Optional) the two named cheap fixes + their tests, only if clearly safe.
5. Full `pytest -n auto` green. Make a REAL wiki-touching commit and CONFIRM the hook no
   longer dirties wiki-cloud/log.md (the dance is gone) — this is the acceptance proof.
6. Commit `fix(26): lint/audit --staged/--ci are read-only — end the pre-commit
   wiki-clobber (25-REVIEW F15)`. SUMMARY records the before/after and what was left
   deferred.
</tasks>

<acceptance>
- After a wiki-touching commit, `git status` shows NO stray change to wiki-cloud/log.md
  or lint-report.md — the clobber is gone; the strip/checkout dance is retired.
- `lint --staged`/`--ci` provably read-only; plain `lint` still writes report+log.
- `pytest -n auto` green.
</acceptance>
