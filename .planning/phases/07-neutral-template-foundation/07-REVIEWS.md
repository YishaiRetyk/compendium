---
phase: 7
reviewers: [gemini, codex]
reviewed_at: 2026-04-15
plans_reviewed:
  - 07-01-PLAN.md
  - 07-02-PLAN.md
  - 07-03-PLAN.md
  - 07-04-PLAN.md
  - 07-05-PLAN.md
---

# Cross-AI Plan Review — Phase 7

## Gemini Review

# Phase 7: Neutral Template Foundation — Plan Review

## Summary
The proposed five-plan sequence for Phase 7 is a comprehensive and technically sound roadmap for transitioning the LLM Wiki Compiler from a personal MVP to a shareable GitHub template. The plans prioritize security (C-1 creator-content leakage) through a tiered defense strategy: mechanical neutralization of `AGENTS.md`, a human-reviewed denylist, a dedicated neutrality CI gate, and a "Gold Standard" orphan-branch release workflow using detached worktrees. The early implementation of `requirements-sync.sh` ensures that the increased complexity of the v1.1 milestone is met with strict traceability from the outset.

## Strengths
- **Defense in Depth:** Combines pre-commit hooks, CI gates, and a standalone neutrality scanner (`check-neutrality.sh`) to prevent accidental leakage of Kahneman or personal data.
- **Orphan-Branch Release Hygiene:** Utilizing `git worktree` followed by `git init` in `release.sh` is significantly safer than in-place orphan checkouts, effectively isolating the public release from the private `.git` history.
- **Traceability first:** Placing `07-01-PLAN.md` (Requirements Sync) as the very first wave ensures that every subsequent requirement in Phase 7 is mechanically verified against its verification truth.
- **Obsidian-Native Considerations:** The inclusion of `.obsidianignore` to hide the `examples/` cluster from the graph view addresses a critical UX pitfall identified in research.
- **Idiomatic Tooling:** All scripts follow the established bash-with-python-heredoc pattern, maintaining the "zero new runtime dependencies" goal while leveraging Python's superior parsing capabilities for YAML and Markdown.

## Concerns
- **Manual Neutralization Accuracy (MEDIUM):** `07-03-PLAN.md` relies on a manual inventory and replacement of 13+ tokens in `AGENTS.md`. While a verification grep is included, a single typo or case variant missed could violate the neutrality requirement.
- **Log Entry Pollution (LOW):** When moving Kahneman entries to `examples/kahneman/log.md`, there is a risk that personal-domain entries (e.g., about the creator's personal journal) remain in the moved log. The plan mentions "extracting any Kahneman ingest entries," but the procedure should be explicitly filtered to ensure only Kahneman-domain entries migrate.
- **Denylist Source Fallback (LOW):** Task 2 in `07-05-PLAN.md` correctly identifies that after Plan 02 deletes `local_only` files, the suggest-mode scanner has no targets. The fallback to scanning git history and `.planning/notes` is clever and necessary.

## Suggestions
- **Automated Neutralization Verification:** In `07-03-PLAN.md`, Task 1, step 7 (Grep Verification), add a step to run the *actual* `bin/check-neutrality.sh` (even if it's not yet fully implemented, the logic can be prototyped or the test can be moved to after plan 05) to ensure the neutralization survives the real gate.
- **Worktree Cleanup Trap:** Ensure `bin/release.sh` uses a `trap` for the worktree cleanup to handle `Ctrl+C` or mid-script failures, preventing `/tmp` bloat and stale worktree references. (Note: The plan already includes a `trap`, which is good).
- **Log Extraction Scripting:** For `07-02-PLAN.md`, Task 1.6, provide a simple one-liner (e.g., `grep -A 5 "ingest | .*Kahneman"` or similar) to make the log migration deterministic rather than a manual cut-paste.

## Risk Assessment: LOW
The overall risk is low because the plans are heavily gated. The "fail-closed" nature of the neutrality gate and the dry-run-by-default posture of the release script provide multiple safety nets before any data reaches a public remote. The dependency ordering is logical: requirements-sync (infrastructure) -> relocation (content) -> neutralization (schema) -> scaffolding (docs) -> gates (enforcement).

- **Justification:** The primary hazard (data leak) is mitigated by the orphan-branch workflow which creates a fresh history, meaning even if a string leaks in the final commit, the *entire history* of the private vault remains unreachable. The human checkpoint in `07-05` further reduces the probability of a "silent" leak.

---

## Codex Review

## 07-01-PLAN.md

**Summary**
This plan is a solid Wave 0 foundation. It scopes one mechanical utility (`bin/requirements-sync.sh`) plus a reusable Phase 7 test harness, and it defines concrete fixture-driven behavior for advisory vs strict modes, JSON output, and phase filtering. It is appropriately isolated from the rest of Phase 7 and gives later plans a shared verification entrypoint.

**Strengths**
- Clear single responsibility: DEBT-03 plus test harness bootstrap.
- Good TDD shape: RED fixture phase before GREEN implementation.
- `--root` support is a strong design choice for fixture-based testing and future reuse.
- Advisory vs strict behavior matches the milestone decision record.
- Output contract is explicit and testable.
- Dependency ordering is correct: later plans can rely on `tests/phase-07/run.sh`.

**Concerns**
- `MEDIUM`: The plan assumes VERIFICATION files use a simple `- REQ-ID: Status` syntax, but the surrounding docs mention multiple possible truth formats. Parser fragility could cause false drift or missed drift.
- `MEDIUM`: `find "$ROOT" -maxdepth 3 -name '*VERIFICATION.md'` may miss deeper future phase layouts or accidentally include unrelated verification files if the structure changes.
- `LOW`: The acceptance criteria use shell patterns like `head -1 | grep -qi 'advisory'`, which are slightly brittle if formatting changes without semantic breakage.
- `LOW`: The plan does not define behavior for duplicate REQ-IDs across multiple VERIFICATION files.

**Suggestions**
- Make the parser explicitly tolerate both `- REQ-ID: Pending` and any existing checkbox or emoji variants, even if only Phase 7 fixtures use the simple form.
- Define precedence if multiple VERIFICATION files mention the same REQ-ID.
- Have JSON output include `phase` as an optional field; that will make CI/debugging easier later.
- Consider making the root scan recursive without hardcoded depth, or at least document the expected directory contract.

**Risk Assessment**
**LOW** — It is well-bounded and unlikely to derail the phase, though parser assumptions should be tightened to avoid noisy drift output later.

---

## 07-02-PLAN.md

**Summary**
This is the most structurally important plan in the phase. It moves the Kahneman cluster into `examples/kahneman/`, deletes clearly disallowed `local_only` creator content, shrinks `wiki/` to a starter skeleton, adds the NEUT-07 decision record, and updates lint exclusion semantics. The sequence is mostly correct and aligns with the milestone goal of producing a neutral starter repo.

**Strengths**
- Correctly identifies relocation before neutralization as the right dependency order.
- Explicitly separates preserved example content from deleted creator-private content.
- Uses `git mv`, which preserves history locally and keeps the move auditable before orphan release.
- Includes a concrete decision record requirement, which is important for future maintainers.
- Lint exclusion work is paired with fixtures and tests rather than treated as incidental.
- The plan directly advances the core phase goal: empty default wiki, examples preserved elsewhere.

**Concerns**
- `HIGH`: The decision record schema in the plan does not match the authoritative `AGENTS.md` decision-record schema shown earlier. The plan uses fields like `date` and `class: SUPERSEDE` instead of the documented base fields (`id`, `type`, `status`, `summary`, `created_at`, `updated_at`, `epistemic_status`, etc.). That is a schema-compliance risk.
- `HIGH`: The plan states "wiki/ contains only index.md + log.md skeletons and decisions/" but also keeps `wiki/maintenance/lint-report.md`; that conflicts with TMPL-05 and its own success criteria.
- `MEDIUM`: The in-cluster wikilink verification only checks slugs inside `examples/kahneman/`; it does not check links from public control-plane files that may still point into old `wiki/...` paths.
- `MEDIUM`: The test that greps `wiki/` for Kahneman strings may fail on the decision record itself if it lives under `wiki/decisions/` and necessarily names the move target.
- `MEDIUM`: The skeleton frontmatter for `wiki/index.md` and `wiki/log.md` appears underspecified relative to the repo's strict page schema. `type: log` may not even be a valid type if the schema only allows the listed types.
- `LOW`: Replacing `wiki/maintenance/lint-report.md` with a stub risks carrying stale maintenance artifacts into the public template when deleting it may be cleaner.

**Suggestions**
- Rewrite the NEUT-07 decision record to fully conform to the documented `type: decision` schema, including `id`, `status`, `summary`, `created_at`, `updated_at`, `epistemic_status`, `tags`, `domains`, and the required section ordering.
- Decide definitively whether `wiki/maintenance/` ships at all. If TMPL-05 says skeleton-only, remove it.
- Add a repo-wide scan for stale `wiki/...kahneman...` path references after the move, not just in-cluster slug checks.
- Clarify whether `wiki/log.md` is exempt from the normal page-type enum or whether it should follow a documented non-page artifact schema.
- Ensure tests exclude `wiki/decisions/` from the "no Kahneman strings under wiki/" assertion, or better, assert no Kahneman content remains under `wiki/entities|concepts|comparisons|overviews|sources`.

**Risk Assessment**
**MEDIUM-HIGH** — This plan is essential and mostly well-aimed, but there is real risk of schema drift and self-contradictory acceptance criteria if not corrected.

---

## 07-03-PLAN.md

**Summary**
This plan tackles the highest-visibility neutralization work: removing Kahneman-specific inline examples from `AGENTS.md`, creating a template source for the Phase 8 wizard, and enforcing byte-identical `CLAUDE.md` parity. The intent is right, but the plan mixes true wizard placeholders with readability placeholders in a way that risks overcomplication and accidental divergence from the "exactly four placeholders" decision.

**Strengths**
- Correctly depends on relocation first.
- Explicitly enforces the AGENTS/CLAUDE parity invariant with local and CI guardrails.
- The sync script is simple, deterministic, and easy to recover from.
- The plan updates `AGENTS.md` to reflect new top-level directories and `example: true`, which is necessary schema maintenance.
- Good choice to ship hook installer plus hook path, not just prose instructions.

**Concerns**
- `HIGH`: The plan introduces many literal placeholder tokens like `{{ENTITY_NAME_PLACEHOLDER}}`, `{{CONCEPT_NAME_PLACEHOLDER}}`, etc. That may violate or at least muddy D-08's "exactly four placeholders" decision. Even if they are called "readability aids," they are syntactically indistinguishable from wizard placeholders.
- `HIGH`: The acceptance criteria say the template must have "exactly 4 wizard placeholders," but the plan also allows many more `{{...}}` strings in the file. That will create confusion for the eventual renderer.
- `MEDIUM`: The grep-based neutralization inventory is risky for a long schema file. It may miss semantically equivalent references or accidentally replace strings inside normative examples where preserving literal schema terms matters.
- `MEDIUM`: The plan says to substitute `{{AGENT_FILENAME}}` only in "natural occurrences" and add a sentence if none exists. That feels under-specified and could create awkward template output.
- `LOW`: The pre-commit hook exits after auto-syncing and re-staging, which is safe, but the user experience should be documented because it forces a second commit attempt.

**Suggestions**
- Use a distinct syntax for non-rendered illustrative tokens, such as `<CONCEPT_NAME>` or `example-concept-name`, to avoid colliding with the wizard's true `{{...}}` placeholder language.
- Add a test that asserts the only double-curly placeholders in `schema/AGENTS.template.md` are the four approved wizard placeholders.
- Replace broad grep replacement steps with a section-by-section review list to reduce accidental edits.
- Add a test that `CLAUDE.md` remains byte-identical after running the hook path, not just after manual sync.
- Clarify whether `AGENTS.md` itself should remain fully concrete and neutral, with only the template carrying wizard placeholders.

**Risk Assessment**
**MEDIUM** — Strong intent and useful tooling, but placeholder semantics need tightening or Phase 8 will inherit ambiguity.

---

## 07-04-PLAN.md

**Summary**
This plan covers the stranger-facing surface area: README, license, privacy explainer, ignore files, docs skeleton, and the release runbook. It is generally well-scoped and aligned with the phase goal, with good separation between Phase 7-owned docs and later stubbed tracks. The main issue is a small amount of scope leakage and some content choices that may overstate implementation that does not yet exist.

**Strengths**
- Good separation between "real now" docs and later stub docs.
- README structure is concrete and appropriate for the target audience.
- `<org>/<repo>` placeholder discipline is explicit.
- `PRIVACY.md` is short and user-facing rather than duplicating schema internals.
- `.gitignore` and `.gitattributes` are pragmatic and low-risk.
- `docs/reference/release.md` gives a real maintainer workflow, which is necessary for TMPL-11.

**Concerns**
- `MEDIUM`: Shipping `.obsidianignore` is reasonable, but it is still an unresolved behavior assumption in the research. That makes it a product decision sneaking in without validation.
- `MEDIUM`: README says python3 "with PyYAML — stdlib-sufficient on most distros," which is inaccurate: PyYAML is not stdlib. That will confuse users.
- `MEDIUM`: `PRIVACY.md` says CI gates are "shipped starting in Phase 9," but Phase 7 plan 05 already ships a neutrality workflow. The wording is likely to go stale immediately.
- `LOW`: The release runbook lists `.github/workflows/neutrality.yml` as part of the public file set before plan 05 creates it; acceptable as forward reference, but sequencing should be explicit.
- `LOW`: The docs plan creates stubs for guided/manual setup although the phase boundary says those are Phase 8. This is acceptable, but they should remain unmistakably skeletal to avoid accidental scope creep.

**Suggestions**
- Fix the README prerequisite wording to distinguish `python3` from `PyYAML`, or just say Phase 7 requires `python3` and Phase 10/11 brownfield uses `ruamel.yaml`.
- In `PRIVACY.md`, say CI enforcement is "described here and expanded across later phases," rather than pinning it to Phase 9.
- Treat `.obsidianignore` as conditional: either ship it with a clear comment that it is a starter default, or move it to a documented optional file if the team wants stricter minimalism.
- Add a test ensuring no Kahneman terms appear in README/PRIVACY/docs except where explicitly allowed.

**Risk Assessment**
**LOW-MEDIUM** — Mostly straightforward scaffolding. Main risks are documentation drift and small inaccuracies, not architectural failure.

---

## 07-05-PLAN.md

**Summary**
This plan is the decisive safety gate for the entire phase: neutrality enforcement, human-reviewed denylist, release tooling, and CI. It addresses the right risks, especially creator-content leakage and public git-history leakage, and correctly includes blocking human checkpoints. It is also the most security-sensitive plan, and a few implementation details need tightening to avoid either false assurance or accidental destructive behavior.

**Strengths**
- Correctly identifies creator-content leakage as the dominant phase risk.
- Human review checkpoint for the denylist is the right call; it should not be automated away.
- `check-neutrality.sh` excludes `examples/`, matching the intended example-preservation model.
- `release.sh` is dry-run by default and requires explicit confirmation.
- CI gating includes both neutrality and AGENTS/CLAUDE drift.
- The plan explicitly tests leak-positive and clean cases, not just happy path.
- The final human checkpoint includes a throwaway remote smoke test, which is exactly the right validation for TMPL-11.

**Concerns**
- `HIGH`: `bin/release.sh` as written is dangerous/incomplete. After `git worktree add --detach "$WORKTREE" HEAD`, the worktree shares the original repository's tracked files. Running `rm -rf .git && git init` inside that checkout does not automatically sanitize history exposure or file selection the way the plan implies. It needs a more carefully defined staging strategy.
- `HIGH`: The release script does not clearly prevent accidental push to a real target during tests, and the plan's automated tests wisely skip full apply. That means the most critical behavior remains only manually validated.
- `HIGH`: `check-neutrality.sh` scans current working tree content, but it does not validate that old sensitive history is unreachable. Only orphan publish mechanics handle that, so release script correctness is existential.
- `MEDIUM`: The candidate denylist generation after local-only files were deleted is awkward. Falling back to git history or `.planning/notes` is reasonable, but the plan does not define a deterministic algorithm there.
- `MEDIUM`: `grep -rIinF` with a hand-maintained denylist may produce noisy false positives on common substrings unless phrase quality is tightly curated.
- `MEDIUM`: Workflow triggers on `push` to `main` as well as PR. That is fine, but it means a broken main can happen before the gate if branch protections are not separately configured.
- `LOW`: The release script hardcodes `user.email="release@<org>"`, which may produce odd commit metadata or invalid email format depending on user expectations.

**Suggestions**
- Rework `bin/release.sh` to stage into a fresh temp directory outside the repo, copy only the explicit allowlisted public file set, then `git init` there. That is safer and simpler than trying to mutate a detached worktree in place.
- Add an allowlist-based copy step for release rather than relying on `.gitignore` plus deletions. For this phase, allowlist is safer than denylist.
- Add an automated test that inspects the dry-run's printed public file set and verifies `.planning/`, `.brownfield/`, and non-public wiki directories are absent.
- Make `check-neutrality.sh --suggest-denylist` deterministic and document its sources explicitly; if git history is used, define exactly which paths and extraction rules are allowed.
- In CI, keep `pull_request` as the meaningful gate and treat `push` as extra monitoring, but note that branch protection is required for real enforcement.
- Add a manual verification step that checks the published repo contains exactly one commit and that `git rev-list --all --count` equals `1`.

**Risk Assessment**
**HIGH** — This plan addresses the right threat model, but its release mechanics are the single biggest place the phase can fail. If `release.sh` is not implemented with an explicit allowlist and truly fresh repo initialization, creator-content leakage via history or file carryover remains possible.

---

## Codex Overall Assessment

**Summary**
The Phase 7 plan set is directionally strong and mostly well-sequenced: foundation test harness first, content relocation second, schema neutralization third, public scaffolding fourth, and enforcement/release last. That ordering fits the phase goal. The biggest systemic risk is not missing functionality but false confidence around neutrality and clean release history. Plans 02, 03, and especially 05 need tightening around schema conformance, placeholder semantics, and release staging.

**Concerns (overall)**
- `HIGH`: Release publication mechanics are not yet safe enough to trust without redesign toward an explicit allowlist + fresh temp repo.
- `HIGH`: The NEUT-07 decision record plan appears to drift from the canonical schema in `AGENTS.md`.
- `MEDIUM`: Placeholder semantics in 07-03 are underspecified and may undermine the future wizard.
- `MEDIUM`: Some acceptance criteria conflict with each other, especially around `wiki/maintenance/` and residual Kahneman strings under `wiki/decisions/`.
- `LOW`: A few docs claims will go stale immediately unless tightened.

**Suggestions (overall)**
- Before implementation, revise 07-02 to make the decision record schema strictly compliant.
- Before implementation, revise 07-03 so only the four approved wizard placeholders use `{{...}}`; use another syntax for illustrative tokens.
- Before implementation, revise 07-05 to use fresh-directory allowlist release staging instead of worktree mutation.
- Add one explicit phase-level invariant test: public control-plane paths contain zero Kahneman/personal terms, and public release allowlist contains only the intended file set.
- Add one explicit post-release smoke criterion: cloned public repo has exactly one commit and no reachable prior refs/tags.

**Risk Assessment**
**MEDIUM-HIGH** — The plan set is good enough to execute after a focused revision pass. Without that pass, the likely failure mode is not missing docs or scripts; it is shipping a "neutral" template that still leaks creator structure, strings, or history.

---

## Consensus Summary

### Agreed Strengths (mentioned by both reviewers)
- **Defense-in-depth neutrality posture** — pre-commit hook, CI gate, and `check-neutrality.sh` together, plus dry-run-by-default `release.sh` and human checkpoints.
- **Correct dependency ordering** — traceability/test harness first (07-01), content relocation second (07-02), schema neutralization (07-03), public scaffolding (07-04), enforcement last (07-05).
- **Example preservation model** — `examples/kahneman/` with `EXCLUDE_DIRS` and `example: true` is sound; creator-private content is deleted rather than exposed.
- **Human checkpoints inserted at the right places** — denylist review and final live-template smoke test are correctly not automated.
- **Creator-content leakage (C-1) is identified as the dominant risk** and addressed by multiple independent gates.

### Agreed Concerns (raised by both — highest priority to address)
1. **Neutralization inventory fragility in 07-03 (HIGH/MEDIUM).** Both reviewers flag that manual/grep-based replacement of 13+ Kahneman tokens in `AGENTS.md` risks missed case variants or accidental edits inside normative schema examples. Gemini suggests running `check-neutrality.sh` against `AGENTS.md` before phase close; Codex adds a test asserting only the four wizard placeholders use `{{...}}`.
2. **Release-script confidence gap (implicit in Gemini, HIGH in Codex).** Gemini treats orphan-branch release as the primary mitigation of C-1; Codex argues the current worktree + `rm -rf .git && git init` mutation is unsafe and should be replaced by a fresh-temp-dir allowlist copy. The consensus is that release staging **must be allowlist-based**, not denylist-based, for the phase goal to hold.
3. **Automated vs manual verification of the release mechanism.** Both note that the release script's most critical behavior (clean history, allowlisted file set) is only manually validated. The dry-run test should assert the printed file set explicitly excludes `.planning/`, `.brownfield/`, and non-public wiki directories, and the manual checkpoint should assert `git rev-list --all --count == 1`.

### Divergent Views
- **Overall risk rating.** Gemini: LOW (trusts the layered gates). Codex: MEDIUM-HIGH (trusts intent, distrusts release-script details). The divergence tracks whether you believe the current `release.sh` implementation as sketched in 07-05 is sufficient — if it is reworked toward an allowlist/fresh-temp-dir model, Codex's concern collapses to Gemini's.
- **Placeholder semantics (07-03).** Only Codex flags this; Gemini does not mention it. Codex's point is substantive: illustrative `{{...}}` tokens are syntactically indistinguishable from wizard `{{...}}` placeholders and will confuse Phase 8's renderer. Recommend addressing even though unanimous consensus is absent.
- **Decision-record schema (07-02).** Only Codex flags NEUT-07 schema drift (HIGH). Worth cross-checking against `AGENTS.md` decision-record schema before 07-02 executes.

### Recommended Next Actions
- **Option A — Replan with reviews:** `/gsd:plan-phase 7 --reviews` to incorporate the HIGH-severity feedback into 07-02 (decision-record schema), 07-03 (placeholder semantics), and 07-05 (release staging model).
- **Option B — Execute with targeted spot-fixes:** Proceed to `/gsd:execute-phase 7` but require the executor to honor these deviations at the task level:
  - 07-02: conform NEUT-07 frontmatter to `type: decision` schema in `AGENTS.md`; decide `wiki/maintenance/` fate (delete or keep, documented).
  - 07-03: restrict `{{...}}` tokens in `schema/AGENTS.template.md` to the four approved wizard placeholders; use `<PLACEHOLDER>` or plain text elsewhere.
  - 07-05: rework `bin/release.sh` to stage into a fresh temp directory via allowlist copy, then `git init`; add dry-run test asserting forbidden paths absent; manual checkpoint asserts `git rev-list --all --count == 1`.

Option A is the safer route given the HIGH-severity findings touch the phase's core risk (creator-content leakage).
