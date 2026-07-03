# Pre-commit lint step clobbers the wiki-health report + spams log.md per commit

**Surfaced:** 2026-07-03, first-ever live runs of .githooks/pre-commit (hooks had been
disabled since April — Phase 24 review finding #2 reinstalled them).

**Symptom:** the hook's `bin/lint.sh --strict --staged --category provenance` writes
`wiki-cloud/maintenance/lint-report.md` (overwriting the full wiki-health report with a
0-findings staged-scope result) and appends a `## [date] lint | wiki-cloud health check`
block to `wiki-cloud/log.md` — one per commit. Pre-existing lint behavior (report+log are
unconditional side effects of a non-dry-run run), newly visible now that the hook actually runs.

**Interim practice:** `git checkout -- wiki-cloud/log.md wiki-cloud/maintenance/lint-report.md`
after commits if the mutation is unwanted, or commit it deliberately after a FULL lint run.

**Fix (post-v1.5-parity or as a hook-side change — the hook is NOT parity-frozen):** either
give lint a `--no-report` flag for gate-mode runs (lint behavior change → after MIG-02 or in
lockstep both impls), or have the hook snapshot/restore the two files around its lint step.

---

**RESOLVED: 2026-07-03 (Phase 26 / 26-03).** Chose the cleaner root-cause fix over a flag:
`src/compendium/lint.py` now gates the report+log write block on
`not STAGED_MODE and not CI_MODE` (a non-interactive VALIDATION run must not mutate the
wiki; only a plain interactive maintenance `lint` writes them). The migration parity bar
that forbade this behavior change was retired in 26-02, so no `--no-report` seam or
hook-side snapshot/restore is needed. Pinned by `tests/test_lint_readonly_modes.py`
(--staged/--ci byte-unchanged; plain `lint` still writes). The `git checkout --` interim
dance is retired.
