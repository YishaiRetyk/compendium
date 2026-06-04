---
phase: 16
cycle: 4
reviewers: [claude, codex]
reviewed_at: 2026-06-05T00:00:00
plans_reviewed: [16-00-PLAN.md, 16-01-PLAN.md, 16-02-PLAN.md, 16-03-PLAN.md, 16-04-PLAN.md]
prior_cycle_high: 2
current_cycle_high: 0
---

# Cross-AI Plan Review — Phase 16: Reference Extraction (Cycle 4)

**Convergence-loop cycle 4.** The plans were revised (commit `11827af`) to address the 2 HIGH
concerns from cycle 3, both about pre-existing neutrality-gate state:
(1) `bin/check-neutrality.sh` exited 2 on the committed tree (3 `wiki-cloud/` files carry
denylisted terms outside `examples/kahneman/`); and (2) a filename-level leak
(`dr-2026-04-15-kahneman-to-examples.md` ships via the release ALLOWLIST with a denylisted
term in its name, unscanned by the content-only gate). This review verifies the cycle-4 fixes
against the **live repo** (including an empirical re-run of the scanner on a patched tree) and
re-scans for new defects.

**Verdict:** Both cycle-3 HIGHs are **FULLY RESOLVED** (both reviewers; Claude repo-verified with
an empirical exit-0 proof). The cycle-4 revisions introduce **0 new HIGH**. Two MEDIUM and three
LOW findings remain for polish but none blocks execution. **Net: 0 unresolved HIGH.**

---

## Claude Review

All findings verified against the live repo at HEAD `11827af`, including an empirical scanner
re-run on a `git archive HEAD` tree with the planned exemptions applied.

### 1. Summary

The cycle-4 Wave-0 plan (16-00, now 6 tasks) cleanly and verifiably resolves both cycle-3 HIGHs.
The neutrality gate is pre-cleared via the **sanctioned `neutrality_exempt: true` precedent** —
which I confirmed is real (the scanner honors it at line 222; 3 in-repo files already use it) —
applied to the 3 offending files, with the lint.sh hardcoded report template ALSO patched so the
exemption survives regeneration (root-cause fix for the recurring 12.1-style wipe). The filename
leak is closed by adding basename path-name scanning with a single narrow `PATH_NAME_EXEMPT`. I
empirically proved the remedy works: applying the 3 frontmatter exemptions to a clean HEAD tree
and re-running `bash bin/check-neutrality.sh` yields **exit=0**. The load-bearing precondition the
cycle-3 review said was unachievable as previously planned is now genuinely reachable.

### 2. Cycle-3 HIGH Disposition (repo-verified)

**HIGH #1 — `bin/check-neutrality.sh` exits 2 on the committed tree → FULLY RESOLVED.**
Verified live: the gate currently exits 2 with exactly 6 hits across the 3 named files
(`dr-2026-06-04-privacy-asymmetric-two-dir.md:30,92`, `log.md:344,345`,
`maintenance/lint-report.md:86,87`) — matching the plan's enumeration exactly. Tasks 3–5 add
`neutrality_exempt: true` to all three. The precedent is genuine: `has_neutrality_exempt()` skips
`.md` files with that frontmatter (line 222), and `wiki-cloud/index.md` + two DRs already carry it.
Task 4(a) fixes the durability root cause — verified the report is regenerated from a hardcoded
f-string at `bin/lint.sh:2504` (`report_content = f"""---`), with `has_contradictions: false` at
2522 and `knowledge_domain: ""` at 2523, exactly where Task 4a inserts the exemption. The plan's
`<verification>` includes a post-lint regeneration re-run, proving durability. **Empirical proof:**
patching the 3 files on a clean `git archive HEAD` tree → scanner exit=0.

**HIGH #2 — filename-level neutrality leak → FULLY RESOLVED.**
Verified the DR exists and `wiki-cloud/decisions` is release-allowlisted (`bin/release.sh:33`).
Task 6 adds basename scanning with `PATH_NAME_EXEMPT = {"wiki-cloud/decisions/dr-2026-04-15-kahneman-to-examples.md"}`.
The scanner structure matches the plan's line refs (SELF_REFERENTIAL_EXEMPT 161, SANCTIONED_PATH_RE
169, per-file loop with `rel_path`), so the new check slots in cleanly. **Verified no spurious
failures:** after exempting that one DR, a full simulated basename scan over PUBLIC_PATHS finds
ZERO other denylisted basenames — so the single-entry exemption passes the current tree clean while
hard-failing any future denylisted filename.

### 3. Cycle-3 MEDIUM/LOW carry-overs (verified addressed in 16-04)

- **MEDIUM (E.3 resident/extracted conflation) → addressed.** 16-04 STEP E.3 now has an explicit
  "SCOPE BOUNDARY (cycle-3 MEDIUM fix)" block listing §5 `knowledge_domain`, §8 cross-tier rule,
  `wiki-local/sources/`, `FROM "wiki-cloud"` as belonging to LEAF files, NOT the template resident
  range, with both `<` and `>` diff directions handled.
- **LOW (F.5 scoping prose vs command) → addressed.** STEP F.5 now reasons explicitly that after
  §16 deletion + §§4/5/6/8/13 stub-reduction the `schema/reference|workflows|docs/reference` path
  pattern appears ONLY in the routing-table/stub region, so the whole-file grep IS effectively
  scoped (prose now matches command), with an `awk`-bound escape hatch noted if a future edit
  reintroduces the pattern elsewhere.

### 4. New Concerns

- **MEDIUM — Task 1 internal commit-instruction contradiction.** 16-00 Task 1 (line 135) says
  "After the edit, commit: `schema: add schema/...`", but Task 2 (line 167), Task 6 (line 278),
  the objective, and the `<done>` all say the six tasks land as ONE Wave-0 commit. An executor
  following Task 1 literally would create an intermediate commit that is RED (Task 1 alone does not
  clear the 3 content hits — the plan's own `<done>` acknowledges this). **Fix:** change Task 1's
  "After the edit, commit" to "Do NOT commit yet — lands with Task 6" to match Task 2's wording.
  (Independently raised by Codex.)

- **MEDIUM — basename scan uses raw substring of spaced denylist terms; misses slugified
  multi-word terms.** Task 6 step 2 says "match the file's relative path string against `terms`"
  using the same spaced denylist. Verified the denylist contains multi-word entries (`prospect
  theory`, `loss aversion`, `system 1`, `thinking fast and slow`, `decision fatigue`) that appear
  in filenames as slugs (`prospect-theory.md`, `loss-aversion.md`). A spaced-term substring scan
  catches single-word `kahneman` but would NOT catch `prospect-theory.md`. **Latent, not a current
  leak** — such files live under `examples/`, which is pruned from check-neutrality.sh PUBLIC_PATHS,
  and the current schema/reference basenames are abstract. But the Task 6 `<done>` claims "any
  FUTURE denylisted filename under a public path fails," which overstates coverage for multi-word
  terms. **Fix:** normalize the path string (also test hyphen/underscore→space variants) before
  matching, or note the spaced-term limitation explicitly. (Independently raised by Codex.)

- **LOW — `SANCTIONED_PATH_RE` reuse on path names is broader than needed.** Since top-level
  `examples/` is not in check-neutrality.sh PUBLIC_PATHS, the `examples/kahneman/...` line-strip is
  effectively dead for the path-name check. Harmless, but the plan could anchor the path-name
  sanction tightly rather than reuse the content regex. (Codex.)

- **LOW — no negative fixture for the new basename scanner.** The plan's verification proves the
  current tree is clean (exit 0) but does not add a test that creates a denylisted filename under a
  public path and asserts exit 2 (plus the exempted DR path → exit 0). Without it, a future
  regression of the basename check would go unnoticed. (Codex.)

- **LOW — Task 6 `<done>` overclaims durability.** Says "any FUTURE denylisted filename under a
  public path fails the gate" — true only for single-word terms given the substring design (see
  MEDIUM #2). Tighten the claim or the implementation.

### 5. Risk Assessment — LOW-to-MEDIUM

Both execution-blocking HIGHs are fully and verifiably resolved; the gate is empirically reachable
to exit 0, and the durability root cause is fixed. Residual risk is the Task 1 commit-instruction
contradiction (could produce a transient red commit if followed literally) and the multi-word
basename-scan gap (latent, not a current leak). Neither requires rethinking the extraction; both are
small edits for the next replan. Risk is LOW for correctness of the resolved HIGHs, MEDIUM only
because of the commit-order ambiguity.

---

## Codex Review

**Summary** — The two cycle-3 HIGH concerns are resolved by the cycle-4 Wave 0 plan as written: the
neutrality gate is pre-cleared with durable exemptions, and filename scanning is added with a narrow
exemption for the one historical DR. I do see plan-quality issues, but none rises to HIGH.

**Cycle-3 HIGH Disposition**

1. **FULLY RESOLVED** — `bin/check-neutrality.sh` red on current committed tree.
   Tasks 3–5 cover all three known hits using the existing `neutrality_exempt: true` mechanism, and
   Task 4 fixes the root cause by adding the exemption to the `bin/lint.sh` generated report template
   as well as the current report. The final verification includes both `check-neutrality.sh` exit 0
   and a post-lint regeneration check, so the asserted end state is reachable and durable.

2. **FULLY RESOLVED** — filename-level neutrality leak.
   Task 6 adds path-name scanning and a single exact `PATH_NAME_EXEMPT` for
   `wiki-cloud/decisions/dr-2026-04-15-kahneman-to-examples.md`. Given the ground-truth fact that no
   other denylisted basenames exist under `PUBLIC_PATHS`, this closes the known leak without
   broadening the exemption.

**New Concerns**

- **MEDIUM** — Task 1 still says "After the edit, commit," contradicting the later requirement that
  all six tasks land as one Wave-0 commit. Remove that Task 1 commit instruction or replace it with
  "Do not commit until Task 6." Otherwise an executor could create an intermediate red commit.

- **MEDIUM** — The proposed filename scan appears to use raw substring matching. That catches
  `kahneman`, but may miss slugified forms of multi-word denylist entries such as `loss-aversion.md`,
  `prospect-theory.md`, or `system-1.md` if only the spaced phrase is denylisted. Normalize path text
  by checking both raw and hyphen/underscore-to-space variants.

- **LOW** — Reusing `SANCTIONED_PATH_RE` on path names is broader than needed. Since top-level
  `examples/` is pruned from `PUBLIC_PATHS`, path-name scanning should not need the line-level
  `examples/kahneman/...` scrub, or it should anchor it tightly to the sanctioned top-level path.

- **LOW** — The verification proves current cleanliness but lacks a negative fixture for the new
  filename scanner. Add a temporary/public-path test that creates a denylisted filename and confirms
  exit 2, plus the exact exempted DR path confirms exit 0.

**Risk Assessment** — **MEDIUM**. The execution-blocking HIGHs are resolved, but the Wave 0 plan
still has one commit-order ambiguity and one real future-coverage gap in filename normalization.

**Unresolved HIGH count this cycle: 0**

---

## Consensus Summary

Both reviewers independently agree that **both cycle-3 HIGHs are FULLY RESOLVED**. Claude
additionally provided an empirical proof: applying the 3 frontmatter exemptions to a clean
`git archive HEAD` tree drives `bin/check-neutrality.sh` to **exit 0**, and a simulated basename
scan confirms ZERO other denylisted basenames (so Task 6's single-entry exemption is exact and
non-spurious). All structural claims in the plan were verified against the live repo: the
`neutrality_exempt` precedent is real and honored by the scanner; the `bin/lint.sh` report template
is at the exact line the plan targets; the cycle-2 fixes (init-wizard flags, §3 bullet present in
AGENTS.md / absent from template, fixture in `files_modified`) still hold.

Both reviewers independently surfaced the **same two MEDIUM findings** (Task 1 commit-instruction
contradiction; multi-word slugified basename-scan gap) and overlapping LOWs. None rises to HIGH.

### Agreed Strengths

- The `neutrality_exempt` remedy uses an established, scanner-honored precedent (3 prior in-repo
  uses) rather than inventing a new mechanism — and is the reviewers' preferred "make the gate green
  first" remedy over weakening the downstream assertions.
- Task 4(a) fixes the durability ROOT CAUSE by patching the hardcoded lint-report template inside
  `bin/lint.sh`, so 16-04's `bin/lint.sh --ci` cannot re-wipe the exemption — closing the recurring
  12.1-style regression.
- Task 6's basename scanning closes the filename leak with a single exact-path exemption and ZERO
  spurious failures on the current tree (empirically confirmed).
- The cycle-3 MEDIUM (E.3 resident/extracted conflation) and LOW (F.5 scoping) carry-overs are both
  addressed in 16-04 with explicit "cycle-3 fix" annotations.

### Agreed Concerns (both reviewers — MEDIUM, non-blocking)

1. **[MEDIUM] Task 1 commit-instruction contradicts the single-Wave-0-commit rule.** Line 135 says
   "After the edit, commit"; everywhere else says land all six as one commit. Following Task 1
   literally yields an intermediate RED commit (Task 1 alone does not clear the content hits).
   **Fix:** align Task 1 to "do not commit until Task 6."

2. **[MEDIUM] Basename scan uses spaced-term substring matching; misses slugified multi-word
   terms.** `prospect theory` in the denylist won't match `prospect-theory.md`. Latent (such files
   live under the pruned `examples/`; current schema basenames are abstract), but the Task 6 `<done>`
   overclaims "any future denylisted filename fails." **Fix:** normalize path text to also test
   hyphen/underscore→space variants, or scope the durability claim to single-word terms.

### Divergent Views

Minor severity-framing nuance only: Codex rates overall risk MEDIUM; Claude rates it LOW-to-MEDIUM
(LOW for correctness of the resolved HIGHs, MEDIUM only for the commit-order ambiguity). Same
remediation set; same disposition on both HIGHs (fully resolved) and both MEDIUMs. No material
disagreement.

### Unresolved HIGH count this cycle: 0

Both cycle-3 HIGHs are FULLY RESOLVED (repo-verified; empirical exit-0 proof). The cycle-4 revisions
introduce no new HIGH. Remaining items are 2 MEDIUM + 3 LOW polish findings for the next replan.
