---
phase: 14
reviewers: [gemini, codex]
reviewed_at: 2026-06-02T17:08:19Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md]
cycle: 2
---

# Cross-AI Plan Review — Phase 14 (Cycle 2, re-review)

> Re-review after the Cycle-1 replan. Two independent external reviewers (Gemini, Codex).
> Claude (self-CLI) was skipped for independence per the review workflow's self-CLI rule —
> this review session is itself running inside Claude Code. The orchestrator independently
> verified the load-bearing Codex HIGH finding against the embedded plan code (see Consensus).
>
> Cycle-1 raised three HIGHs (alias YAML-quoting, obsidian_map NameError under --category
> linkres, examples/ example:true exemption count). This cycle assesses whether those are
> resolved AND hunts for regressions introduced by the revision.

## Gemini Review

# Phase 14 Plan Review: Graph Link Resolution (Revision 2)

This review assesses the revised implementation plans for Phase 14 (v1.1.1 Graph Integrity). This is a re-review focusing on the resolution of three previously identified HIGH-severity concerns and any new issues introduced by the revisions.

## 1. Summary
The revised plans are **excellent** and exhibit a high degree of technical rigor. They successfully resolve all three HIGH-severity concerns raised in the previous cycle (alias YAML-quoting, `NameError` prevention, and exemption count reconciliation). The decomposition into a documentation/schema wave and a tool/data wave is logically sound. The inclusion of specific "canary" tests for the colon-title corruption bug and the `obsidian_map` isolation crash demonstrates a proactive "trust but verify" approach. The plans are ready for execution.

## 2. Strengths
- **Surgical Tooling Updates:** The `bin/lint.sh` updates (Plan 02) follow existing project patterns perfectly while introducing necessary helper functions (`normalize_link`, `_yaml_quote_alias`) that are well-encapsulated.
- **Defensive Design:** The use of `if 'obsidian_map' not in dir():` guards ensures that the `linkres` check can be run in isolation (via `--category`) without crashing—a critical fix for developer UX and testability.
- **Robust Verification:** The 9-case test suite (`test_lint_linkres.sh`) is comprehensive, covering not just the happy path but also idempotency, reachability, and YAML parse-integrity for complex titles.
- **Clear Convention Correction:** Plan 01 correctly identifies and replaces the false "Wikilinks resolve to this `title` value" claim at its source in `AGENTS.md`, replacing it with the reality of filename+alias resolution.
- **Quantified Remediation:** Plan 03 provides a precise count of affected files (53 pages), correctly excluding `example: true` fixtures that are mechanically invisible to the linter.

## 3. Concerns
- **[RESOLVED] Alias YAML-Quoting:** Plan 02 now includes `_yaml_quote_alias` and Test 9 (the colon-title canary), which specifically prevents the corruption of decision pages with titles like `Topic: Subtitle`.
- **[RESOLVED] isolation Crash:** Plan 02 now builds `obsidian_map` defensively inside the `linkres` block, preventing the `NameError` crash when running the category in isolation.
- **[RESOLVED] Exemption Counts:** Plan 03 correctly identifies the remediation scope as "45 wiki + 8 lint-visible examples", adjusting for the unconditional `example: true` skip in `bin/lint.sh:972`.

### New Observations (Low Severity)
- **Log Count Placeholders:** In Plan 03 Task 1 Step 6, the log entry uses `<N_wiki>` placeholders. While correct to derive these from the run, the executor must ensure they don't accidentally leave the brackets in the final `log.md` commit. (Disposition: Accept; standard procedure).
- **LINT_VERSION Sequence:** The plan correctly sequences the `LINT_VERSION` bump and the `test_lint_require_version.sh` update in the same commit. This prevents a temporary CI breakage.

## 4. Suggestions
- **Execution Order:** Ensure Plan 02 (Enforcement) is tested against the existing wiki state *before* running the Plan 03 fixes. The plan already specifies this in the "CI-RED-WINDOW STRATEGY" note, which is a great piece of operational foresight.
- **Spot-check:** When running Task 1 of Plan 03, the executor should explicitly verify the content of `wiki/overviews/domain-driven-design.md` after `--fix` to ensure the preservation of the existing `DDD` alias alongside the new ones.

## 5. Risk Assessment
- **Overall Risk:** **LOW**
- **Justification:** The technical path is well-defined, reuse of existing `lint.sh` patterns is high, and the potential for data corruption (the highest risk) has been mitigated through YAML quoting and isolated regex application to frontmatter. The "Canary" tests provide a solid safety net.

**Verdict: APPROVED.** All prior HIGH-severity concerns are resolved. The plans are idiomatically complete and align with the requested architectural direction.

---

## Codex Review

## Summary

The revised plans are much stronger, and two prior HIGH issues are genuinely addressed: YAML alias quoting and defensive `obsidian_map` creation under `--category linkres`. The example-count issue is correctly diagnosed mechanically, but Plan 03 now overcorrects by exempting `example: true` pages from remediation, which appears to conflict with LINK-09 and the milestone target that `examples/` pages carry self-aliases. There is also a new HIGH correctness gap: the proposed `--fix` does not actually add the `id` slug alias for normal compliant pages because it treats the filename stem as sufficient reachability.

## Strengths

- The `obsidian_map` NameError concern is resolved. Plan 02 explicitly builds `obsidian_map` inside the `linkres` block when orphan/gap were skipped, matching the live risk at [bin/lint.sh](/home/yishai/Documents/compendium/bin/lint.sh:1080).

- The YAML quoting concern is resolved. `_yaml_quote_alias`, colon-title tests, and Plan 03 canaries directly cover the prior corruption case.

- The example skip behavior is now understood correctly. Live code skips `example: true` before checks at [bin/lint.sh](/home/yishai/Documents/compendium/bin/lint.sh:956), so `--fix` cannot reach those pages.

- The normalization rules are well-scoped: no edit distance, no stemming, no synonym matching, explicit plural map only.

- Plan 03’s CI-red-window discussion is realistic: Plan 02 alone makes full CI red until data remediation lands.

## Concerns

- [HIGH] The self-alias invariant is weakened from “`title` and `id` are in `aliases`” to “reachable via filename stem or aliases.” Plan 02 computes `to_add` only when `pid.lower() not in reachable`; for normal pages where `id == filename`, the `id` is already “reachable,” so it will not be added to `aliases`. This contradicts LINK-02/LINK-06 and Plan 03’s expected `domain-driven-design` alias block.

- [HIGH] Plan 03’s treatment of `example: true` pages conflicts with LINK-09 as written. It correctly says lint cannot touch the 12 skipped fixtures, but then declares them exempt from graph-resolvable self-aliases. The milestone says all `wiki/` and `examples/` pages carry self-aliases, and LINK-09 says examples pages carry self-aliases while respecting skip conventions. “Not lint-enforced” should not automatically mean “not remediated.”

- [MEDIUM] `linkres` appears to scan only `all_pages` bodies, which excludes `wiki/index.md` and `wiki/log.md`. Orphan scans those specially, but the new body-link variant check does not. Broken links in index/log could evade LINK-05 even though they affect the Obsidian graph.

- [MEDIUM] AGENTS/CLAUDE §11.3 CI severity mapping is not updated in Plan 02. `docs/reference/ci.md` is updated, but that page says AGENTS.md §11.3 is source of truth. Adding `linkres` to `bin/lint.sh` and `docs/reference/ci.md` without AGENTS/CLAUDE §11.3 creates schema drift.

- [LOW] Plan 03’s spot-check examples show unquoted aliases, but Plan 02 intentionally re-emits all aliases quoted. That is harmless but the expected block should match the actual writer style.

- [LOW] Several tasks say “commit” but show only `git add` plus a commit message. Add the actual `git commit -m ...` command if the executor is expected to commit.

## Suggestions

- Change Plan 02 subcheck A fix logic so `--fix` always ensures literal alias membership for both `title` and `id`, independent of reachability. Keep reachability as the error condition if desired, but compute `to_add` from actual aliases:
  `if title not in aliases: add title; if pid not in aliases: add pid`.

- In Plan 01, restore LINK-02 wording to literal self-alias membership, or explicitly revise the requirement. Current “reachable” wording does not match the stated invariant.

- In Plan 03, either hand-edit the 12 `example: true` pages to add self-aliases, or formally change LINK-09 to say they are exempt from remediation. The better fit for the milestone is: lint skips them, but remediation still updates them mechanically or via a separate script.

- Add final verification for examples:
  `bash bin/lint.sh --category linkres examples/ --format json`
  plus a direct alias-membership check over all 20 example markdown files if LINK-09 remains literal.

- Extend `linkres` body-link scanning to include `wiki/index.md` and `wiki/log.md`, or explicitly document that LINK-05 excludes scaffolding files.

- Update AGENTS.md/CLAUDE.md §11.3 CI severity table alongside `docs/reference/ci.md`.

## Risk Assessment

Overall risk: **MEDIUM-HIGH**.

The core lint design is close, and the two technical prior HIGHs are fixed. The remaining risk is requirements drift: the revised plans now enforce reachability rather than literal self-alias membership, and they exempt `example: true` files from remediation rather than just from lint. Those two issues could let the phase finish “green” while missing LINK-02/LINK-09 as originally stated.

---

## Consensus Summary

The two reviewers **agree the three Cycle-1 HIGHs are technically resolved** (YAML alias
quoting via `_yaml_quote_alias` + Test 9 canary; defensive `obsidian_map` build inside the
`linkres` block; correct mechanical diagnosis that `bin/lint.sh:972` skips `example: true`
pages so `--fix` cannot reach them). They **diverge sharply on overall risk**: Gemini rates
the revised plans **LOW / APPROVED**; Codex rates them **MEDIUM-HIGH**, raising two NEW
concerns this cycle.

The orchestrator independently verified Codex's load-bearing HIGH against the embedded plan
code. **It is confirmed real** (details below). Gemini reviewed at the design/intent level and
did not trace the `to_add` computation; Codex traced it. As in Cycle 1, the deeper code-level
trace wins.

### Agreed Strengths

- All three Cycle-1 HIGHs are resolved at the code level (quoting, NameError guard, example
  skip diagnosis). Both reviewers state this explicitly.
- Conservative, well-scoped normalization (`normalize_link`): explicit plural map only, no
  edit distance / stemmer / substring matching.
- Strong "canary" test design — Test 9 (colon-title YAML integrity) and the isolation crash
  guard directly target the prior bugs.
- Realistic CI-red-window discussion in Plan 03 (Plan 02 alone turns full CI red until
  remediation lands).

### Agreed Concerns (highest priority)

- **[HIGH — confirmed live by orchestrator] `--fix` does NOT add the `id` slug alias for
  compliant pages, contradicting the self-alias invariant and Plan 03's own success
  criterion.** Plan 02 subcheck A (14-02-PLAN.md lines 556–575) computes `to_add` against
  `reachable = {stem.lower()} | {alias.lower() ...}` — which **includes the filename stem**.
  For any compliant page where `id == filename`, `pid.lower()` is already in `reachable` via
  the stem, so `id` is never appended to `aliases` (the plan even annotates this branch as
  "near-dead for compliant pages", line 568). But:
    - The milestone target + LINK-02 mandate the literal invariant "every page's `aliases`
      includes its `title` **and `id` slug**".
    - Plan 03's verification (14-03-PLAN.md line 281) explicitly asserts
      `wiki/overviews/domain-driven-design.md` aliases include **both** "Domain-Driven Design"
      **and** "domain-driven-design" (the id slug) after `--fix`.
    With the current `to_add` logic, the id-slug half of that assertion will NOT hold —
    `--fix` adds only the `title`, never the slug, for the typical `id == filename` page.
    Note this is a **regression vs. the RESEARCH.md §8 reference implementation** (lines
    454–474), which computed `to_add` against `existing_lower` (actual alias membership, NOT
    stem-inclusive `reachable`) and therefore DID add the id slug. The Plan-02 revision
    diverged from RESEARCH when it refactored the helper to a caller-computed `to_add`.
    **Fix (Codex, endorsed):** compute `to_add` from literal alias membership, not
    reachability — `if title not in aliases: add title; if pid not in aliases: add pid` — OR
    revise LINK-02 / Plan 03 wording to drop the literal-id-slug invariant. The two must agree.

- **[HIGH per Codex / interpretation drift] `example: true` pages: "not lint-enforced" was
  widened to "not remediated", which may miss LINK-09 as written.** The plans correctly show
  lint cannot touch the 12 `example: true` fixtures, then declare them exempt from carrying
  self-aliases. The milestone says all `wiki/` **and `examples/`** pages carry self-aliases;
  LINK-09 says examples pages carry self-aliases *while respecting skip conventions*. Codex
  reads that as "lint skips them, but remediation still updates them (mechanically or via a
  separate hand-edit)"; the plans read it as "skipped ⇒ exempt". This is a genuine
  spec-interpretation fork, not a code bug — it needs an explicit ruling (hand-edit the 12,
  or formally amend LINK-09 to declare them exempt). Gemini accepted the plans' reading.

### Divergent Views

- **Overall risk:** Gemini **LOW / APPROVED** vs Codex **MEDIUM-HIGH**. Same pattern as
  Cycle 1: design-level review (Gemini) saw the prior bugs fixed and stopped; code-trace
  review (Codex) found the `to_add` regression and the LINK-09 interpretation gap. Orchestrator
  verification sides with Codex on the `to_add` HIGH.
- **LINK-09 examples remediation:** Codex wants the 12 example pages either hand-edited or
  LINK-09 formally amended; Gemini treats the plans' "exempt" reading as correct and final.

### Lower-severity items (non-blocking, worth folding in)

- **[MEDIUM — Codex]** `linkres` body-link scan runs over `all_pages` only, excluding
  `wiki/index.md` and `wiki/log.md` (which `orphan` scans specially). Broken links there could
  evade LINK-05. Fix: extend the scan to index/log, or explicitly document the exclusion.
- **[MEDIUM — Codex]** Plan 02 updates `docs/reference/ci.md` severity table but not
  AGENTS.md/CLAUDE.md §11.3 — yet `ci.md` declares §11.3 the source of truth. Adding `linkres`
  to the severity remap without updating §11.3 is schema drift. Fix: update §11.3 in the same
  change (and re-run `bin/sync-claude.sh --check`).
- **[LOW — Codex]** Plan 03 spot-check examples show unquoted aliases, but Plan 02 re-emits all
  aliases quoted — expected blocks should match the actual writer style.
- **[LOW — Codex]** A few tasks say "commit" but show only `git add` + message; add the literal
  `git commit -m ...` if the executor is expected to commit.
- **[LOW — Gemini]** Plan 03 Task 1 Step 6 uses `<N_wiki>` placeholders in the log entry —
  ensure the brackets are replaced with real counts before committing.

### Recommendation

The three Cycle-1 HIGHs are genuinely closed, but the revision introduced **one confirmed new
HIGH** (`--fix` drops the id-slug alias, breaking the self-alias invariant and Plan 03's stated
verification) plus **one HIGH-rated spec-interpretation fork** (LINK-09 examples remediation).
Do not execute Plan 02/03 verbatim. Reconcile the `to_add` computation with LINK-02/Plan 03
(make `--fix` add the literal id slug, OR amend the invariant), and rule explicitly on the
12 `example: true` pages. Also fold in the §11.3 severity-table update and the index/log
body-link scan. With those applied, the phase cleanly achieves LINK-01..10.
Recommended next step: `/gsd-plan-phase 14 --reviews`.
