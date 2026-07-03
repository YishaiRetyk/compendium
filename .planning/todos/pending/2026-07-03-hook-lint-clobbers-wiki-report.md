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
