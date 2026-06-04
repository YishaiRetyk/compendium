---
phase: 15
reviewers: [codex]
reviewed_at: 2026-06-04T16:50:00Z
cycles: 3
cycle_1_reviewed_at: 2026-06-04T13:07:56Z
cycle_2_reviewed_at: 2026-06-04T13:33:23Z
cycle_3_reviewed_at: 2026-06-04T16:50:00Z
plans_reviewed: [15-00-PLAN.md, 15-01-PLAN.md, 15-02-PLAN.md]
note: "claude CLI skipped all three cycles — review ran inside Claude Code (CLAUDE_CODE_ENTRYPOINT=cli); the self-CLI is skipped for independence per the review workflow. Codex provided the independent external review. Findings were additionally code-verified against the live tree by the orchestrating agent. Cycle 2 re-reviewed the replan that addressed cycle 1's 8 HIGH concerns and raised 1 residual HIGH (raw-sources/ boundary). Cycle 3 (FINAL) re-reviews the replan that closed that HIGH via a fail-closed CI-wired guard (bin/check-sources-cloud-safe.sh) + RED regression tripwire; current_high resolved to 0. See the Cycle 3 section appended below."
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

---

# Cross-AI Plan Review — Phase 15 — CYCLE 2 (re-review after replan)

Cycle 1 raised 8 HIGH concerns (7 numbered + the D-02 atomicity framing). The plans were re-planned to address them. Cycle 2 re-runs Codex against the revised plans to assess (a) whether each cycle-1 HIGH is resolved, and (b) whether the replan introduced new concerns. As in cycle 1, the `claude` CLI was skipped (self-CLI, running inside Claude Code); Codex provided the independent external review, and the orchestrating agent code-verified the load-bearing premises against the live tree.

## Orchestrator pre-review code verification (cycle 2)

Before invoking Codex, every cycle-1 HIGH premise was re-checked against the current tree to confirm the replan targets real code:

- **HIGH #5 confirmed live:** `bin/lint.sh:375` `VALID_PRIVACY`, `:378` `BASE_FIELDS` (contains `privacy`), `:1065-1066` enum check — all present. Plan 15-01 Task 3 removes all three.
- **HIGH #4 confirmed live:** `bin/lint.sh:2434` emits `privacy: cloud_safe`; `bin/audit-claims.sh:863,936` emit `privacy: local_only`. Plan 15-01 Task 3 strips all.
- **HIGH #3 confirmed live:** `bin/audit-claims.sh:250` `source_registry[sfm['id']] = sfm` (frontmatter only). Plan 15-01 Task 6 adds `summary_rel_path`.
- **HIGH #2 confirmed live:** `bin/audit-claims.sh:745-746` passes `(sfm or {}).get('path','')` (raw `sources/...` path) into `resolve_effective_claim_privacy`. Plan 15-01 Task 6 swaps it to the summary path.
- **HIGH #1 confirmed live:** the 3 phase-13 resolver tests exist and `bin/lib/privacy_resolve.py` is the 3-level ladder (`three-level`, `stricter wins`, `fail-closed`). Plan 15-01 Task 5 rewrites the tests; Task 6 collapses the ladder.
- **HIGH #6 confirmed live:** `bin/check-neutrality.sh:265` walks `os.path.join(ROOT,"wiki")`, `:279` has the `^privacy:\s*local_only` regex, `:308` preserves the git-history literal. Plan 15-01 Task 6 re-keys the walk + drops the dead regex in the SAME commit.
- **HIGH #7 confirmed live + count corrected:** bare `wiki/` references across the 9 phase dirs = 6+6+12+3+6+18+1+11+31 = **94 files** (cycle-1 estimate "~40" was an undercount; the replan now says 94). Plan 15-01 Task 1 manifest-classifies them across all 9 dirs.
- **Raw-source state:** `sources/` has no `local/cloud` tier and currently zero raw sources carry `privacy: local_only`. The planned deny profile is `Read(./wiki-local/**)` only — `sources/` is NOT denied to cloud sessions (relevant to the new HIGH below).

## Codex Review (cycle 2)

**Summary**

The replan is much stronger and closes most cycle-1 gaps in the right place: Wave 0 now has RED tests, Plan 15-01 pulls the privacy predicate rewrites into the security-atomic migration, and Plan 15-02 is mostly additive. I would not execute it unchanged yet: the new "raw `sources/` is cloud-safe-only" rule is a real privacy-policy change and is not enforced by the directory boundary, and a few verification criteria remain too vague for a phase whose failure mode is irreversible leakage.

**Cycle-1 HIGH Disposition**

| # | Verdict | Justification |
|---|---|---|
| #1 Resolver collapse breaks phase-13 gate | RESOLVED | Plan 15-01 Task 5 explicitly rewrites `test_privacy_resolve_precedence`, `test_claim_page_privacy`, and `test_raw_source_privacy` to structural assertions, and Task 4(c) requires the full phase-13 suite green. |
| #2 FAITH-04 loses raw-source privacy | PARTIALLY RESOLVED | Plan 15-01 Task 6 fixes the audit egress predicate by storing `summary_rel_path` and passing the source-summary path, but "raw `sources/` is cloud-safe-only" is not a safe structural model for sensitive raw sources. |
| #3 Source summary tier unavailable + audit control-plane mis-routed | RESOLVED | Plan 15-01 Task 6 adds `summary_rel_path` / `source_summary_path`, and Task 3 routes audit state/report to `wiki-local/maintenance/` with acceptance forbidding `wiki-cloud/maintenance/audit-*`. |
| #4 Generated maintenance frontmatter reintroduces `privacy` | RESOLVED | Plan 15-00 adds `test_generated_frontmatter_clean.sh`; Plan 15-01 Task 3 strips audit/lint generated templates, and Task 4 strips schema templates/examples. |
| #5 Lint still requires/validates `privacy` | RESOLVED | Plan 15-01 Task 3 removes `privacy` from `BASE_FIELDS`, removes `VALID_PRIVACY` / `Invalid privacy`, and requires `test_lint_required_field_dropped.sh` green. |
| #6 D-02 atomicity violated | RESOLVED, execution-risk remains | Plan 15-01 Task 6 moves all predicate re-keys into the lockstep commit, and Task 4(d) requires one migration commit with no prior partial commit. |
| #7 Blanket fixture re-key unsafe / under-scoped | PARTIALLY RESOLVED | Plan 15-01 Task 1 correctly replaces blanket rewrite with four manifest buckets across all 9 phase dirs / 94 files, but the manifest has no concrete path, schema, or automated verifier. |

**New Concerns Introduced By The Replan**

- **HIGH — Raw `sources/` remains outside the privacy boundary.** Plan 15-01 Task 6 and Plan 15-02 Task 2 define raw `sources/` as cloud-safe-only, with local sensitivity represented only by the source summary under `wiki-local/sources/`. That protects FAITH-04 classification, but it does not stop a cloud session from reading sensitive raw source files in `sources/` (the planned deny profile is `Read(./wiki-local/**)` only — code-verified: `sources/` is not denied). This is a real hole unless the project now forbids sensitive raw sources. Fix by adding a structural raw-source tier (`sources-cloud/` + `sources-local/`), denying `sources/` to cloud by default, or making migration fail if any existing raw source is not mechanically proven cloud-safe. *(Orchestrator note: cycle-1 Suggestion #2 explicitly listed "a hard rule that raw `sources/` is cloud-safe only, documented and tested" as an acceptable option, and the replan chose exactly that — so this is the sanctioned resolution's residual hole, not an ignored item. It currently bites no one: the creator vault has zero local raw sources today. It is HIGH because it silently changes the forward trust model for any future user with a sensitive raw source, and is unmitigated structurally.)*

- **MEDIUM — Pass C manifest is not reviewable enough.** Task 1 says the helper "emits a per-file classification manifest" but specifies no artifact path, format, or automated assertion. Add a manifest path (e.g. `.planning/phases/15-privacy-architecture/pass-c-manifest.tsv`), require every bare `wiki/` occurrence to be classified, and add a verifier that rejects unclassified bucket-1/bucket-2 occurrences.

- **MEDIUM — Task 1 clean-tree precheck conflicts with creating the helper.** Task 1 says to write `bin/migrate-privacy-dirs.sh`, then Pass 0 verifies `git status --porcelain` is empty. If the helper is untracked/modified, it fails its own precheck. Run the clean-tree check before creating the helper, use an inline block, or explicitly ignore the helper path.

- **MEDIUM — Template byte-equality wording is wrong/ambiguous.** Task 2 / success criteria say `CLAUDE.md ≡ AGENTS.md ≡ template`, but `schema/AGENTS.template.md` is a wizard template with placeholders. The byte-equality invariant should be only `CLAUDE.md ≡ AGENTS.md`; the template is mirrored semantically and validated through the regenerated `canonical-AGENTS.md`.

- **MEDIUM — Two-root lint discovery needs duplicate-ID semantics.** Plan 15-02 Task 1 builds `page_tier[id] = cloud|local` across both roots. If the same `id` exists in both tiers, last-writer-wins can hide or falsely report a cloud→local link. Add a duplicate-ID lint error or make `page_tier[id]` a set with a defined resolution rule.

- **MEDIUM — `check-privacy` test wording conflicts with its documented scope.** Plan 15-00 Task 2 says copied `wiki-local` content into `docs/` should make `check-privacy.sh` exit 2, while Plan 15-01 Task 6 says `check-privacy` is only a path/release guard, not a content scanner. Make the test specifically use `docs/wiki-local/...`; leave arbitrary copied text to `check-neutrality.sh`.

- **LOW — Plan 15-00 Task 2 count drift.** It says "remaining 5 RED tests" / "All 5 files exist" but lists 4. Harmless; correct to avoid executor confusion.

**Remaining Concerns**

- The biggest remaining issue is raw-source privacy (the HIGH above): the replan fixes source-summary-tier classification but not raw-source readability from cloud runs — a trust-model change, not documentation polish.
- The cycle-1 MEDIUM around `check-privacy` scope is still only partly settled: the tests and docs must agree it is path-based while `check-neutrality` handles copied-content terms.
- The Plan 15-02 cloud-deny behavioral check still allows a manual fallback — acceptable only because the docs honestly label the profile fail-open; it must not be treated as a fail-closed gate.

**Risk Assessment**

Overall risk: **HIGH** until raw-source handling is corrected. If the project explicitly guarantees that every raw file under `sources/` is cloud-safe and adds a mechanical migration check for that invariant, the remaining plan risk drops to MEDIUM: mostly large-commit executability, fixture-manifest verification, and two-root lint edge cases.

## Cycle 2 Consensus Summary

The replan resolved 5 of 7 cycle-1 HIGHs cleanly (#1, #3, #4, #5, #6) and partially resolved 2 (#2, #7). It introduced exactly one new HIGH — the raw-`sources/` privacy hole — which is the residual gap of the cycle-1-sanctioned "raw sources are cloud-safe-only" option.

### Cycle-1 HIGH disposition rollup

- **Fully resolved (5):** #1 (phase-13 tests rewritten + suite-green gate), #3 (summary_rel_path + audit control-plane routed local), #4 (generated-frontmatter stripped + gated by a Wave-0 RED test), #5 (privacy removed from lint BASE_FIELDS/enum + gated), #6 (all predicate re-keys pulled into one security-atomic commit). Each is verification-backed by a Wave-0 RED test that goes GREEN only after the fix lands, and each premise was code-verified live.
- **Partially resolved (2):**
  - **#2 (FAITH-04 source-tier privacy):** the audit *classification* egress is fixed (summary-path predicate), but the underlying "raw sources/ cloud-safe-only" model leaves raw sensitive sources structurally readable — this folds into the new HIGH.
  - **#7 (Pass C manifest):** scope is now correct (94 files / 9 dirs / 4 buckets), but the manifest artifact has no specified path/schema/verifier, so the classification is reviewable only by inspecting the helper's runtime output.

### New HIGH (1)

- **Raw `sources/` outside the privacy boundary** — cloud sessions can read sensitive raw source files; the deny profile covers only `wiki-local/`. Sanctioned-option residual; unmitigated structurally. Recommend a structural raw-source tier OR a mechanical migration assertion that every raw source is cloud-safe.

### Net unresolved HIGH count: 1

Counting per the cycle contract: 5 cycle-1 HIGHs are FULLY RESOLVED (verification-backed) and excluded; 2 are PARTIALLY RESOLVED and #2 collapses into the single new HIGH (raw-source hole). The raw-source HIGH is the one unresolved HIGH carrying forward. #7's partial state is a MEDIUM-grade gap (manifest reviewability), not a standalone HIGH.

**current_high = 1** (the raw-`sources/` privacy boundary hole).

### Divergent Views

None — single external reviewer both cycles. Orchestrator code-verification independently confirmed the deny-profile scope (`Read(./wiki-local/**)` only) and the empty raw-source-local state, corroborating the new HIGH's premise.

---

# Cross-AI Plan Review — Phase 15 — CYCLE 3 (FINAL: re-review after raw-source guard replan)

Cycle 2 closed with exactly **one** unresolved HIGH: the raw-`sources/` privacy-boundary hole (cloud sessions can read sensitive raw files under `sources/`; the deny-profile covers only `wiki-local/`). The cycle-3 replan closes that HIGH with a fail-closed, CI-wired guard. Cycle 3 re-runs Codex to confirm (a) the raw-source HIGH is now FULLY RESOLVED, (b) the resolution is structural (not relocation), and (c) the replan introduced no new HIGH. As in cycles 1–2, the `claude` CLI was skipped (self-CLI, running inside Claude Code); Codex provided the independent external review, and the orchestrating agent code-verified every load-bearing premise against the live tree.

## Orchestrator pre-review code verification (cycle 3)

Before invoking Codex, every cycle-3 premise was re-checked against the current tree:

- **Raw-source state confirmed:** `sources/` has **23** raw `.md` files, **all cloud-safe** — zero carry `privacy: local_only`, and no `sources/local-only/` directory exists. The guard bites no one today; it protects the forward trust model.
- **Deny-profile scope confirmed:** the planned profile is `{ "permissions": { "deny": ["Read(./wiki-local/**)"] } }` — `sources/` is genuinely **not** read-denied to cloud (`.claude/settings.cloud.json` is a Plan-02 artifact, not yet created). So the "prevent sensitive content from existing un-migrated" model is the correct structural lever, not "deny reads."
- **Guard uses proper frontmatter parsing:** `bin/lib/brownfield_yaml.py:186` `read_fm_body` exists; Plan 15-01 Task 6 mandates the guard parse via `read_fm_body` (NOT grep) to avoid prose false-hits.
- **CI host confirmed:** `.github/workflows/lint.yml` has a live `privacy-leak` job (runs `bin/check-privacy.sh`); the new `bin/check-sources-cloud-safe.sh` is wired alongside it.
- **Predicate re-keys target real code (D-02 atomicity):** `bin/lib/privacy_resolve.py` is still the 3-level ladder (docstring lines 6–43: "three-level precedence", "stricter wins", "fail-closed"); `bin/check-neutrality.sh:262` `source_local_only_wiki()` walks `os.path.join(ROOT,"wiki")` (:265) with the to-be-dead `^privacy:\s*local_only` regex (:279). Plan 15-01 Task 6 collapses the ladder and re-keys the leak-source predicate in the **same** security-atomic commit — no dead-predicate intermediate.
- **Wave-0 tripwire present:** `tests/phase-15/test_raw_sources_cloud_safe_guard.sh` is in the Plan 15-00 RED-test scaffold (13 RED tests total — the cycle-2 LOW count drift "5 RED/4 files" is resolved; the plan now states 13 consistently).

## Codex Review (cycle 3)

**Summary**

Phase 15 is ready to execute. The carried-forward raw-`sources/` HIGH is now addressed by an explicit repository invariant, CI enforcement, and a RED regression test. `current_high` moves to **0**.

**Cycle-2 HIGH Disposition — raw-`sources/` boundary: RESOLVED**

The raw-`sources/` concern is fully resolved under the chosen privacy model. Since `sources/` is not read-denied to cloud sessions, the structural control must be **admission control**: sensitive raw content must not *exist* there. The new `bin/check-sources-cloud-safe.sh` guard, its CI wiring in `privacy-leak`, and `test_raw_sources_cloud_safe_guard.sh` create a verifiable fail-closed boundary for that invariant. This is acceptable as a structural resolution — **not** merely relocation of the hole — because the model is now explicit: `sources/` is cloud-safe-only; local-only material belongs elsewhere or must be migrated before cloud use. The docs correctly avoid claiming cloud sessions are denied from reading `sources/`.

Previously resolved HIGHs stay resolved: the predicate re-keys remain security-atomic, resolver behavior is structural, neutrality/privacy/audit checks are re-keyed together, generated templates/lint no longer preserve `privacy`, and Wave-0 tests cover those regressions. The two prior partials remain non-HIGH: D-09 cross-tier link checking is now planned with enforcement, and the cloud deny-profile is still fail-open but honestly labeled and backed by verification/runbook guidance.

**New Concerns**

- **No new HIGH concerns.**
- **MEDIUM** — The guard should fail on missing or malformed raw-source frontmatter and ideally require explicit `privacy: cloud_safe`, not only *absence* of `privacy: local_only`. If the script already does this, the concern is moot; if not, the architecture is still materially improved, but the invariant leans more on curator discipline. *(Orchestrator note: a reasonable hardening for execution — but non-blocking. The 23 current raw sources carry no privacy frontmatter at all, so an "absence-of-local_only" check already passes them; requiring explicit `cloud_safe` would be a stricter posture worth adopting at execution time. Filed as a MEDIUM polish item, not a phase gate.)*

**Net Unresolved HIGH Count: 0**

**Risk Assessment:** LOW–MEDIUM. Low for the carried-forward HIGH (the structural invariant is now testable and CI-enforced). Medium residual operational risk only around source-misclassification or bypassing the documented source-ingestion discipline.

## Cycle 3 Consensus Summary

The cycle-3 replan closes the single carried-forward HIGH (raw-`sources/` boundary) with a fail-closed, CI-wired admission-control guard plus a Wave-0 RED regression tripwire. Codex and the orchestrator's independent code-verification converge: this is a genuine structural resolution, not a relocation, because `sources/` must remain cloud-readable for legitimate ingest — so blocking sensitive content from *existing* un-migrated (and failing CI the moment it appears) is the correct lever. No new HIGH was introduced.

### Cumulative HIGH disposition across all 3 cycles

- **Cycle 1:** 8 HIGH raised.
- **Cycle 2:** 5 FULLY RESOLVED (verification-backed), 2 PARTIALLY RESOLVED, **1 new HIGH** (raw-`sources/` boundary). Net unresolved = 1.
- **Cycle 3:** the 1 carried-forward HIGH **FULLY RESOLVED** (fail-closed guard + CI wiring + RED tripwire). 0 new HIGH. The two cycle-2 partials remain MEDIUM-grade (D-09 enforcement now planned; deny-profile fail-open but honestly labeled) — neither is a standalone HIGH. Net unresolved = **0**.

### New / carried MEDIUM items (non-blocking, for execution)

- Harden `bin/check-sources-cloud-safe.sh` to require explicit `privacy: cloud_safe` (or fail on malformed/missing frontmatter), rather than only asserting absence of `local_only` (cycle-3 MEDIUM).
- Pass-C manifest reviewability is now specified (path + TSV schema + verifier) — was cycle-2 MEDIUM, now addressed in Plan 15-01 Task 1.
- check-privacy path-vs-content scope honesty documented in Plan 15-02 Task 2 (cycle-1/2 MEDIUM, addressed).

### Net unresolved HIGH count: 0

**current_high = 0** — no unmitigated HIGH concern remains. Phase 15 is cleared to execute.

### Divergent Views

None — single external reviewer all three cycles. Orchestrator code-verification independently confirmed the raw-source state (23 cloud-safe sources, no `sources/local-only/`), the deny-profile scope (`Read(./wiki-local/**)` only), and that the guard parses frontmatter via `read_fm_body` — corroborating the RESOLVED verdict.
