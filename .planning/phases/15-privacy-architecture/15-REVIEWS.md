---
phase: 15
reviewers: [codex]
reviewed_at: 2026-06-04T13:07:56Z
plans_reviewed: [15-00-PLAN.md, 15-01-PLAN.md, 15-02-PLAN.md]
note: "claude CLI skipped — review ran inside Claude Code (CLAUDE_CODE_ENTRYPOINT=cli); the self-CLI is skipped for independence per the review workflow. Codex provided the independent external review. Findings below were additionally code-verified against the live tree by the orchestrating agent."
---

# Cross-AI Plan Review — Phase 15 (Privacy Architecture)

## Codex Review

**Summary**

The plans are thoughtful and security-aware, but not ready to execute as written. The biggest issue is that they treat the privacy rewrite as mostly path churn, while several current guards encode privacy as a semantic predicate over page frontmatter, source-summary frontmatter, raw-source frontmatter, and old source-directory defaults. Collapsing that to "path starts with `wiki-local/`" breaks phase-13 tests and may silently reclassify source-derived local claims as cloud-safe. The wave structure also contradicts the claimed atomicity: Plan 15-01 commits a migrated tree while some privacy guards are knowingly broken until Plan 15-02.

**Strengths**

- The phase is decomposed sensibly into RED tests, migration, then enforcement.
- The plans correctly identify the security reality that `.claude/settings.cloud.json` is fail-open and that object-level separation is the only strong guarantee.
- Route-then-strip is the right migration order for existing pages.
- The D-09 cloud→local wikilink rule is a good structural addition.
- The decision record requirement is well-scoped and should preserve why the architecture changed.
- The plans correctly call out `check-neutrality.sh` as more than a simple path rewrite.

**Concerns**

- **HIGH: Phase-13 regression suite is incompatible with the proposed resolver collapse.** Current tests directly assert the old ladder: `tests/phase-13/test_privacy_resolve_precedence.sh` expects frontmatter, `/local-only/`, `/cloud-safe/`, and fail-closed defaults. `tests/phase-13/test_claim_page_privacy.sh` and `tests/phase-13/test_raw_source_privacy.sh` also unit-test old `privacy:` behavior. Plan 15-02's acceptance criterion "phase-13 audit suite green" does not plan to rewrite those tests or define equivalent structural fixtures. **Code-verified:** these three tests pass `privacy` frontmatter dicts directly to `resolve_effective_claim_privacy` / `resolve_source_privacy` and assert precedence/stricter-wins outcomes that the collapse deletes — they fail regardless of any path re-key.

- **HIGH: The collapsed FAITH-04 predicate loses raw-source privacy.** `audit-claims.sh` calls `resolve_effective_claim_privacy(fm, rel, sfm, raw_source_fm, (sfm or {}).get('path',''))` at line ~745. That last path is a raw `sources/...` path, not a `wiki-local/...` path. Under the proposed predicate ("effective local_only IFF page OR any contributing source under `wiki-local/`"), a local-only raw source can never make a claim local-only unless raw sources also get a structural local tier. **Code-verified:** sources live under `sources/` (no `sources/local-only/` or `wiki-local/` prefix), so every source-derived claim becomes cloud_safe — a silent privacy regression at the audit egress boundary, exactly the surface PRIV-05's "no behavioral regression" forbids.

- **HIGH: Source-summary tier is not available to the resolver as planned.** `source_registry` stores source frontmatter by id, not the source-summary page's repo path (`bin/audit-claims.sh:246-250`). **Code-verified:** `source_registry[sfm['id']] = sfm` keeps only the frontmatter dict. If source summaries move to `wiki-local/sources/`, the resolver still cannot see that unless the registry retains a `summary_rel_path`.

- **HIGH: Plan 15-01 contradicts audit control-plane relocation.** Requirements (PRIV-01/D-08) move audit control-plane local. Plan 15-01 Task 1 moves the existing audit files to `wiki-local/maintenance/`, but Task 3 re-keys `bin/audit-claims.sh`'s default report path to `wiki-cloud/`. **Code-verified:** `audit-claims.sh:538` derives `state_path` from `WIKI_DIR` and `:713` defaults the report to `wiki/maintenance/audit-report.md`; a blanket `wiki/`→`wiki-cloud/` re-key would regenerate `audit-report.md`/`audit-state.md` on the CLOUD side, directly violating PRIV-01.

- **HIGH: Generated maintenance frontmatter is not covered.** `bin/audit-claims.sh` still generates `privacy: local_only` in audit-state/report templates (lines 863, 936) and `bin/lint.sh` still generates `privacy: cloud_safe` in lint-report output (line 2434). **Code-verified.** Removing the field repo-wide (D-01) requires updating these generated templates too; otherwise the next audit/lint run re-introduces the `privacy` field the migration just stripped.

- **HIGH: `bin/lint.sh` still has `privacy` in required/schema validation.** **Code-verified:** `privacy` is in the required base-field list at `bin/lint.sh:381` and the enum is validated at `:1065-1066`. Plan 15-01 mentions "lint-green" but no task explicitly removes `privacy` from the required-field set. Without that removal, every stripped page fails the yaml check (54 "missing required field" errors) — the D-02 lockstep "no lint-red intermediate" invariant is unsatisfiable as the tasks are currently written.

- **HIGH: D-02 atomicity is not actually preserved.** Plan 15-01's own threat register (T-15-07) admits `check-neutrality.sh`'s local leak-source predicate is broken (returns empty) until Plan 15-02. That is a committed intermediate security regression even if lint is green. If D-02 means "no degraded tree," Plan 02's predicate re-keys (check-neutrality, check-privacy, privacy_resolve, audit) belong in the same lockstep commit as the field strip.

- **HIGH: Pass C blanket `wiki/` → `wiki-cloud/` fixture rewrite is unsafe.** Some fixture references are audit maintenance paths that should become `wiki-local/maintenance`, not `wiki-cloud/maintenance` (e.g. `tests/phase-13/test_report_privacy_local_only.sh`, `test_checkpoint_advance.sh`). Others intentionally test old privacy-resolver semantics and should be rewritten structurally or archived, not mechanically re-keyed. **Code-verified + scope undercount:** there are ~94 prior-phase `.sh` files referencing bare `wiki/` (phase-13 alone: 31; phase-11: 18; phase-12.2: 11; phase-09: 12), not the "~40" the plan estimates. The Pass C acceptance criterion only validates 4 of 9 phase directories (phase-07/08/09/13), silently omitting phase-09.1/10/11/12.1/12.2.

- **MEDIUM: Plan 15-00 test count is inconsistent.** The objective says "1 harness + 9 RED test files" but `files_modified` and the task bodies create only 8 `test_*.sh`. `test_neutrality_leak_source_rekey.sh` appears only in Plan 15-02 (Wave 2), so the W1 regression tripwire is not actually RED upfront — a Nyquist gap (a requirement's failing gate does not exist before the structural change).

- **MEDIUM: `check-privacy.sh` re-key is underspecified.** "Flag wiki-local content copied into docs" is not detectable by path prefix once the file is copied to `docs/private.md`. A path-only scanner can catch `docs/wiki-local/...`, not arbitrary copied content. If content-equivalence or term scanning is expected, say so explicitly.

- **MEDIUM: Lint D-09 may not see both tiers.** The proposed test runs `lint.sh --category linkres wiki-cloud/` but expects it to resolve a target in sibling `wiki-local/`. Current lint page discovery is rooted in one wiki dir (`WIKI_DIR`). The plan needs an explicit two-root discovery model for link resolution, or the `page_tier` map cannot be built over local targets.

- **MEDIUM: Docs and public metadata are under-scoped.** Existing docs, PR template, and fixtures still reference `privacy: local_only`. Plans update some schema files and `docs/reference/privacy-model.md`, but not all user-facing docs (`PRIVACY.md`, README/quickstart/manual-setup, `.github/pull_request_template.md`).

**Suggestions**

- Collapse Plan 15-01 and the predicate portions of 15-02 into one security-atomic commit, or move `check-neutrality`, `check-privacy`, `privacy_resolve`, audit report/state generation, and lint required-field changes into Plan 15-01.
- Define structural privacy for raw sources before touching FAITH-04. Options: `sources-cloud/` + `sources-local/`, local raw sources inside a nested private repo, or a hard rule that raw `sources/` is cloud-safe only (documented and tested).
- Change `audit-claims.sh` to build a two-tier page universe and store source-summary repo paths in `source_registry`.
- Rewrite phase-13 privacy tests to structural equivalents instead of blanket path rewrites. Keep old precedence tests only if explicitly legacy tests against a migration helper, not active acceptance tests.
- Replace Pass C with a manifest-driven migration: classify each fixture as cloud page, local audit control-plane, legacy brownfield input, or obsolete old-privacy test. Widen the acceptance grep to all 9 phase dirs.
- Make `bin/audit-claims.sh` write audit state/report to `wiki-local/maintenance/` and omit `privacy` frontmatter; make `bin/lint.sh` omit `privacy` from generated lint-report.
- Add Wave 0 RED tests for generated maintenance files, lint required-field removal, source-derived local claims, and two-root audit/link resolution.
- Tighten `check-privacy.sh`'s promise: either keep it a path/release allowlist guard only, or add hash/term-based checks if it must catch copied local content.

**Risk Assessment**

Overall risk: **HIGH**. The architecture goal is good, but the current plans leave load-bearing privacy semantics ambiguous at exactly the audit egress boundary. The biggest danger is not a visible migration failure; it is a green test suite after mechanically rewriting fixtures while source-derived local claims become cloud-safe. The phase needs a sharper structural model for raw sources and a security-atomic tooling re-key before execution.

---

## Consensus Summary

Only one external reviewer (Codex) was invoked — the `claude` CLI was skipped because this review executed inside Claude Code, and the workflow skips the self-CLI for independence. There is therefore no second-model cross-check; instead, every Codex finding below was independently **code-verified against the live tree** by the orchestrating agent before being recorded. Line references and the fixture-count correction are confirmed against `bin/audit-claims.sh`, `bin/lint.sh`, `bin/lib/privacy_resolve.py`, and `tests/phase-13/`.

### Agreed Strengths

- Sound three-wave decomposition (RED tests → migration → enforcement).
- Honest security posture: deny-profile labeled fail-open; separate-repo named as the only fail-closed guarantee; object-level (`git show`) leak surface acknowledged.
- Route-then-strip migration ordering (D-03) is correct.
- D-09 asymmetric cloud→local link prohibition is a valuable structural addition.

### Agreed Concerns (highest priority — all code-verified)

1. **(HIGH) Resolver collapse breaks the phase-13 acceptance gate.** `privacy_resolve.py` is collapsed to a path-prefix predicate, but `tests/phase-13/{test_privacy_resolve_precedence,test_claim_page_privacy,test_raw_source_privacy}.sh` unit-assert the deleted 3-level/stricter-wins behavior. "phase-13 audit suite green" cannot hold without rewriting/retiring those tests — work no plan assigns.
2. **(HIGH) Source-tier privacy is lost.** Raw sources live under `sources/`, never `wiki-local/`; `source_registry` keeps only frontmatter (not a repo path). The collapsed predicate makes every source-derived claim cloud_safe — a silent FAITH-04 privacy regression. No structural privacy model for raw `sources/` is defined.
3. **(HIGH) Audit control-plane mis-routed.** Plan 15-01 Task 3 re-keys `audit-claims.sh` paths to `wiki-cloud/`, which would write the (local-only) audit-state/report to the cloud tier — contradicting PRIV-01/D-08.
4. **(HIGH) Generated frontmatter re-introduces `privacy`.** `audit-claims.sh` emits `privacy: local_only` and `lint.sh` emits `privacy: cloud_safe`; neither plan strips the field from these generators, so the next tool run undoes the repo-wide D-01 strip.
5. **(HIGH) `privacy` not removed from lint required/enum validation.** `bin/lint.sh:381` lists `privacy` as required and `:1065` validates the enum. Stripping the field from 54 pages while lint still requires it produces 54 yaml errors — the D-02 "no lint-red intermediate" invariant is unsatisfiable as written.
6. **(HIGH) D-02 atomicity violated.** The Plan-01 commit knowingly leaves `check-neutrality.sh`'s leak-source predicate dead (T-15-07) until Plan 02 — a committed intermediate security regression.
7. **(HIGH) Pass C blanket fixture re-key is unsafe and under-scoped.** Local-tier audit paths and old-privacy-semantics tests cannot be blindly `wiki/`→`wiki-cloud/` rewritten; the real count is ~94 files (not "~40") and the acceptance grep covers only 4 of 9 phase dirs.

### Divergent Views

None — single reviewer. The orchestrator's pre-review code analysis converged with Codex on concerns 1, 2, and 7 independently, which raises confidence in those three in the absence of a second model.
