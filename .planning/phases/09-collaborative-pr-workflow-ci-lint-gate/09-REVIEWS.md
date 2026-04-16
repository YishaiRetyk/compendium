---
phase: 9
reviewers: [gemini, codex]
reviewed_at: 2026-04-16T06:17:02Z
plans_reviewed:
  - 09-01-test-harness-and-fixtures-PLAN.md
  - 09-02-lint-flags-json-ci-version-PLAN.md
  - 09-03-lint-strict-escape-hatch-contributor-PLAN.md
  - 09-04-privacy-ingest-search-contributor-PLAN.md
  - 09-05-ci-workflow-agents-amendments-pr-template-PLAN.md
  - 09-06-contributing-docs-integration-PLAN.md
---

# Cross-AI Plan Review — Phase 9: Collaborative PR Workflow + CI Lint Gate

## Gemini Review

This review covers the implementation plans for **Phase 9: Collaborative PR Workflow + CI Lint Gate**.

## Summary
The plans are exceptionally detailed, demonstrating a deep understanding of both the existing v1.0 codebase and the new requirements for collaborative features. The architecture is robust, utilizing "pattern-twin" scripts (`bin/check-privacy.sh` mirroring `check-neutrality.sh`) and a clever three-job CI workflow that separates structural health from quality-ratchet enforcement. The use of a JSON-to-Annotation shim for PR feedback is a highly efficient, zero-dependency choice that aligns perfectly with the project's mandates. The TDD approach in Wave 0 (09-01) ensures that all subsequent tasks have the necessary fixture coverage to verify complex git-status and frontmatter-leak scenarios.

## Strengths
- **Severity Policy Design:** The orthogonal design of `--ci` and `--strict` (09-02, 09-03) solves the risk of "performative linting" by allowing draft iteration while enforcing structural correctness and ensuring high quality at merge time.
- **Attribution Hygiene:** The resolution flow for `contributor::` (09-04 T2) meticulously avoids leaking bare emails (Pitfall 5) and honors the "single-author stays clean" preference.
- **Annotation Optimization:** The decision to sort errors first in the annotation shim (09-05 T1) is a sophisticated handling of GitHub's annotation caps, ensuring the most critical blockers are never truncated.
- **Fixture Comprehensiveness:** 09-01 correctly identifies that git-based checks (`--strict`) require actual repo initialization (`git init`) in the test harness, which is handled via the `make_fixture_repo` helper.

## Concerns
- **Regex Backslash Escaping in Search (Plan 04, T3):** 
  - **Severity: MEDIUM**
  - In Plan 09-04, Task 3, Step 2, the Python snippet for `bin/search.sh` uses `r'contributor::s*@'` and `r'b'`. Since these are raw strings inside a bash heredoc, the backslashes for `\s` and `\b` appear to have been dropped in the plan text. 
  - *Impact:* The search will fail to match whitespace or word boundaries correctly, leading to false negatives in contributor filtering.
- **Missing PRIVACY.md in Leak Guard (Plan 04, T1):**
  - **Severity: LOW**
  - `PUBLIC_PATHS` in `bin/check-privacy.sh` includes `README.md` and `AGENTS.md` but omits `PRIVACY.md`. 
  - *Impact:* While unlikely to contain a leak, `PRIVACY.md` is a public-facing control-plane file and should be included for parity with `bin/check-neutrality.sh`.
- **Large PR Performance in Strict Mode (Plan 03, T1):**
  - **Severity: LOW**
  - The `DR-match` logic in `strict_check` scans *every* file in the wiki to build the `dr_covered` set and then scans every page for claims. While acceptable for the v1 target of 200 pages, this is an O(N^2) operation relative to vault size.
  - *Mitigation:* The plan correctly notes this is for v1 limits; no change needed now, but worth noting in the "Scaling Boundaries" section of AGENTS.md in a future phase.

## Suggestions
- **Fix Search Regex:** In `bin/search.sh` (09-04 T3), ensure the regexes are written as `r'contributor::\s*@'` and `r'\b'`.
- **Expand Privacy Scope:** Add `PRIVACY.md` to the `PUBLIC_PATHS` array in `bin/check-privacy.sh` (09-04 T1).
- **Sub-Agent Delegation:** Tasks in 09-02 and 09-03 modify `bin/lint.sh` heavily. These are excellent candidates for the `generalist` sub-agent to handle the high-volume code insertion and TDD loop while keeping the main history clean.
- **Git-Diff Ref Safety:** In `strict_new_pages` (09-03 T1), consider a fallback for `origin/main` if the user has renamed their primary remote. While `origin` is standard for GitHub Actions, using `$(git symbolic-ref refs/remotes/origin/HEAD)` (if it exists) can be more robust.

## Risk Assessment
**Overall Risk: LOW**

The phase is well-decoupled from upcoming brownfield work and builds on the proven CI patterns from Phase 7 and 8. The most complex logic (Strict DR-matching and Contributor mapping) is protected by explicit fixtures in Wave 0. Provided the regex syntax in `bin/search.sh` is corrected during implementation, the phase is positioned for a high-quality delivery.

| Succes Criteria | Plan Coverage | Status |
| :--- | :--- | :--- |
| 1. CI runs lint --ci --format json | 09-02, 09-05 | Covered |
| 2. --contributor writes to log.md | 09-04 | Covered |
| 3. Privacy-leak guard | 09-04, 09-05 | Covered |
| 4. --strict ratchet + escape hatch | 09-03, 09-05 | Covered |
| 5. CONTRIBUTING.md + CI docs | 09-06 | Covered |

---

## Codex Review

## 09-01 — Test Harness and Fixtures

**Summary**

09-01 is a solid Wave 0 foundation plan. It is concrete about the harness shape, keeps fixtures static rather than committing synthetic repos, and gives downstream plans a reusable test API. The plan does a good job reducing later ambiguity by defining exact fixture purposes and helper signatures. The main risk is that a few fixtures are too thin relative to how later tests actually use git history and baseline refs, so some downstream tests will still need to do significant scenario construction themselves.

**Strengths**

- Reuses the Phase 08 harness pattern verbatim, which reduces accidental novelty in test infrastructure.
- `lib.sh` API is explicit and sufficient for most later bash tests: `make_fixture_repo`, `setup_git_author`, `assert_exit_code`, `assert_json_has_finding`, `cleanup_fixture_repo`.
- The fixture set maps directly to Phase 9 validation needs instead of creating generic, under-specified test repos.
- The plan explicitly avoids committing `.git/` state inside fixtures, which is the right boundary.
- Acceptance criteria are concrete and automatable.

**Concerns**

- `MEDIUM` — 09-01 T2’s fixtures do not fully back all later diff-sensitive tests. In particular, 09-03 T1 relies on `origin/main...HEAD` semantics, but the fixture does not establish a canonical remote/base-ref pattern. Later tests reconstruct this ad hoc, which increases flakiness and duplication.
- `MEDIUM` — `make_fixture_repo()` seeds an initial commit for every fixture, including fixtures that intentionally contain malformed or incomplete wiki content. If later lint logic assumes presence of minimal repo scaffolding beyond seeded files, some tests may silently fail for the wrong reason.
- `LOW` — `setup_git_author()` uses `date > .ts`, which can collide if called twice within the same second on some systems or create noisy dependencies on shell locale/time formatting. It will probably work, but it is a fragile commit-mutator primitive.
- `LOW` — The plan says every seeded fixture must document “exact bytes” of files, but the actual task language does not enforce reproducibility details like newline endings or frontmatter delimiters consistently.

**Suggestions**

- Add one more helper in 09-01 T1 for git-history-sensitive tests, e.g. `seed_origin_main_ref <repo>`, so 09-03 strict tests do not each reinvent remote/base setup.
- Add a tiny canonical wiki skeleton fixture with `wiki/index.md` and `wiki/log.md` already present; several downstream tests currently reseed these manually.
- Make `setup_git_author()` write a unique file name based on email plus timestamp or counter rather than always `.ts`.
- Explicitly state that all seeded markdown files use LF endings and UTF-8 encoding; this matters for line-number assertions later.

**Risk Assessment**

`LOW-MEDIUM`. The plan is good and implementable, but some fixture scenarios are not quite rich enough for later git-diff and strict-mode tests, so downstream plans may compensate with local setup logic.

---

## 09-02 — Lint Flags, JSON, CI Mode, Version Pinning

**Summary**

09-02 is the most important infrastructure plan in the phase, and it is mostly well-designed. It cleanly separates primitives from later integrations, preserves existing local behavior, and uses the existing `add_finding()` tuple as the canonical JSON contract. The main issue is that the plan assumes a simpler `bin/lint.sh` internal shape than may actually exist, and a few details around `--skip-category`, `drift-external`, and JSON `line` support remain under-specified or potentially mismatched with the current implementation.

**Strengths**

- Strong separation of concerns: versioning first, then JSON/CI/skip behavior.
- D-01 through D-06 are translated into actionable code changes with good fidelity.
- Preserving non-`--ci` exit behavior is the right compatibility choice.
- The JSON contract is explicit and reuse-oriented, which directly supports CI annotations and future portability.
- Test coverage is well targeted at behavior rather than incidental implementation details.
- The plan resolves Open Question 6 about version comparison correctly by requiring tuple-based semver comparison.

**Concerns**

- `HIGH` — 09-02 T2 assumes `drift-external` is a category that can be skipped independently, but the plan text does not confirm whether the existing linter emits `drift-external` as its own category versus a subtype/message under `drift`. If the code does not already model it distinctly, `--ci` default skip will not work as specified.
- `HIGH` — The JSON emission design still treats findings as 4-tuples in the plan examples, while the required schema includes optional `line`. If some existing checks already know line numbers only inside message text, the plan does not specify whether to parse and normalize them or to omit `line` entirely. That leaves CI-05 partially underspecified.
- `MEDIUM` — 09-02 T1’s acceptance criterion “existing `bin/lint.sh --dry-run wiki/` output identical to pre-edit version” is good in spirit, but the plan does not define a mechanism to assert this. In practice it may become an untested assumption.
- `MEDIUM` — The plan adds `--skip-category` as colon-separated environment state, but does not address interaction with the existing `--category` inclusive filter. If both are passed, precedence is unclear.
- `MEDIUM` — The plan’s CI severity remap includes `drift` as warning and defaults to skipping `drift-external`, but it never specifies how mixed drift findings are represented if both external and internal drift share the same category.
- `LOW` — `test_lint_format_json.sh` checks that `lint-report.md` does not exist after a JSON run, but not that a preexisting report file’s mtime/content remains untouched.

**Suggestions**

- Before implementation, explicitly audit whether `bin/lint.sh` already distinguishes `drift-external` structurally. If not, add a clear subcategory model or adjust the decision to skip by predicate instead of by category name.
- Define precedence for `--category` and `--skip-category`. Recommended: apply `--category` first to narrow, then `--skip-category` to subtract.
- Decide now whether `line` will remain absent for most checks in Phase 9 or whether selected checks will be normalized to include it. Document that in the plan text so the annotation shim can rely on it.
- Add one regression test that pre-creates `wiki/maintenance/lint-report.md`, runs `--format json`, and verifies the file was neither rewritten nor deleted.
- Add one explicit test for invalid `--require-version` input like `foo` or `1.2`, unless semver validation is deliberately deferred.

**Risk Assessment**

`MEDIUM`. The architecture is right, but a few assumptions about current lint categories and line-number modeling could cause rework or spec drift during implementation.

---

## 09-03 — Strict Mode, Escape Hatch, Contributor Check

**Summary**

09-03 is the riskiest plan in the set. It addresses the right requirements and gives concrete regexes, git-diff logic, and tests, but it also carries the most hidden complexity. The strict-mode rules are defensible, yet the plan conflates “current wiki state” with “PR diff state” in a few places, and the contributor check leans on a trust model that is acceptable for warning-only lint but should be documented as weak. This plan will work if carefully implemented, but it needs tighter scoping around diff semantics and test setup.

**Strengths**

- The escape-hatch marker contract is very concrete and defensible.
- The decision-record matching rule correctly reuses `affected_pages` instead of inventing new schema.
- Separating `--strict` from primary `--ci` is a good design and aligns with D-11.
- The plan recognizes that source and decision pages are exempt from new-page provenance requirements.
- The contributor category is appropriately warning-level, not blocking.
- The tests cover both positive and negative cases, including adjacency and ID mismatch.

**Concerns**

- `HIGH` — 09-03 T1’s `collect_dr_affected_pages()` scans all `wiki/decisions/` pages in the working tree, not “decision pages in the PR diff” as D-08 states. That changes the semantics materially. A preexisting unrelated decision record could satisfy strict mode even when the current PR does not include it.
- `HIGH` — 09-03 T1’s DR-match check scans all wiki pages for inferred/tentative claims, not just new claims introduced by the PR. That is much stricter than the requirement and could fail old debt on unrelated PRs.
- `HIGH` — The new-page provenance test setup in `test_lint_strict_new_page.sh` is brittle. It rewrites local branches and remote refs manually and may not reliably produce `origin/main...HEAD` behavior across all environments. This should be abstracted or simplified.
- `MEDIUM` — `strict_new_pages()` hardcodes `origin/main`. The workflow uses `pull_request` and `push` contexts; on forks or unusual branch names this may be missing locally. CI may be okay with `fetch-depth: 0`, but local developer runs will be inconsistent unless fallback behavior is defined.
- `MEDIUM` — `count_skips_aggregate()` plus `strict_check()` can double-report the same marker in `--strict --count-skips` runs unless explicitly documented as intended.
- `MEDIUM` — The contributor check trusts `.git-author-map.txt` entirely. A contributor can map any email to any handle. That is acceptable for a warning-only consistency check, but it is not an identity proof and the plan should say that.
- `MEDIUM` — The single-author short-circuit in contributor lint can suppress real issues on repos with one historical author but incorrect `contributor::` fields added later. This is acceptable pragmatically, but it is a policy choice that deserves clearer documentation.
- `LOW` — The regex for contributor handles allows underscores and hyphens but not dots, while some ecosystems use dots in usernames. GitHub handles currently do not use dots, so this is probably fine.
- `LOW` — `if '/examples/' in dirpath` is not robust path filtering if run on Windows-like paths in other contexts, though CI target is Linux.

**Suggestions**

- Narrow D-08 enforcement to decision records added or modified in the PR diff, not all decisions in the repo. If that is too hard for v1.1, explicitly revise the decision text rather than silently broadening behavior.
- Narrow unmatched inferred/tentative checking to claims on changed files, ideally changed lines, or at minimum files in the PR diff. Current all-wiki scanning turns strict mode into a repository debt gate.
- Add a helper in 09-01 or 09-03 for setting up `origin/main` cleanly, rather than hand-building remote refs inside tests.
- Define fallback behavior for local `--strict` when `origin/main` does not exist. Recommended: warn and skip new-page diff checks locally, but keep claim/DR checks on changed files if determinable.
- Document the `.git-author-map.txt` trust model explicitly: it is a convenience mapping reviewed in git, not an authentication mechanism.
- Clarify whether `--count-skips` is additive to strict-mode skip-count findings or a separate reporting mode. Recommended: keep both, but document that combined use may emit both per-exempted-claim and per-marker inventory rows unless deduplicated.

**Risk Assessment**

`HIGH`. This plan touches the most nuanced policy logic, and there are real mismatches between locked decisions and proposed implementation scope. It is still salvageable, but it needs correction before execution.

---

## 09-04 — Privacy Guard, Ingest Contributor Resolution, Search Filter

**Summary**

09-04 is strong overall and matches the phase boundary well. Splitting privacy into its own script is the right architectural move, and the contributor/search work is appropriately pragmatic. The biggest issue is around `bin/ingest.sh`: the plan itself notices that the current script may only print instructions rather than directly edit `wiki/log.md`, but then proceeds as if the emission point is trivially adaptable. That ambiguity should be resolved up front because it affects both implementation shape and tests.

**Strengths**

- Correctly keeps privacy-leak logic out of `bin/lint.sh`.
- Full-tree, frontmatter-only scanning is the right fail-closed posture for CI-07.
- The `.git-author-map.txt` contract is simple and human-reviewable.
- Explicitly forbids bare-email fallback, which is an important privacy and schema safeguard.
- `bin/search.sh --contributor` accepting both `@handle` and bare handle resolves Open Question 5 well.
- Tests cover the main contributor resolution branches and privacy false-positive avoidance.

**Concerns**

- `HIGH` — 09-04 T2 has an unresolved implementation ambiguity around `bin/ingest.sh`. If the script does not actually write `wiki/log.md` and only prints templates/instructions, the plan must specify exactly where the `contributor::` line appears and how tests inspect that output. Right now it acknowledges the ambiguity but leaves the core behavior partly “planner verifies.”
- `MEDIUM` — 09-04 T1’s privacy scanner uses regex frontmatter extraction rather than PyYAML parsing. That is consistent with the decision, but malformed frontmatter in a public file could evade detection if the block parsing fails. For a privacy fail-closed guard, this should at least warn or fail on malformed frontmatter in scanned files.
- `MEDIUM` — `.git-author-map.txt` parsing accepts either two-space-arrow-two-space or tab separator, but the seed file and docs emphasize the arrow format. The looser parser is fine, though it slightly broadens the spec without documentation symmetry.
- `MEDIUM` — The contributor auto-detect logic keys off `git config user.email` from the current repo state. In CI or scripted environments this may be unset or inherited unexpectedly. The plan handles this with warnings, but tests should cover missing `user.email` explicitly.
- `LOW` — `test_check_privacy_clean.sh` assumes the real repo remains privacy-clean throughout the phase. That is a valid invariant check, but it can make the test suite sensitive to unrelated in-flight documentation edits.
- `LOW` — `bin/search.sh --contributor` splitting log entries on `^## \[` is reasonable, but the plan assumes `wiki/log.md` entry formatting remains stable. That is acceptable given AGENTS.md authority, though brittle if formatting drifts.

**Suggestions**

- Resolve the `bin/ingest.sh` ambiguity before execution. Recommended: explicitly state that the script will augment the printed log-entry template, not directly mutate `wiki/log.md`, if that matches current behavior.
- For `bin/check-privacy.sh`, consider failing closed on malformed frontmatter within public paths, or at least emitting a script-failure exit 1. A malformed public control-plane markdown file is itself a release-quality problem.
- Add one test for missing `git config user.email` in multi-author mode to ensure the warning path is sane.
- Add one test for `--format json` on `bin/check-privacy.sh`, since the script help exposes it and Plan 05 or future tooling may rely on it.
- In `bin/search.sh`, consider making `--contributor` incompatible with `--query` unless semantics are explicitly defined. Open Question 5 is only partially resolved by “planner’s call”; the plan should choose.

**Risk Assessment**

`MEDIUM`. The privacy portion is solid; the main implementation risk is around how `bin/ingest.sh` actually surfaces the contributor field and how much that depends on undocumented current behavior.

---

## 09-05 — CI Workflow, Annotation Shim, PR Template, AGENTS Amendments

**Summary**

09-05 is well structured and ties together the earlier plans into the user-visible CI experience. The workflow layout, annotation shim, PR template, and AGENTS documentation are mostly well designed. The main gap is that the plan introduces a new tracked file `.github/scripts/json-to-annotations.py` even though earlier context explicitly leaned toward an inline shim and no separate helper, and the workflow-failure semantics rely on `continue-on-error` plus reraising state in a way that is good but should be validated carefully.

**Strengths**

- Good integration plan that respects dependency ordering.
- `lint`, `privacy-leak`, and `strict` as independent jobs directly match the success criteria.
- The workflow header comment is a good operator affordance and matches prior project patterns.
- The annotation shim correctly maps `info` to `notice`, which resolves Open Question 2 appropriately.
- AGENTS.md amendments are concrete and align code behavior with canonical schema.
- CLAUDE.md sync check is correctly treated as a first-class acceptance criterion.
- The PR template is concise and operationally useful.

**Concerns**

- `MEDIUM` — The plan diverges from earlier context stating “no separate shim script” by creating `.github/scripts/json-to-annotations.py`. That is not inherently bad, but it is a planning inconsistency against the earlier guidance and should be justified explicitly.
- `MEDIUM` — The `lint` job uses `continue-on-error: true` and then a final “Fail on error-severity findings” step keyed to `steps.lint_run.outcome == 'failure'`. That works only if the lint step failure reliably corresponds to error findings and not script/runtime failure distinctions. The plan should state whether missing `/tmp/lint.json` on runtime failure still causes annotations step to behave acceptably.
- `MEDIUM` — The workflow does not explicitly upload `lint.json` as an artifact. Given GitHub annotation caps, the workflow logs may not be enough for large PRs. This is not required by scope, but it would improve debuggability.
- `LOW` — `pip install pyyaml` in the `privacy-leak` job may be unnecessary if the privacy script never imports PyYAML. It is consistent with the baseline pattern, so not a big issue.
- `LOW` — The PR template links to `../PRIVACY.md`; depending on GitHub template rendering context, relative links in PR templates can be awkward. This is usually acceptable but worth a quick manual check.
- `LOW` — The AGENTS section tests use text matching rather than structure-aware validation, so they may pass on shallow mentions rather than precise documentation.

**Suggestions**

- Either inline the annotation shim in the workflow as previously suggested, or add one sentence in the summary/docs explaining why a dedicated script was chosen instead: better testability and clearer cap handling.
- In the `lint` workflow, add a guard in the annotation step to fail cleanly if `/tmp/lint.json` is missing or invalid, with a deterministic stderr message.
- Consider uploading `/tmp/lint.json` as a workflow artifact when the lint step finds issues. That helps with the GitHub annotation cap and reviewer debugging.
- Add one acceptance criterion verifying no `needs:` edges exist between the three jobs, since parallel independence is a locked decision.
- In AGENTS.md CI-mode docs, explicitly mention that `drift-external` is skipped by default in CI so operators understand why local and CI runs differ.

**Risk Assessment**

`MEDIUM`. This plan will likely succeed, but there are a couple of integration wrinkles around the annotation shim choice and workflow failure-path clarity.

---

## 09-06 — CONTRIBUTING and CI Reference Docs

**Summary**

09-06 is a strong documentation close-out plan. It clearly separates contributor TL;DR guidance from deep CI reference material, and it aligns well with D-23, D-24, D-31, and D-32. The main risk is mild over-documentation: `docs/reference/ci.md` is very comprehensive, which is good, but it now becomes another place where behavior can drift if not kept close to the scripts and workflow.

**Strengths**

- Good split between `CONTRIBUTING.md` and `docs/reference/ci.md`.
- The content maps directly to the phase success criteria, especially the docs and merge-conflict requirements.
- The merge-conflict recipes are practical and actionable rather than abstract.
- The CI reference docs resolve the multi-provider requirement without taking ownership of cross-provider testing.
- The tests focus on presence of critical content and exclusions, which is appropriate for docs.
- The plan explicitly preserves the terse/mechanical tone and avoids scope creep into governance material.

**Concerns**

- `MEDIUM` — `docs/reference/ci.md` becomes a second detailed specification layer alongside AGENTS.md and the actual scripts. There is some drift risk unless wording is kept tightly aligned with implementation and tests.
- `MEDIUM` — The GitLab snippet includes `apt-get install -y git bash`, which is plausible but may not be sufficient in all slim images depending on package state. Since CI-09 is docs-only, this is acceptable, but the snippet should be framed clearly as illustrative, not guaranteed.
- `LOW` — `CONTRIBUTING.md` recommends merge commits over squash for ingest PRs. That is sensible, but it is a policy suggestion not enforced anywhere; this should be labeled as recommendation, not implied requirement.
- `LOW` — The docs tests only ensure excluded providers are not top-level sections. Mentions in out-of-scope lists are fine, but this leaves some wiggle room for accidental extra depth later.
- `LOW` — The merge-conflict resolution commands are narrative rather than exact reproducible sequences. That is probably the right level for docs, but some users may still need more explicit examples.

**Suggestions**

- Add a short “last updated by Phase 9” note or at least keep tests anchored to specific behavior so drift becomes visible when scripts change.
- In `docs/reference/ci.md`, label GitLab/Gitea/Codeberg snippets as “starting points” rather than turnkey support.
- In `CONTRIBUTING.md`, phrase merge-commit guidance as “recommended for ingest PRs” to avoid implying repository enforcement.
- Add one test ensuring `docs/reference/ci.md` mentions the annotation cap and artifact/log fallback for dropped findings, since that was an identified open question.
- Consider a final doc cross-link from `CONTRIBUTING.md` to `.github/pull_request_template.md` only if it improves discoverability.

**Risk Assessment**

`LOW-MEDIUM`. The docs plan is strong and likely to land cleanly. The main risk is maintenance drift rather than implementation failure.

---

## Cross-Plan Assessment

**Summary**

As a whole, the plan set is high quality: it is concrete, requirement-traceable, and mostly well sequenced. 09-01 through 09-06 cover the five roadmap success criteria with little obvious scope creep. The main weakness is 09-03, where strict-mode implementation broadens the intended requirement from “PR-added debt” into “current wiki debt” in a few places. The second main weakness is that 09-04 and 09-05 carry some unresolved integration assumptions around `bin/ingest.sh` output shape and annotation workflow failure paths.

**Strengths**

- Wave sequencing is sensible: fixtures first, primitives next, integration after.
- File modification overlap is mostly controlled. The only high-contention file is `bin/lint.sh`, and plans touching it are correctly serialized.
- Deferred items generally stay deferred; the plans do not obviously smuggle in `.lint-state.json`, merge-base comparison, or post-merge auto-fix PRs.
- Security/privacy posture is appropriately conservative, especially the public-path privacy guard.
- The plans are unusually concrete for shell-heavy work: exact regexes, flag names, command lines, and expected output shapes are all specified.
- The six open questions from research are mostly resolved:
  - Q1 `fetch-depth: 0`: resolved in 09-05 strict job with justified scope.
  - Q2 annotation cap: resolved in 09-05 with sorting and trailing notice.
  - Q3 AGENTS schema version: correctly deferred; lint version only.
  - Q4 email case sensitivity: effectively resolved by lowercasing in 09-04.
  - Q5 `search.sh --contributor` interaction: only partially resolved; still needs explicit choice.
  - Q6 deleted/re-added/new-page detection: partially resolved by “status A only,” but renames/copies remain implicit.
- Fixture coverage is good overall and each Wave 1+ area has backing fixtures, though some git-history-sensitive tests still do extra setup.

**Concerns**

- `HIGH` — 09-03 T1 does not currently honor the locked decision boundary around PR-diff-specific strictness and DR matching. This is the most important issue in the review.
- `MEDIUM` — 09-04 T2 still leaves the `bin/ingest.sh` integration point partly open-ended. That should be decided before coding.
- `MEDIUM` — 09-02/09-03 assume a lint internal model for categories and line numbers that may not match the actual script structure.
- `MEDIUM` — There is some spec duplication risk across AGENTS.md, docs/reference/ci.md, and the workflow/test expectations.
- `LOW` — Performance is acceptable overall. `fetch-depth: 0` only on the strict job is a reasonable tradeoff. JSON parsing overhead is negligible for this repo. The largest operational risk is large PRs hitting GitHub annotation caps, which 09-05 addresses.

**Suggestions**

- Fix 09-03 before execution:
  - Restrict DR matching to relevant changed files or explicitly redefine the locked decision if broader behavior is desired.
  - Restrict inferred/tentative claim checks to changed pages, not the entire wiki.
  - Add a canonical helper for `origin/main` setup.
- Tighten 09-04 T2 by explicitly declaring whether `bin/ingest.sh` augments a printed template or writes the log directly.
- Tighten 09-02 around category modeling:
  - confirm whether `drift-external` is a real skip target,
  - define `--category` plus `--skip-category` precedence,
  - clarify optional `line` population policy.
- In 09-05, either keep the standalone annotation shim and justify it, or revert to an inline workflow step to match prior design guidance.
- Add one final phase-level test or checklist item confirming all five roadmap success criteria are actually covered end-to-end, not just via unit tests.

**Risk Assessment**

`MEDIUM`.

The plans are strong enough to execute, but not yet low-risk. If 09-03’s strict-mode scope mismatch is corrected and 09-04’s ingest integration ambiguity is resolved, overall risk drops substantially. As written, the likely failure mode is not “can’t implement,” but “implements a subtly wrong gate that blocks unrelated PRs or behaves inconsistently locally versus CI.”

---

## Consensus Summary

Phase 9 plans received reviews from Gemini (concise, overall LOW risk) and Codex (detailed per-plan breakdown, overall MEDIUM risk). Both reviewers confirmed requirement coverage and structural soundness; Codex surfaced one HIGH-severity scope concern (`--strict` applying to the whole wiki vs. PR-diff only) that Gemini did not flag, and Gemini caught a plan-text transcription issue (missing backslash escapes in `bin/search.sh` regex) that Codex did not call out. The divergence in overall risk rating (LOW vs MEDIUM) reflects whether the reviewers treat the `--strict` scope question as a locked-decision violation or as an implementation refinement.

### Agreed Strengths

- **Concreteness of action text** — both reviewers praised the level of detail (exact regexes, flag names, dispatch-table contents, command lines, fixture bytes) relative to typical shell-heavy plans.
- **Wave sequencing** — Wave 0 fixtures first, primitives next, integration last is sensible and correctly serializes `bin/lint.sh` modifications across 09-02 → 09-03.
- **Attribution/privacy posture** — three-job CI layout, `contributor::` as body-only Dataview field (not frontmatter), bare-email leak prevention, and public-path privacy guard are all judged conservative-enough.
- **Annotation cap handling** — sorting errors first with a trailing "N more" note in the GitHub Actions shim (09-05 T1) was called out positively by both.
- **Open-question resolution** — research's 6 open questions are mostly settled in plan text; only Q5 (search.sh --contributor filter interaction) and Q6 (rename/copy handling) remain partially open per Codex.

### Agreed Concerns

(Concerns raised or corroborated by both reviewers, ordered by severity)

| Severity | Area | Plan(s) | Summary |
|----------|------|---------|---------|
| **HIGH** (Codex) / **not flagged** (Gemini) | `--strict` scope | 09-03 T1 | Codex argues DR-match and new-page provenance checks should operate on PR-diff (`A` status files only), not the entire wiki, per the locked CI-06 decision. If enforced wiki-wide, existing legacy debt would block unrelated PRs. Gemini did not flag this but noted large-PR performance (related concern). |
| **MEDIUM** | `bin/ingest.sh` integration | 09-04 T2 | Codex: unclear whether `--contributor` augments a printed template or writes log.md directly. Needs explicit decision before coding. Gemini did not flag. |
| **MEDIUM** | Category modeling in lint | 09-02 | Codex: `--category` vs `--skip-category` precedence undefined; `drift-external` as skip target unverified; optional `line` population policy unclear. |
| **MEDIUM** | Spec duplication risk | 09-05 / 09-06 | Codex: severity policy, JSON schema, and provider equivalents could drift across AGENTS.md, `docs/reference/ci.md`, and workflow file. No single source of truth designated. |
| **MEDIUM** (Gemini) | Search regex escape | 09-04 T3 | Gemini: Python raw-string regexes in bash heredoc appear to have lost `\s` and `\b` backslashes in plan text (`r'contributor::s*@'`, `r'b'`). Would produce silent false negatives. |
| **LOW** | Origin ref robustness | 09-03 T1 | Gemini: fallback to `$(git symbolic-ref refs/remotes/origin/HEAD)` when `origin/main` isn't the canonical base. Codex: also noted lack of canonical `origin/main` setup helper in fixtures. |
| **LOW** | `PRIVACY.md` in PUBLIC_PATHS | 09-04 T1 | Gemini: `PRIVACY.md` missing from public-path privacy guard; parity with `bin/check-neutrality.sh` warrants inclusion. |
| **LOW** | O(N²) strict-mode scan | 09-03 T1 | Gemini: entire-wiki scan acceptable for v1 (≤200 pages) but worth noting in Scaling Boundaries. |
| **LOW** | `setup_git_author()` timestamp file | 09-01 T1 | Codex: `date > .ts` collision-prone; unique filename per author preferred. |
| **LOW** | Newline/encoding discipline | 09-01 T2 | Codex: fixtures should state LF + UTF-8 explicitly for line-number-sensitive assertions. |

### Divergent Views

| Topic | Gemini | Codex | Worth investigating |
|-------|--------|-------|---------------------|
| Overall risk | LOW | MEDIUM | Hinges on whether `--strict` scope concern (09-03 T1) is a locked-decision violation or a clarification. **YES** — needs user call. |
| `--strict` wiki-wide scan | Performance concern only | Scope boundary violation | Codex's reading is stricter; review against 09-CONTEXT.md D-08/D-10 locked decisions. |
| Search regex escape issue | HIGH-impact finding | Not flagged | Verify by reading 09-04 T3 action text directly; if backslashes are present but Gemini lost them in rendering, this is a false positive. |
| Sub-agent delegation suggestion | Suggested for 09-02/03 | Not suggested | Optional execution-strategy note. |

### Recommended Next Steps

1. **Inspect 09-04 T3** to confirm whether regex backslashes are present in plan text. If missing, fix before execution (one-line action-text edit).
2. **Decide on `--strict` scope** — PR-diff only (Codex's reading) vs. wiki-wide (current plan). Cross-reference CONTEXT.md D-08/D-10. If PR-diff only, amend 09-03 T1 accordingly.
3. **Clarify `bin/ingest.sh --contributor` integration point** — does it write to log.md or augment a stdout template? Amend 09-04 T2.
4. **Define category-flag precedence** in 09-02 plan text (`--category X --skip-category Y` interaction).
5. **Designate single source of truth** for severity policy + JSON schema — likely AGENTS.md §11.3 with `docs/reference/ci.md` and workflow file linking to it.
6. Optionally: add `PRIVACY.md` to PUBLIC_PATHS in 09-04 T1; harden `origin/main` detection in 09-03 T1; tighten fixture newline discipline in 09-01 T2.

Feed this back via `/gsd:plan-phase 9 --reviews` to have the planner generate targeted revisions.
