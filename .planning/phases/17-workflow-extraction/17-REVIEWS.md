---
phase: 17
reviewers: [codex]
reviewed_at: 2026-06-05
review_cycle: 2
plans_reviewed: [17-01-PLAN.md, 17-02-PLAN.md, 17-03-PLAN.md, 17-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 17 (Cycle 2)

> Reviewer set: Codex (independent) + orchestrator direct repo verification. Claude
> self-review skipped for independence (orchestrated from inside Claude Code).
> This is CYCLE 2: the plans were revised to address the 4 cycle-1 HIGH consensus
> concerns. Every verdict below was re-checked against the revised plan text AND the
> live repo (CLAUDE.md L-anchors, bin/lint.sh structure, check-neutrality regex).

## Cycle-1 HIGH Resolution Audit

| # | Cycle-1 HIGH | Verdict | Evidence |
|---|--------------|---------|----------|
| 1 | Self-contradicting §N grep + 14 unrepointed Phase-16 back-links (unified §N policy) | **RESOLVED** | All headers/footers across Plans 01–03 now use DISPATCH wording ("The AGENTS.md routing table points here" / "routing-table stub") with NO `§N` token. Plan 03 adds a NEW **Task 0** repointing all 14 Phase-16 back-links (verified: `grep -rnE '§[0-9]\|Section [0-9]' schema/` returns 14 today, Task 0 worklist enumerates every one) + a **Task 4 CORE SWEEP** converting the 4 residual resident-core refs (§1 L30/L32, §2 L67/L98 — confirmed those are the only resident survivors before §9). Binding gate is the WHOLE-FILE `! grep -qE '§[0-9]' CLAUDE.md` + `! grep -qE '\bSection [0-9]' CLAUDE.md` assertion — total-coverage, cannot pass with any survivor. Plan 04's routing rule is now "DEAD SIMPLE: any `§[0-9]`/`\bSection [0-9]` → error" with NO {1,2,3} exemption. |
| 2 | Duplicate "Source of truth for Phase 9 / Phase 12.2 CI" string (Plan 03) | **RESOLVED** | Confirmed the phrase appears exactly 1× in CLAUDE.md today (L571). Plan 03 Task 1 PARAPHRASES the banner ("This file is the authoritative specification for the CI + local-gate contracts") and keeps the verbatim phrase ONCE in the relocated L571 body block; acceptance asserts `grep -c '...' == 1`. |
| 3 | Two authoritative solo-op log shapes (compact core vs multi-line §12) | **PARTIALLY RESOLVED** | Plan 01 declares ONE canonical shape (multi-line in `log-format.md`) and labels the compact 2-line core form a "dispatch summary … NOT a second standard" inline in core — this resolves the core-level two-canonical contradiction. BUT Plan 01 L302 explicitly promises "Plan 03's `log-format.md` extraction adds a **reciprocal note** that the compact core shape is a summary of the canonical entry," and Plan 03 Task 3 (the log-format.md task) contains **no such instruction**. The reconciliation is half-wired: core states it, log-format.md never points back. Documentation-completeness gap, not a return of two canonical shapes — but the promised fix is incompletely specified. |
| 4 | Plan 04 routing impl risks (destructive checkout, docs/reference known-set, exit-0 proof) | **RESOLVED** | (a) Destructive `git checkout` replaced with `mktemp -d` temp-copy negative test (Task 1 acc. L203) — verified `release.md` is untracked when Plan 04 runs, so this was a real hazard. (b) Targets resolved via `os.path.isfile(os.path.join(REPO_ROOT, target))`, no hard-coded known set (L146–150) — docs/reference/*.md no longer false-error. (c) Inverse/drift tests inspect `--format json` (L201, L313); orchestrator-confirmed only error-severity drives exit-1 (bin/lint.sh L2457/L2583), so warning/info paths correctly need JSON. (d) MEDIUMs also addressed: `remap_ci_severity(sev,cat,msg)` helper (not inline prefix), baseline-after-insertion ordering, mandatory inline justifications, `wiki-cloud/log.md` entry + validate-op, wizard dry-run in acceptance. |

**3 of 4 cycle-1 HIGHs FULLY RESOLVED; HIGH#3 PARTIALLY RESOLVED.**

## Codex Review (verbatim)

```
HIGH#1: RESOLVED — Plans 01-03 now use dispatch wording, add Task 0 for Phase-16 back-links, add a core sweep, and gate on zero §N / Section N.
HIGH#2: RESOLVED — Plan 03 paraphrases the banner and preserves the exact `Source of truth for Phase 9 / Phase 12.2 CI` string once in the relocated body with count == 1.
HIGH#3: PARTIALLY-RESOLVED — Plan 01 labels the compact core form as a dispatch summary, but Plan 03's log-format.md task does not actually add the promised reciprocal note, and the core still says solo ops "log … as" the compact form.
HIGH#4: RESOLVED — Plan 04 replaces destructive checkout with temp-copy tests, resolves targets on disk, uses JSON assertions for warning/info findings, and adds remap_ci_severity().

NEW HIGH concerns:
HIGH: Plan 03 Task 4's "exactly one routing row" acceptance uses global grep -c "schema/workflows/$f.md" CLAUDE.md, but core stubs also reference those paths. This makes the assertion impossible once stubs plus routing-table rows coexist.
HIGH: Plan 04 inverse-orphan spec conflicts with its test. The implementation allows "routing table or any core stub arrow" to satisfy reachability, but the test only removes a routing-table row and expects ORPHAN; every extracted file also has a core stub arrow, so the test will not fire.
```

## Newly-Introduced HIGH Concerns (orchestrator-verified)

Both new HIGHs share ONE root cause: **the plans are internally inconsistent about whether a core "stub arrow" (`→ See \`schema/workflows/X.md\``) counts as a routing reference.** Plan 03 treats stub arrows as SEPARATE from routing-table rows (causing a duplicate count); Plan 04 treats stub arrows AS valid routing references (breaking its orphan test). Resolving that one ambiguity fixes both.

### NEW-HIGH-A — Plan 03 Task 4 "exactly one routing row" assertion is impossible to satisfy (phase-close blocker)

After extraction, EVERY one of the 8 extracted files is referenced **twice** in core: once by its §-stub arrow and once by its routing-table row. Verified against the plan text:
- §9 stub arrow → `schema/workflows/structured-operations.md` (Plan 01 L285) **+** routing-table row (Plan 03 L396) = 2
- §11.1/§11.2 stub arrows → ingest.md / query.md (Plan 02 L216/L226) **+** routing rows (Plan 02 L232-233) = 2 each
- §11.3–§11.7 stub arrows → lint/reflect/brownfield/release/audit.md (Plan 03 L382-386) **+** routing rows (Plan 03 L392-399) = 2 each
- §12 stub arrow → `schema/reference/log-format.md` (Plan 03 L387) **+** routing row (Plan 03 L400) = 2

Plan 03 Task 4 acceptance (L434) asserts `[ "$(grep -c "schema/workflows/$f.md" CLAUDE.md)" -eq 1 ]` for all 8 — this counts **2** for every file, so the verify block fails for all of them. The cycle-1 "bounded-table assertion (catches accidental duplicates)" fix over-tightened into an unsatisfiable check. **Fix:** count routing-table ROWS specifically (e.g. grep for the `| … | \`schema/workflows/X.md\` |` row form, or count occurrences within the routing-table line range only), not raw path occurrences across the whole core.

### NEW-HIGH-B — Plan 04 inverse-orphan test cannot fire (orphan-detection guarantee unverified)

Plan 04 Task 1 step 3 (L160-162) defines reachability as satisfied by "AGENTS.md's routing table **(or any core stub arrow)**." But the inverse-orphan acceptance test (L201) only "remove a workflow file's routing row from the copied AGENTS.md" — it leaves the §-stub arrow intact. Since every extracted file ALSO has a stub arrow pointing at it, deleting only the routing row does NOT orphan it, so the `ORPHAN` finding never fires and the test asserting `confirm the ORPHAN finding is present` FAILS (or vacuously finds nothing). The test that is supposed to PROVE orphan-detection works is therefore a false-negative the suite can't catch. **Fix:** make the spec + test agree — either (a) define reachability as routing-table-row ONLY (then the test must also delete the stub arrow to truly orphan a file — but note that then a missing stub arrow becomes the orphan signal, which couples to NEW-HIGH-A's definition), or (b) keep "table OR stub" reachability and rewrite the test to remove BOTH the routing row AND the stub arrow for the target file.

---

## Consensus Summary

The cycle-1 revisions are largely successful: the dominant cycle-1 blocker (unified §N-abolition + Phase-16 back-link repoint) is cleanly resolved across all four plans with a binding whole-file gate, the duplicate source-of-truth string is fixed (count==1), and all four Plan-04 routing implementation risks are addressed with verified, non-destructive, JSON-asserted tests. **3 of 4 cycle-1 HIGHs are fully resolved.**

However, cycle 2 surfaces **3 remaining HIGHs**: cycle-1 HIGH#3 is only PARTIALLY resolved (the promised reciprocal note in `log-format.md` was never written into Plan 03 Task 3), plus **2 newly-introduced HIGHs** — both rooted in a single unresolved ambiguity about whether a core stub arrow counts as a "routing reference." That ambiguity makes Plan 03's one-routing-row acceptance unsatisfiable (NEW-HIGH-A, a phase-close blocker) and makes Plan 04's orphan-detection test unable to fire (NEW-HIGH-B).

### Agreed Strengths
- Unified §N policy is now encoded identically in every header, footer, body-conversion step, acceptance grep, and the routing-guard pattern (cycle-1's load-bearing fix landed cleanly).
- Plan 03 Task 0 (repoint the 14 Phase-16 back-links) is the right prerequisite, sequenced before Plan 04's guard — verified the 14 refs exist today and the worklist covers all of them.
- Plan 04's `remap_ci_severity(sev,cat,msg)` helper generalizes the real `matches_skip('EXTERNAL: ')` precedent (bin/lint.sh L348) — sound, testable, correctly targeted at the L2396-2398 CI-remap site.
- Resolve-on-disk routing-target check (`os.path.isfile`) correctly avoids the docs/reference false-error class.
- All invoked scripts exist (init-wizard.sh --dry-run, validate-op.sh, check-privacy.sh, check-neutrality.sh); examples/kahneman neutrality exemption regex confirmed at check-neutrality.sh L169.

### Agreed Concerns (highest priority — all verified)
1. **[HIGH, NEW-A] Plan 03 Task 4 one-routing-row assertion is unsatisfiable** — counts stub-arrow + routing-row = 2 for all 8 files; phase-close blocker. Count routing-table rows specifically.
2. **[HIGH, NEW-B] Plan 04 inverse-orphan test can't fire** — spec says "table OR stub arrow" reachable, test removes only the row; orphan-detection guarantee goes unverified. Align spec + test (delete both, or define reachability as row-only and have the test delete the stub).
3. **[HIGH, carried #3] Plan 03 Task 3 never adds the reciprocal log-shape note** that Plan 01 L302 promises; the canonical/summary reconciliation is one-directional. Add the reciprocal pointer in `log-format.md`.

### Divergent Views
- None. Single external reviewer (Codex); every Codex verdict was independently reproduced by the orchestrator against the plan text and live repo. One orchestrator nuance on HIGH#3: the CORE-level "two canonical shapes" contradiction IS resolved by Plan 01; the residual is the missing reciprocal note in log-format.md — classified PARTIALLY RESOLVED (counts as unresolved per the cycle contract) because the originally-promised fix is incompletely specified.

### Recommended next step
Feed this review back into planning:

```
/gsd-plan-phase 17 --reviews
```

All three remaining HIGHs are localized and mechanical. The load-bearing fix is to **pick one definition of "routing reference"** (recommend: the routing-TABLE row is the canonical reachability anchor; stub arrows are convenience pointers and do NOT count toward the one-row invariant) and encode it identically in Plan 03's one-row acceptance grep AND Plan 04's orphan spec+test. Then add the one-line reciprocal note to Plan 03 Task 3's log-format.md action.
