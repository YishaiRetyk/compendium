---
phase: 22-repository-source-type
completed: 2026-07-03
plans_completed: 3/3
requirements_completed: [REPO-01, REPO-02, REPO-03, REPO-04, REPO-05, REPO-06]
---

# Phase 22 Summary — Repository Source Type

**Consolidated summary for all 3 plans** (executed in one autonomous session; per-plan detail lives in the commit messages and 22-VERIFICATION.md).

- **22-01 (schema, commit 40c5299):** `schema/reference/repository-ingestion.md` authoritative convention — repository as the extension contract's first PRIMARY new-type instance (4/5 dimensions change; the inverse verdict of pdf/video by the same rule); retro-fit table 8th row + finalized registry verdict; frontmatter enum + field block; `#path:`/`#commit:` locator rows; ingest Pass-0 bullet + granularity row; routing row byte-synced across all four carriers (AGENTS.md ≡ CLAUDE.md + template + regenerated canonical fixture); inclusion-audit re-stamped 291 @ 2026-07-03.
- **22-02 (tooling, commit f4ee7c0):** lint `repository` enum + conditional required-fields gate (repo_url/commit_sha/default_branch, 40-hex shape; LINT_VERSION 1.11.0); audit `_resolve_path`/`_resolve_commit` dispatched before `#para`/`#p` (D-11); `bin/repo-snapshot.sh` mechanical acquisition glue; `tests/phase-22/` TDD harness.
- **22-03 (validation, commits 2e3852b/e5802d1/c08718c):** real end-to-end ingest of `open-gsd/gsd-core` at `69fef7c0` — which caught LIVE external drift (the documented repo home `gsd-build/get-shit-done` is an archived redirect; the project renamed to `@opengsd/gsd-core`); entity `gsd` upgraded from report-derived to repository-direct claims (the Model C promotion story exercised); DR `dr-2026-07-03-repository-source-type`; one mid-validation defect (fenced CHANGELOG excerpt truncating the registry) fixed with regression test.
- **Review round (commit 311d252, 22-REVIEW.md):** 10-angle adversarial review, 15 findings, all fixed — headline: shared `_fence_mask_lines` across ALL four audit resolvers (the fence fix had been one resolver too shallow), locator-grammar closure (whole-file/single-line/inverted-range), hollow-passage repair on the live snapshot (logged same-phase curation amendment), generator hardening (H1 demotion, clobber guard, license order).

**Deviations from plan:** target repo changed mid-flight (gsd-build/get-shit-done → open-gsd/gsd-core) because the planned target turned out to be an archived redirect — recorded in the log as a live drift case that motivates Phase 23. Default branch is `next`, not `main` (recorded as-is).
