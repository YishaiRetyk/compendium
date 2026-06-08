---
phase: 18
reviewers: [claude, codex]
reviewed_at: 2026-06-08T00:00:00
plans_reviewed: [18-00-PLAN.md, 18-01-PLAN.md, 18-02-PLAN.md]
---

# Cross-AI Plan Review — Phase 18 (Skills Overlay)

> Two independent reviewers (Claude, Codex). Several concrete, falsifiable claims
> were **verified by direct test** during this review; results are recorded in the
> Consensus Summary under "Verified Findings."

## Claude Review

I've reviewed all three plans against the SPEC, CONTEXT, RESEARCH, PATTERNS, and the actual repo conventions (gitignore, sync-claude idiom, pre-commit composition, neutrality gate). Below is my adversarial assessment.

---

### 1. Summary

These are well-researched, well-documented plans that correctly mirror the established `sync-claude.sh` generated-artifact idiom and faithfully implement the two-layer Source-of-Truth model. Dependency ordering (gitignore → generator+wiring → docs) is sound, the bash-3.2 `get_desc()` deviation from D-01 is a good defensive call, and the exit-code reconciliation (1 vs sync-claude's 2) is handled. **However, three of the ten Wave-0 test scripts contain a concrete `set -e` bug that will make them fail exactly when they are supposed to pass** — including the one test Plan 00 explicitly claims will be green. This is a latent defect that will surface as a false RED, masked by Plan 00's "expected RED state" framing, and will block Plan 01's `PHASE 18 TESTS: 10/10` acceptance gate until an executor debugs and patches it. Secondary concerns center on tests mutating the real working tree without cleanup, a vacuous idempotency check, and the mechanical SKILL-02 gate being a proxy that a 3-line procedural body could slip through.

> NOTE (Claude asserted `.gitignore` negation is correct). This claim was **disproven by direct test** during the review — see Consensus Summary. Codex's contrary HIGH finding is the correct one.

### 2. Strengths

- **Faithful pattern reuse.** `gen-skills.sh` is a true structural twin of `sync-claude.sh`; the pre-commit insertion point (between sync-claude and lint write-gate) and CI job both match D-03 exactly.
- **D-07 is protected from "simplification."** The load-bearing rationale for keeping structural assertions alongside the diff is documented in the script comment, the pre-commit comment, the CI comment, and the docs page.
- **Bash-3.2 portability caught proactively.** Swapping `declare -A` for a `case`-based `get_desc()` is the right call and the deviation from D-01 is documented inline.
- **Exit-code trap avoided.** RESEARCH Pitfall 6 (sync-claude exits 2, SPEC wants 1) is explicitly handled; tests assert exit 1.
- **Strong artifact discipline.** Committed-not-gitignored rationale, hand-edit prohibition, and `--check` enforcement are coherent and correctly mapped to Claude Code's session-start filesystem discovery.

### 3. Concerns

- **[HIGH] `set -e` + `rc=$?` bug breaks 3 test scripts on the success path.** In `test_skills_git_tracked.sh`, `test_gen_skills_check_clean.sh`, and `test_gen_skills_check_drift.sh`, a bare command that returns non-zero (e.g. `git check-ignore` exiting 1 on the PASS case, or `gen-skills.sh --check` exiting 1 on injected drift) is *not* in an `if`/`&&`/`||`/`!` context, so under `set -e` the script aborts before `rc=$?` runs and the assertion never fires. This bites precisely the expected-non-zero cases and directly contradicts Plan 00's claim *"test_skills_git_tracked should PASS."* Because Plan 00 frames nearly all Wave-0 failures as "expected RED," an executor is likely to not scrutinize these — the bug is camouflaged. Fix: `cmd && rc=0 || rc=$?` (or bracket with `set +e`/`set -e`).
- **[MEDIUM] Tests mutate the real repo working tree with no `trap` cleanup.** `test_skills_git_tracked.sh` does `mkdir -p`/`touch` and never removes it; the `--check` drift tests append drift lines and rely on a *trailing* regenerate to restore. Combined with the `set -e` bug, an aborted test leaves a stray empty `SKILL.md` (Wave 0) or a drifted committed file (Wave 1). Fixtures-or-trap would make the suite idempotent.
- **[MEDIUM] Idempotency test can pass vacuously.** `test_gen_skills_idempotent.sh` checks `git diff --name-only .claude/skills/`, but `git diff` only reports *tracked* files; before Plan 01 stages them the diff is empty regardless. Capture per-file checksums or use `git status --porcelain` for a real test.
- **[MEDIUM] The mechanical SKILL-02 gate is a proxy, not a guarantee.** `--check` enforces body ≤3 lines + pointer substring + dir purity + no first-person in *description*. A 3-line body with two procedural imperatives plus the pointer line would pass. RESEARCH recommended a body-content grep for imperative verbs; none is implemented. SKILL-02's "zero behavior" still rests on the human desk-check. Plans over-state the mechanical coverage.
- **[MEDIUM-LOW] DR + index commit must clear the pre-commit provenance write-gate, untested by the plan.** Plan 02 commits the DR + index.md; the hook runs `lint.sh --strict --staged --category provenance`. The plan assumes decision pages don't need per-claim `[prov:]` markers (true for the analog) but never verifies the exemption. Low likelihood, but an unverified integration assumption on the critical path.
- **[LOW] First-person regex has a character-class bug.** `[[:space:]|$]` is a character class (space/pipe/dollar literal), not "space or end-of-line"; a description ending in a pronoun would not be caught. Both the test and the generator versions are weaker than advertised.
- **[LOW] Dead code in `lib.sh`.** Phase-18 tests run against the real repo; `make_bare_repo`/`write_page`/`cleanup_fixture_repo` copied from phase-15 are unused.
- **[LOW] `files_modified` lists `.planning/ROADMAP.md` though Task 2B is "verify, no edit."** Minor manifest inaccuracy.
- **[LOW] Generator does no YAML-validity / non-empty-description check.** `description: ${desc}` is emitted unquoted; a future `:` or `#` would produce ambiguous YAML the gate wouldn't catch.
- **[LOW] CI `skills-check` job lacks the draft-PR `if:` guard** that the sibling `strict` job uses — inconsistent and undocumented as deliberate.

### 4. Suggestions

- Fix the `set -e` capture in all three affected tests (`cmd && rc=0 || rc=$?`). Highest-value change.
- Add `trap … EXIT` cleanup to every test that touches the real tree.
- Harden the idempotency test to compare content (sha256) or `git status --porcelain`, not `git diff`.
- Add a body-content grep for procedural/imperative verbs to the verifier step; at minimum state explicitly that the line-count assert is a proxy and the desk-check is the real SKILL-02 guarantee.
- Run `bin/lint.sh --strict --staged --category provenance` against the staged DR+index inside Plan 02 *before* the commit task.
- Fix the `[[:space:]|$]` character-class to a proper alternation/anchor; consider dropping `-i`.
- Trim `lib.sh` to the two helpers actually used.

### 5. Risk Assessment

**Overall: MEDIUM.** Scope is genuinely low-risk, the architecture is correct, the SOT model is sound. What pulls the rating up is the HIGH-severity `set -e` test bug — concrete, affecting the exact success-path tests, and camouflaged by the "expected RED" narrative. None of these threaten the *deliverable*, but they threaten the *verification story*. Fix the three `set -e` captures and add `trap` cleanup and residual risk drops to LOW.

---

## Codex Review

### Overall Summary

The phase is well-scoped and the two-layer source-of-truth model is directionally sound: workflow markdown owns behavior, `bin/gen-skills.sh` owns generated artifact bytes. The main risks are mechanical, not conceptual: the `.gitignore` re-include pattern is likely wrong, several tests will fail because of `set -e`, the generator does not actually enforce "pointer-only" strongly enough, the pre-commit auto-fix can stage unintended files, and the documentation/DR plan misses required wiki workflow bookkeeping.

### 18-00 Review

**Strengths**
- Good wave split: unblocking git tracking and RED tests before implementation is the right dependency order.
- The test list maps well to SKILL-01/SKILL-02 acceptance criteria.
- Calling out `.claude/skills/` tracking as a precondition is correct and important.

**Concerns**
- **[HIGH]** The `.gitignore` fix is probably insufficient. With `.claude/` ignored as a directory, `!.claude/skills/` and `!.claude/skills/**` may not re-include descendants because the parent directory remains excluded. Prefer ignoring `.claude/*` instead of `.claude/`, or explicitly re-include the parent.
- **[HIGH]** `test_gen_skills_check_clean.sh` and `test_gen_skills_check_drift.sh` will abort under `set -e` when `--check` intentionally exits non-zero. They need `set +e` or `if bash …; then … fi` around expected failures.
- **[HIGH]** Tests mutate the real repo and lack traps. Drift injection or stub creation can leave `.claude/skills/` dirty if a test exits early.
- **[MEDIUM]** `test_skills_git_tracked.sh` verifies "not ignored," not "tracked." SKILL-02 requires committed/tracked files; add a `git ls-files` assertion after Plan 01.
- **[MEDIUM]** Directory purity tests only reject extra `.md` files, but the spec says each skill dir contains only `SKILL.md`. Non-md files would still be allowed.
- **[LOW]** The grep acceptance around `!.claude/skills/` is inconsistent: one check expects one match, later verification expects two.

**Suggestions**
- Change ignore strategy to something like `.claude/*`, `!.claude/settings.cloud.json`, `!.claude/skills/`, `!.claude/skills/*/`, `!.claude/skills/*/SKILL.md`.
- Run destructive tests in temp fixtures or add `trap` cleanup/restore handlers.
- Split "trackable" and "tracked" tests.
- Make directory purity reject any file other than `SKILL.md`.

**Risk Assessment: MEDIUM-HIGH** — Wave 0 is foundational. If the gitignore pattern or RED tests are wrong, later plans will appear broken even if the implementation is fine.

### 18-01 Review

**Strengths**
- Generator-first approach is the right enforcement mechanism for generated artifacts.
- The planned `--check` gate mirrors existing repo practice and is easy to reason about.
- CI and pre-commit integration are correctly separated: local auto-fix, CI hard-fail.
- D-07 is a good insight: regenerate-diff alone cannot prevent a fattened template.

**Concerns**
- **[HIGH]** The structural assertions do not actually enforce pointer-only behavior. A future template could encode procedural content in one or two lines and still pass line-count, diff, and pointer-substring checks.
- **[HIGH]** Pre-commit runs `git add .claude/skills/` after any check failure. If an extra file exists, or if structural assertions fail, the hook may stage unintended content and then loop forever.
- **[HIGH]** Directory purity checks only extra `.md` files. Non-md files under `.claude/skills/` would be trackable and could be staged by the hook.
- **[MEDIUM]** Descriptions are unquoted YAML scalars. Current strings are probably safe, but future colons, hashes, or quoting characters can break frontmatter.
- **[MEDIUM]** The ingest description encodes "classify-extract-merge-lint pipeline," which starts to duplicate workflow behavior in always-loaded metadata. Keep descriptions to what/when, not how.
- **[MEDIUM]** The lint description says "audit wiki health," but "Audit" is a distinct workflow in this project. That may confuse model invocation.
- **[MEDIUM]** `--check` does not verify that `schema/workflows/{op}.md` exists.
- **[LOW]** First-person regex is narrow; it misses "we're," "our," "I've," punctuation, and start/end edge cases.

**Suggestions**
- Assert the normalized body is exactly one allowed pointer line, plus optional blank line after frontmatter.
- Check all files in each skill dir: `find "$dir" -mindepth 1 -maxdepth 1 ! -name SKILL.md`.
- In the hook, on failure: generate, rerun `--check`, and only then stage exact files: `.claude/skills/{ingest,query,lint,reflect}/SKILL.md`.
- Quote YAML descriptions or emit block scalars safely.
- Add workflow-target existence checks.
- Avoid "audit" in the lint skill description.

**Risk Assessment: MEDIUM-HIGH** — The implementation mostly achieves artifact drift detection, but SKILL-02 is under-enforced. The biggest problem is that "thin" is checked more strongly than "zero behavior."

### 18-02 Review

**Strengths**
- Correctly keeps AGENTS.md/CLAUDE.md untouched, preserving the v1.2 resident-core goal.
- Adds the right governance artifacts: decision record plus adopter-facing docs.
- The docs explain generated-artifact discipline clearly.

**Concerns**
- **[HIGH]** The planned DR uses `## Why NOT the Alternatives`, but the decision page schema requires `## Alternatives Considered`.
- **[HIGH]** The plan updates `wiki-cloud/index.md` but omits `wiki-cloud/log.md`. The reflect workflow says decision-record creation updates index and log.
- **[MEDIUM]** `affected_pages: index` is questionable without adding `decision_history` to `wiki-cloud/index.md`. Either set `affected_pages: []` like prior infrastructure DRs or add the backlink intentionally.
- **[MEDIUM]** The plan does not explicitly route the wiki mutation through the reflect workflow or validation path before editing wiki files.
- **[MEDIUM]** The DR includes many factual/process claims without `[prov:]`. Existing DR precedent may tolerate this, but it remains in tension with the global provenance rule.
- **[LOW]** The nested fenced code block inside the planned `docs/reference/skills.md` "full content" can break markdown copying unless the outer fence uses four backticks.
- **[LOW]** `.planning/ROADMAP.md` is listed as modified, but the task says no edit is expected.

**Suggestions**
- Rename the DR section to exactly `## Alternatives Considered`.
- Add `wiki-cloud/log.md` to files modified and append a `reflect | skills overlay decision record` entry.
- Decide whether `index` is truly an affected page. If yes, add `decision_history`; if no, use `affected_pages: []`.
- Run `bash bin/lint.sh --ci` after the DR/index/docs edits and do not mask the exit code with `; echo $?`.
- Use four-backtick outer fences in the plan where nested code fences are included.

**Risk Assessment: MEDIUM** — The docs work is straightforward, but it risks violating the project's own wiki workflow rules. The missing log entry and wrong DR section heading are the main blockers.

---

## Consensus Summary

### Verified Findings (tested during this review)

These claims were checked empirically, not just read:

1. **`.gitignore` negation is BROKEN as planned (Codex HIGH — confirmed; Claude's "correct" claim disproven).** Tested in a scratch repo: with `.claude/` ignored as a *directory*, the planned `!.claude/skills/` + `!.claude/skills/**` lines do **not** un-ignore `.claude/skills/ingest/SKILL.md` (git cannot re-include descendants of an excluded directory). Codex's fix — change the ignore line to `.claude/*` (with the existing `!.claude/settings.cloud.json` plus the skills negations) — was tested and **works**: skills files become trackable, `settings.cloud.json` stays trackable, other `.claude/` files stay ignored. **This is the single most important fix** — without it, Plan 00's foundational premise fails silently and every downstream "committed skills" acceptance criterion is unachievable.
2. **`set -e` + `rc=$?` bug is real (both reviewers HIGH — confirmed).** A `set -euo pipefail` script with a bare `false` followed by `rc=$?` aborts before `rc=$?` executes (verified). Affects `test_skills_git_tracked.sh`, `test_gen_skills_check_clean.sh`, `test_gen_skills_check_drift.sh`. Fix: `cmd && rc=0 || rc=$?`.
3. **DR section heading wrong (Codex HIGH — confirmed).** `schema/reference/page-types.md` requires `## Alternatives Considered`; Plan 02 specifies `## Why NOT the Alternatives`. The cloned analog DR uses the correct heading.
4. **`wiki-cloud/log.md` omission (Codex HIGH — confirmed as a real workflow gap).** `schema/workflows/reflect.md` (step 6) requires appending a `## [YYYY-MM-DD] reflect | <scope>` entry to `log.md` when a decision record is created. Plan 02 updates `index.md` only.
5. **Directory-purity is `.md`-only (both reviewers MEDIUM — confirmed).** The SPEC says each skill dir contains *only* `SKILL.md`, but the generator assertion, the tests, and the Plan-01 verification all use `-name "*.md" ! -name "SKILL.md"`, so a non-md file (or a staged stray file the hook auto-adds) would pass.

### Agreed Strengths

- Generator-first / `sync-claude.sh`-twin approach is the right enforcement idiom for generated artifacts (both).
- Correct separation of local auto-fix (pre-commit) vs CI hard-fail (both).
- D-07 (structural assertions are not redundant with regenerate-diff) is a genuine insight, well-documented (both).
- AGENTS.md/CLAUDE.md resident core correctly left untouched (both).
- Two-layer SOT model is conceptually sound (both).

### Agreed Concerns (highest priority)

- **[HIGH] `set -e`/`rc=$?` test bug** — raised by both, verified. Breaks the success-path tests, camouflaged by the "expected RED" framing.
- **[HIGH] SKILL-02 "zero behavior" is under-enforced** — both note the mechanical gate checks "thin" (line count) more strongly than "zero behavior"; a 3-line procedural body slips through. No body-content imperative-verb grep is implemented despite RESEARCH recommending it.
- **[MEDIUM] Directory purity rejects only `.md` files**, not arbitrary files — both. Compounds the pre-commit `git add .claude/skills/` blanket-stage risk Codex raised.
- **[MEDIUM] Unquoted YAML description scalars** — both flag future `:`/`#` breaking frontmatter with no parseability check.
- **[MEDIUM] Tests mutate the real working tree without `trap` cleanup** — both (Codex tagged HIGH for Wave 0, Claude MEDIUM); an aborted test leaves the tree dirty.
- **[LOW] First-person regex is buggy/narrow** — both.

### Divergent Views

- **`.gitignore` negation correctness** — Claude said the `.claude/` + `!.claude/skills/` form is correct; Codex said it is broken. **Resolved by direct test: Codex is right, Claude is wrong.** Use `.claude/*`.
- **Pre-commit blanket `git add .claude/skills/`** — Codex rated this HIGH (could stage unintended content / loop forever); Claude did not raise it independently. Worth treating at Codex's severity given it composes with the directory-purity-is-`.md`-only gap.
- **`affected_pages: index`** — Codex questions it (MEDIUM); Claude did not raise. Minor.

### Recommended Disposition

Feed back into `/gsd-plan-phase 18 --reviews`. The four verified HIGHs below are all small, mechanical fixes with no scope impact:
1. `.gitignore` → `.claude/*` form (with intermediate-dir negations).
2. `cmd && rc=0 || rc=$?` in the three `set -e`-affected tests (+ `trap` cleanup).
3. DR section heading → `## Alternatives Considered`; add `wiki-cloud/log.md` reflect entry to Plan 02.
4. Tighten directory purity to reject any non-`SKILL.md` file (not just non-md), and have the pre-commit hook stage the four exact files rather than `git add .claude/skills/`.

The "SKILL-02 zero-behavior is a proxy" HIGH is a known SPEC limitation (the SPEC acknowledges a human desk-check); recommend adding a body imperative-verb grep to the gate or explicitly documenting the desk-check as load-bearing, but it does not block the deliverable.
