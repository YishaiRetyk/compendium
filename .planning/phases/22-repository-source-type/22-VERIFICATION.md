---
phase: 22-repository-source-type
verified: 2026-07-03T00:00:00Z
status: passed
score: 6/6
overrides_applied: 0
---

# Phase 22: Repository Source Type — Verification Report

**Phase Goal:** Code repositories can be acquired via a documented snapshot pipeline and ingested as a first-class primary source type, with file/line-anchored provenance that the audit can actually resolve.
**Verified:** 2026-07-03
**Status:** PASSED (re-verified post-review — see the Review Round addendum at the bottom)
**Re-verification:** Yes — the xhigh code review (22-REVIEW.md) proved the initial SC-6 "10/10 locators resolve" partially hollow (non-None ≠ usable passage); after the 15-finding fix pass, resolution was re-proven at passage level (worklist: every sampled repo passage substantive, `#sec:readme` 619 chars containing the cited text, `#commit:` passage containing the counted facts)

---

## Goal Achievement

### Observable Truths (success criteria from ROADMAP.md)

1. **Contract evaluation + enum + Pass-0** — PASS. `schema/reference/source-types.md` retro-fit table has the 8th row (`repository`, primary, live drift) and the registry row's verdict is finalized (NEW PRIMARY TYPE, 4/5 dimensions, convention-doc link). `frontmatter.md` enum includes `repository`; `ingest.md` Pass-0 has the explicit first-class-NOT-sub-case bullet (D-12). Evidence: commit 40c5299.
   - REQ: **REPO-01: Complete**
2. **Acquisition runbook + snapshot bundle** — PASS. `schema/reference/repository-ingestion.md` (authoritative, routed from the routing table in AGENTS.md ≡ CLAUDE.md + template + regenerated canonical fixture — byte-equality test PASS) documents the bundle: metadata + curated docs + `## Excerpts` registry, explicitly NOT a full clone. `bin/repo-snapshot.sh` scaffolds it (tests/phase-22/test_repo_snapshot.sh 5/5 on a local fixture repo, no network). Evidence: commits 40c5299, f4ee7c0.
   - REQ: **REPO-03: Complete**
3. **Locators documented + audit-resolvable** — PASS. `provenance.md` Locator Types gained `#path:`/`#commit:` rows + example. `bin/audit-claims.sh` `_resolve_path`/`_resolve_commit` dispatched before `#para`/`#p` (D-11 guarded by T1). Honest degradation verified: missing excerpt, foreign sha, out-of-range → `insufficient-locator` (T4–T6). **Live defect found during validation:** quoted markdown headings inside excerpt fences truncated the registry (2/5 live locators unresolvable) — fixed fence-aware with regression case T3b; live re-audit 10/10 resolve, 0 insufficient-locator. Evidence: commits f4ee7c0, fix commit after 2e3852b; tests/phase-22 3/3 suites.
   - REQ: **REPO-02: Complete**
4. **Epistemic split documented and exercised** — PASS. Convention table in repository-ingestion.md (code `sourced` / self-description claim-level `tentative` / support_type stays `direct`); exercised on the live ingest: `gsd.md` + source summary hedge the "light-weight" and reliability-pitch claims `[epistemic:: tentative]` while `#path:`/`#commit:` claims are `sourced`. `knowledge_domain: software` on both pages.
   - REQ: **REPO-04: Complete**
5. **Lint enforcement** — PASS. D-09 enum extended; conditional required-fields check (`repo_url`/`commit_sha`/`default_branch`, 40-hex sha shape) — tests/phase-22/test_lint_repository_fields.sh 4/4; LINT_VERSION 1.11.0; live tree `bin/lint.sh --dry-run` exits 0 (0 errors; delta vs pre-phase baseline is designed contradiction-candidate warnings on the upgraded entity page).
   - REQ: **REPO-05: Complete**
6. **End-to-end validation ingest** — PASS. Real repository `open-gsd/gsd-core` acquired via `bin/repo-snapshot.sh` at commit `69fef7c0` (branch `next`) into `sources/2026/2026-07/2026-07-03-gsd-core-repo/`; source summary + entity `gsd` upgrade with `#path`-anchored direct provenance; post-commit source-scoped audit: **10/10 repository-source claims resolve** (verdict `insufficient` = passage resolved, verifier not run — the review-only contract; 0 `insufficient-locator`). Bonus finding: the previously-documented repo home is an archived redirect — a live external-drift case, recorded in the log and the DR, feeding Phase 23. Evidence: commits 2e3852b, c08718c; `docs(audit)` checkpoint commit.
   - REQ: **REPO-06: Complete**

## Gates

- tests/phase-22: 3/3 suites (15 cases + T3b regression)
- Cross-suite baseline: phase-09 (25/31), phase-13 (31/33), phase-20 (4/5) — identical pass/fail sets at the pre-phase baseline (stash-verified); no regressions introduced
- `bin/sync-claude.sh --check`, `bin/check-neutrality.sh`, `bin/gen-skills.sh --check`, `bin/lint.sh` (incl. `routing`): all exit 0
- `tests/phase-08/test_canonical_byte_equality.sh`: PASS (fixture regenerated with the routing row)

## Requirements Status

- REPO-01: Complete
- REPO-02: Complete
- REPO-03: Complete
- REPO-04: Complete
- REPO-05: Complete
- REPO-06: Complete
