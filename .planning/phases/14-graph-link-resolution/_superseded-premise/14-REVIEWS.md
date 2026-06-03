---
phase: 14
reviewers: [gemini, codex]
reviewed_at: 2026-06-03T08:07:48Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md]
cycle: 4
---

# Cross-AI Plan Review — Phase 14 (Cycle 4, re-review)

> Re-review after the Cycle-3 replan. Two independent external reviewers (Gemini, Codex).
> Claude (self-CLI) was skipped for independence per the review workflow's self-CLI rule —
> this review session is itself running inside Claude Code. The orchestrator independently
> verified each load-bearing Codex finding against the plan files (grep/line evidence below).
>
> Cycle-3 left one unresolved HIGH (HIGH #2: the correct examples-remediation workflow
> coexisted with three pieces of stale "12 example:true pages exempt" text — one of which was
> the proposed decision-record body) plus two MEDIUMs (LINK-02 literal membership was
> `--fix`-healed but not CI-enforced; the obsidian templates' alias claim). This cycle assesses
> whether those are resolved AND hunts for regressions introduced by the revision.

## Gemini Review

# Phase 14 Cycle 4 Re-Review: Graph Link Resolution

I have completed a rigorous Cycle 4 re-review of the implementation plans. This revision has reached a high level of technical precision and internal consistency.

## 1. Status of Prior Concerns

### HIGH #2 (Cycle 3): Stale "12 exempt" contradictory text
- **Status: FULLY RESOLVED**
- **Evidence:**
    - **Plan 01 Task 3 (DR body):** Correctly states: "10 dataview-fixtures content pages ... remediated by HAND-EDIT ... 2 scaffolding files ... remediation-exempt."
    - **Plan 03 Objective/Scope Correction:** Explicitly reconciles the fork: "Backfill total = 45 wiki/ + 8 kahneman + 10 fixtures (hand-edited) = 63 ... NOT '12 exempt' (only 2 are exempt; 10 are hand-remediated)."
    - **Plan 03 Step 2/2b:** Step 2 acknowledges `--fix` skips 12; Step 2b explicitly hand-edits 10 of them.
- **Trace:** No remaining instances of "12 pages exempt" or "do not hand-edit the 12" were found in the revised text.

### MEDIUM #1 (Cycle 3): LITERAL self-alias membership CI-enforcement
- **Status: FULLY RESOLVED**
- **Evidence:**
    - **Plan 02 Implementation:** `bin/lint.sh` now computes BOTH the error and the `--fix` `to_add` against `existing_lower` (literal membership), not stem-reachability.
    - **Plan 02 Test 9c:** A new canary test (`lit-concept.md`) specifically asserts that a page which Obsidian *would* resolve via stem still fails CI if the literal LINK-02 ID alias is missing.
    - **Plan 01 Checklist:** AGENTS.md §5 items 18–19 now mandate literal membership.

### MEDIUM #2 (Cycle 3): Obsidian-template alias seeding/claim
- **Status: FULLY RESOLVED**
- **Evidence:**
    - **Plan 01 Task 2:** Templates now seed `aliases: - {{title}}`.
    - **Plan 01 Interfaces:** Explicitly documents the limitation: "The {{title}} placeholder below seeds only the TITLE alias ... Do NOT claim these obsidian templates ship the complete aliases ⊇ {title, id} invariant."
    - **Plan 01 Success Criterion:** Correctly reflects that templates seed one of the two literal aliases.

### LOWs (Cycle 3): Count drift, threat model, log placeholders
- **Status: FULLY RESOLVED**
- **Evidence:**
    - **Counts:** Consistent 63/2 split across all plans.
    - **Threat Model:** T-14-02-04 now matches the code's `print(stderr)` warning behavior.
    - **Log Placeholders:** Plan 03 Task 1 Step 6 includes a mandatory grep-gate (`git diff --cached wiki/log.md | grep -q '<N_'`) to prevent committing placeholders.

## 2. Regressions & New Observations

- **Test Count Inconsistency (Minor):** Plan 02 refers to "11 test cases" in several headings/summaries, but the "Behavior" section and the implementation list 12 cases (Tests 1–10, with 9b and 9c). This is a trivial documentation drift with no impact on implementation quality.
- **Regex Robustness:** The `ALIASES_RE` regex (`^aliases:.*?(?=^\w|\Z)`) is safe because it is scoped to the `fm_section` (top 3 lines to first `\n---`) and requires a start-of-line match, preventing collision with body text or indented YAML blocks.
- **YAML Quoting:** The inclusion of `_yaml_quote_alias` and the Step 5b canary in Plan 03 provides a strong safety net against YAML corruption for colon-bearing titles.

## 3. Risk Assessment: LOW

The plans are now technically sound, internally consistent, and rigorously validated via canaries for every confirmed high-risk failure mode (YAML corruption, literal-membership enforcement, and remediation scope).

**Verdict: APPROVED for execution.**

---

## Codex Review

**Summary**
Cycle-4 fixes the prior Cycle-3 HIGH and the two MEDIUMs. I would not block on the original issues anymore. Overall risk is **MEDIUM**, mostly from new stale count contradictions and a few execution hazards that can cause another replan/test failure.

**Prior Issues**
- **Cycle-3 HIGH, stale "12 example:true pages exempt" text: RESOLVED.** Plan 03 now states the correct split: 10 dataview fixtures hand-edited, 2 scaffolding files exempt (14-03-PLAN.md:63, :66, :67). It explicitly says `NOT "12 exempt"` (:69) and Step 2b requires hand-editing all 10 fixtures (:183).
- **Cycle-3 MEDIUM, literal id-alias membership not CI-enforced: RESOLVED.** Plan 02 adds Test 9c for a stem-reachable page missing the literal id alias (14-02-PLAN.md:261), and the implementation gates on `existing_lower`, not `reachable` (:614, :636).
- **Cycle-3 MEDIUM, obsidian templates falsely claimed full invariant: RESOLVED.** Plan 01 now says obsidian templates seed only `{{title}}`, with the id slug completed by `--fix` (14-01-PLAN.md:37, :350).

**Strengths**
- The remediation split is now explicit and repeated in the objective, interfaces, task steps, verification, and success criteria.
- Plan 02's literal-membership predicate aligns the error condition and `--fix` predicate, which is the right regression guard.
- The YAML quoting and defensive `obsidian_map` build are well specified and tested.

**Concerns**
- **MEDIUM: Plan 03 still contains stale hard-coded wiki counts.** It says "All 45 wiki/ pages" and "4 were already compliant" in must-haves (14-03-PLAN.md:32), but later says the prior "4 already compliant" framing no longer applies and not to hard-code 45 (:93). Remove the exact 45/4 claim or make it "actual autofix count."
- **MEDIUM: Plan 01 proposed DR has frontmatter/schema issues.** The DR `summary` contains `[[X]]` in YAML frontmatter (14-01-PLAN.md:398), while the same plan says no wikilinks in frontmatter (:423). Reword as "double-bracket links" in frontmatter.
- **MEDIUM: Plan 01 contradicts its own "no real slugs in DR examples" instruction.** It says to use placeholders in the DR body (14-01-PLAN.md:387), then uses real `domain-driven-design.md` / `[[Domain-Driven Design]]` examples (:438, :441).
- **MEDIUM: Plan 02 test fixture skeleton omits `sources/`.** It only creates `concepts` and `entities` (14-02-PLAN.md:279), but later creates `$WIKI/sources/src-test-01.md` (:299). Add `"$WIKI/sources"` to `mkdir -p`.
- **LOW: test-count drift remains.** Plan 02 says 11 cases in several places, but verification still says "all 9 PASS" (14-02-PLAN.md:780).
- **LOW: placeholder check is staged-diff only before staging.** Plan 03 checks `git diff --cached wiki/log.md` for `<N_` (14-03-PLAN.md:298), but `git add` happens later (:305). Use `grep -q '<N_' wiki/log.md` before commit.

**Suggestions**
- Replace all fixed "45 wiki / 4 compliant" claims with "actual autofix count."
- Fix the DR frontmatter/body examples before execution.
- Add `sources/` to the test fixture setup.
- Add `bash bin/lint.sh --category linkres examples/ --format json` zero-error verification for lint-visible examples.

**Risk Assessment**
**MEDIUM.** The original high-risk logic is fixed, but the remaining plan-text contradictions and fixture setup bug are likely to waste execution time or produce another review cycle if left as-is.

---

## Consensus Summary

Both reviewers **agree the Cycle-3 HIGH (stale "12 example:true exempt" contradictory text) is
now FULLY RESOLVED**, and **both Cycle-3 MEDIUMs are FULLY RESOLVED** (literal LINK-02 membership
is now CI-enforced via the `existing_lower` predicate + Test 9c canary; the obsidian templates now
honestly seed only `{{title}}` and no longer claim the full invariant). The orchestrator
independently grep-verified the HIGH-#2 disposition: no remaining "12 exempt" / "do not hand-edit
the 12" text exists; Plan 03 L63–L69 and Plan 01 L448 carry the agreed 10-hand-edited / 2-exempt
split, and the proposed DR Consequences body (the worst Cycle-3 instance) is corrected.

**No unresolved HIGH concerns remain this cycle.** Gemini rates the plans **LOW / APPROVED**;
Codex rates them **MEDIUM** — but the Codex MEDIUMs are all NEW lower-severity plan-text /
fixture-hygiene items, not the prior HIGH. The two reviewers diverge only on whether the residual
items warrant a MEDIUM overall rating (Codex) or a LOW one (Gemini); they do NOT diverge on the
absence of a HIGH.

The orchestrator independently verified all five Codex findings against the plan files
(line-level grep evidence). All five are real. None is HIGH. They are worth folding into a single
text-hygiene fix pass before execution to avoid a wasted execution cycle.

### Agreed Strengths

- **Cycle-3 HIGH #2 (examples remediation) fully closed** — the 10-hand-edited / 2-exempt split is
  now stated consistently in the objective, interfaces, task steps, verification, success criteria,
  AND the proposed DR body; no contradictory "12 exempt" text survives (both reviewers + orchestrator
  grep-confirmed).
- **LINK-02 literal membership is now CI-ENFORCED, not merely `--fix`-healed** — the `linkres` error
  and the `--fix` `to_add` share the same `existing_lower` predicate, so anything that errors is
  exactly what `--fix` repairs; Test 9c is the regression canary (Cycle-3 MEDIUM #1 closed).
- **Obsidian templates make an honest, limited claim** — seed only `{{title}}`; the id slug is added
  on first `--fix`; the must-have wording matches (Cycle-3 MEDIUM #2 closed).
- **All prior code-level fixes remain intact** — `_yaml_quote_alias` colon-title safety, the defensive
  `obsidian_map` build for `--category linkres` isolation, index.md/log.md body-link scan, and the
  §11.3 ↔ ci.md severity-remap consistency.

### Agreed Concerns (highest priority)

All concerns this cycle are MEDIUM or LOW. There are **no HIGH concerns**.

- **[MEDIUM — Codex, orchestrator-confirmed] Plan 03 must-have L32 hard-codes "All 45 wiki/ pages …
  (4 were already compliant: anthropic, claude-code, backpressure, ralph-loop-creator-skill)"**,
  which directly contradicts the same plan's L93 instruction that the "4 already compliant" framing
  "no longer applies cleanly … do NOT hard-code 45" (since `--fix` now uses literal membership, even
  `title==stem` pages get the literal alias added). **Fix:** rewrite the L32 must-have to "all wiki/
  pages needing a self-alias are backfilled by `--fix`; the autofix-finding count is the source of
  truth (do not hard-code 45/4)."
- **[MEDIUM — Codex, orchestrator-confirmed] Plan 01 DR `summary` frontmatter (L398) contains
  literal `[[X]]`**, while the same plan's FORBIDDEN-PATTERNS block (L423) and §3 prohibit wikilinks
  in frontmatter. `[[X]]` is an abstract placeholder inside a quoted string (not a resolvable link),
  but the bracket syntax in YAML is exactly what the rule warns against and an executor copying it
  verbatim ships a frontmatter `[[ ]]`. **Fix:** reword the summary to "resolves [X] by filename
  stem + aliases" or "double-bracket links" — drop the literal `[[ ]]` from the YAML scalar.
- **[MEDIUM — Codex, orchestrator-confirmed] Plan 01 intra-task contradiction on DR-body slug
  neutrality:** L387 instructs "do NOT use real vault page slugs as inline examples in the DR body
  (use `<page-title>`/`<concept-slug>` placeholders)", but the DR body template at L438/L441 uses
  real `domain-driven-design.md` and `[[Domain-Driven Design]]`. (Note: §3's neutrality prohibition
  is scoped to *template-public files*, and `wiki/decisions/` is NOT one — L387 says so itself — so
  the real slugs are actually permitted by §3; the defect is Plan 01's self-imposed stricter L387
  instruction contradicting its own example.) Same *class* as Cycle-3 HIGH #2 (a self-contradicting
  in-task instruction producing committed wiki content) but lower severity: it affects example
  hygiene in a DR body, not correctness or remediation scope. **Fix:** either relax L387 to "real
  structural terms are fine in the DR body (wiki/decisions/ is not template-public)" or genericize
  the L438/L441 examples to placeholders. Pick one so the executor is not told two things.
- **[MEDIUM — Codex, orchestrator-confirmed] Plan 02 Test fixture `mkdir -p` omits `sources/`:**
  L280 creates only `"$WIKI/concepts" "$WIKI/entities"`, but Test 7 requires writing
  `$WIKI/sources/src-test-01.md` (L299). If the executor writes that file without first creating
  the dir, the test errors at setup. **Fix:** add `"$WIKI/sources"` (and, for safety, `"$WIKI"`
  itself for the index.md/log.md stubs) to the `mkdir -p`.
- **[LOW — both, orchestrator-confirmed] Test-count drift:** Plan 02 verification step 1 (L780)
  still says "all 9 PASS" while the plan describes 11–12 cases (Tests 1–10 incl. 9b, 9c). Cosmetic;
  align to the actual count.
- **[LOW — Codex] Placeholder grep-gate timing:** Plan 03 Step 6 greps `git diff --cached
  wiki/log.md` for `<N_` (L298) before the `git add` at L305, so the staged diff may be empty at
  check time. **Fix:** grep the working-tree file (`grep -q '<N_' wiki/log.md`) before commit, or
  move the check after `git add`.

### Divergent Views

- **Overall risk rating:** Gemini **LOW / APPROVED** vs Codex **MEDIUM**. The divergence is purely
  about whether the residual NEW plan-text/fixture items rise to a MEDIUM overall rating. They do
  NOT diverge on disposition of the prior HIGH (both: RESOLVED) or on the absence of any new HIGH.
  Orchestrator reads this as: execution-ready on correctness, but a 6-item text-hygiene pass (one
  fixture-dir fix + five doc-consistency fixes) is cheap insurance against a wasted execution cycle.

### Recommendation

**The Cycle-3 HIGH and both Cycle-3 MEDIUMs are fully resolved; no HIGH concerns remain.** The
plans are correctness-complete and the executable workflow is sound. Before execution, fold in the
single MEDIUM fixture-dir fix (Plan 02 `mkdir -p` += `sources/`) and the four MEDIUM/LOW plan-text
consistency fixes (Plan 03 L32 count claim; Plan 01 DR summary `[[X]]`; Plan 01 L387↔L438 slug
contradiction; Plan 02 "9 PASS"; Plan 03 placeholder grep timing). All are text/setup edits — none
changes the executable logic, which is already correct.

Recommended next step: a light `/gsd-plan-phase 14 --reviews` text-hygiene pass, then execute.
