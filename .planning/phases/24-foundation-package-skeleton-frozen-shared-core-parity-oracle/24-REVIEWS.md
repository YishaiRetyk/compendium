---
phase: 22
reviewers: [claude, codex]
reviewed_at: 2026-06-18T17:30:00Z
plans_reviewed:
  - 24-01-package-skeleton-and-schema-edit-PLAN.md
  - 24-02-common-core-over-extraction-PLAN.md
  - 24-03-parity-seam-and-pytest-harness-PLAN.md
  - 24-04-characterization-backfill-and-antisignal-PLAN.md
  - 24-05-ci-wiring-and-parity-matrix-PLAN.md
  - 24-06-freeze-guard-and-baseline-pin-PLAN.md
cycle: 5
prior_cycle_high: 5
current_high: 6
---

# Cross-AI Plan Review — Phase 24 (Foundation: Package Skeleton + Frozen Shared Core + Parity Oracle) — CONVERGENCE CYCLE 5

Two independent reviewers (Claude CLI separate session, Codex CLI / gpt-5.5) re-reviewed all 6 plans after the cycle-4→cycle-5 revision (`docs(22): replan to resolve 5 cycle-4 HIGH review concerns`, commit `f69084d`) that was meant to close the 5 localized single-defect HIGH concerns from cycle 4. **The two reviewers converge — independently and tightly — on the same outcome: all 5 cycle-4 HIGH areas remain PARTIALLY RESOLVED, plus the cycle-5 revision introduced one NEW HIGH regression. Both reviewers report an unresolved count of 6, both rate overall risk HIGH.** The HIGH-count trend, which had been 12 → 7 → 5 → 5, **rose to 6 this cycle** — not because the fixes regressed in shape (each is genuinely improved and several sub-defects are now fully closed), but because the revision that pinned the fixes simultaneously **froze the two surfaces those fixes need to modify**.

The decisive new finding, raised independently by both reviewers and adjudicated valid against the source: **the cycle-5 revision added `tests/run-all-suites.sh` and `tests/lib/invoke_tool.sh` (the parity seam) to the explicit frozen surface (Plan 06:148, 154), while Plan 06's own tasks require modifying their interfaces** — a dual `STAGED_EXEC_ROOT`/`ORACLE_GIT_ROOT` root split in the seam (concern #4) and a caller-supplied suite-exclusion knob in the runner (concern #5). An executor following the plans literally either freezes the files and finds the staged-parity gate unbuildable, or edits them and trips `check-common-freeze.sh`. The two fixes the revision was meant to land are mutually exclusive with the freeze the same revision declares.

Several sub-defects ARE genuinely closed this cycle and should be credited: the gen-skills exit-1 drift golden is now mandatory (Plan 04:218); the within-process capture-key collision is fixed by the `<testbasename>-<pid>-<NN>` key with a pre-fix-failing two-subprocess test (Plan 03:315-319, 427); the negative staged-parity test now seeds a temporary `ported.manifest` entry so the py leg genuinely runs (Plan 06:272); the shim-smoke test correctly clears the seam `PYTHONPATH` and asserts a bootstrap-free shim fails (Plan 03:433). The residual in each area is now a single, sharper defect than cycle 4 — but each area still carries at least one.

Load-bearing source facts re-confirmed by both reviewers against the live tree: `bin/audit-claims.sh:123`, `bin/brownfield.sh:730`, `bin/gen-skills.sh:30-31` match as cited; the seam binds a **single `REPO_ROOT`** to BOTH the py-lane shim/`PYTHONPATH` AND the oracle's `git -C "$REPO_ROOT" worktree add` (Plan 03:328/337 vs the oracle git calls) — there is no per-lane root knob; Plan 05 defines **no** `--exclude-suite` / `WIKI_PARITY_SUITES` interface (it hard-codes the enumerated list `09 09.1 10 11 12.1 12.2 13 15 18 20 22`); 86 invocations across the parity suites pass fixtures via `--root "$tmp"` without `cd`-ing, so `capture_footprint "$PWD"` snapshots the wrong tree for them.

---

## Claude Review

I verified load-bearing claims against the live repo: `bin/audit-claims.sh:123`, `bin/brownfield.sh:730`, `bin/gen-skills.sh:30-31` all confirmed as cited; `tests/run-all-suites.sh` and `tests/phase-24/` do not yet exist (created by Plans 05/04); the existing `run.sh` aggregators iterate `test_*.sh` by glob. The decisive finding this cycle is **structural, not cosmetic**: the cycle-5 revision froze `run-all-suites.sh` and `tests/lib/invoke_tool.sh` as immutable surface (Plan 06:148-154) while Plan 06 simultaneously requires *modifying their interfaces* (a suite-exclusion knob; a dual-root split). That contradiction blocks two of the five fixes from being implementable as specified.

### Per-concern disposition (the 5 cycle-4 HIGHs)

#### Concern 1 — Routed-suite capture (key collision + live byte-cmp + per-tool coverage) → **PARTIALLY RESOLVED**
The within-process collision is genuinely fixed: the capture key is now `$IT_CAPTURE_DIR/<testbasename>-<pid>/<tool>-<NN>` (Plan 03:347, `_it_capture_key` at 315-319), and `test_capture_dir.sh` step 2 proves two distinct test-file subprocesses' first `lint` call land in distinct keyed dirs (Plan 03:427) — that pre-fix-failing assertion is real. The live-path divergence test (`test_routed_parity_divergence.sh`, Plan 05:215-219) and per-routed-tool coverage assertion (Plan 05:218) are concrete and correctly reject the comparator stub.

**But the cross-run matching is broken by the very fix.** The key embeds the process PID (`$$`). The two `--capture-channels` runs (one `WIKI_IMPL=bash`, one `WIKI_IMPL=py`) execute in *different processes*, so the `<testbasename>-<pid>` segment differs between the bash capture tree and the py capture tree. `--require-parity` "walks the keyed channel sub-dirs ... for EACH keyed routed call" (Plan 05:200) with **no specified pid-normalization or key-alignment step**. As written, corresponding bash/py invocations sit under non-matching top-level keys, so the byte-comparison either finds no pairs to compare (vacuous green) or must guess the pairing. The pid that solves the intra-run overwrite reintroduces a cross-run alignment gap. Concern 1 is not closed.

#### Concern 2 — init-wizard: gen-skills drift golden required + shim-level exit-3 contract → **PARTIALLY RESOLVED**
The gen-skills sub-defect is genuinely closed: the drift golden is now mandatory and asserts exit 1 (Plan 04 hashlib/gen-skills task). The exit-3 half added a real new test, `tests/phase-24/test_shim_preflight_exit3.sh` (Plan 04:290-318), with a sound pre-fix-failing design (strip python3, assert rc==3, assert the bare-bootstrap variant returns 127 not 3). **The residual:** the test exercises a *synthetic shim-shaped wrapper authored inside the test* (Plan 04:300-311), explicitly preferred over driving the real `bin/init-wizard.sh`. It proves the *template* preserves exit 3, but a future real Phase-23 `bin/init-wizard.sh` shim that omits the preflight gate would not be caught by this test — it tests a wrapper the test itself writes, not the shipped artifact. The contract is documented and demonstrated but not bound to the real shim. Materially narrower than cycle 4, but not fully enforced.

#### Concern 3 — py-via-shim: shim-smoke with seam PYTHONPATH cleared → **PARTIALLY RESOLVED**
The mechanism is correct and the test is well-designed: `test_shim_smoke.sh` runs with the seam PYTHONPATH unset (Plan 03:433), asserts a canonical-bootstrap shim passes (step 3), a bootstrap-free shim fails with ModuleNotFoundError (step 4 — the pre-fix-failing assertion), and a wrong-module shim is caught (step 5). This genuinely catches the cycle-4 masking defect. **The residual** (correctly flagged by Codex): the test proves the *property* on a fabricated `faketool` scaffold (Plan 03:432) — it does not inspect or execute each *actual* manifest-listed shim with the masking env cleared. In Phase 24 the manifest is empty so there is nothing to enforce against yet, but the contract that "every ported shim owns its bootstrap" is demonstrated by example rather than enforced per-shim. Acceptable for a foundation phase, but it is a real "specified by exemplar, not enforced over the population" gap — partial, not full.

#### Concern 4 — staged-index: STAGED_EXEC_ROOT / ORACLE_GIT_ROOT split + negative test seeds manifest+broken module → **PARTIALLY RESOLVED (new structural blocker)**
The negative test is genuinely strengthened: it seeds a temporary `ported.manifest` entry so the py leg actually runs, stages a divergent body, and leaves a passing unstaged copy, asserting the commit is BLOCKED (Plan 06:272). That correctly closes the "empty manifest → vacuous py leg" and "tests working tree not index" sub-defects.

**But the split is not implementable through the frozen seam.** I verified the seam binds a **single `REPO_ROOT`** to *both* the py-lane tool body (`bash "$REPO_ROOT/bin/${tool}.sh"`, `PYTHONPATH="$REPO_ROOT/src"`, Plan 03:328/337) *and* the oracle's git commands (`git -C "$REPO_ROOT" worktree add`). Plan 06 needs the py tool bodies to come from `STAGED_EXEC_ROOT` (the materialized index, **no `.git`**) while git resolution runs against `ORACLE_GIT_ROOT` (the real repo). There is **no per-lane root knob** in the seam. Plan 06 itself freezes `tests/lib/invoke_tool.sh` (Plan 06:148) and leaves the wiring as a bare `<staged-tool-bodies-from-STAGED_EXEC_ROOT>` placeholder (Plan 06:259). You cannot set one `REPO_ROOT` to two values, and the file that would need the second knob is frozen and absent from Plan 06's write set. The concern's *shape* is right and well-documented (Plan 06:256), but the fix as specified cannot be built without editing a frozen surface — so it is not resolved.

#### Concern 5 — self-test recursion: exclude hook self-test from gate fallback (non-vacuous) → **PARTIALLY RESOLVED (same structural blocker)**
The intent is correct: exclude phase-24 from the gate's fallback so the recursion breaks AND the "RUNS the parity path" assertion stays non-vacuous (Plan 06:258), with the `WIKI_PARITY_GATE_ACTIVE` guard demoted to belt-and-suspenders (Plan 06:251). The bounded-termination test (`timeout 120`, assert rc 0 not 124, Plan 06:274) and the parity-path-executes assertion (Plan 06:267, 275) are concrete and pre-fix-failing.

**But the exclusion interface does not exist and cannot be added.** I confirmed Plan 05 defines **no** `--exclude-suite` flag or `WIKI_PARITY_SUITES` override — it hard-codes the enumerated list `09 09.1 10 11 12.1 12.2 13 15 18 20 22` into `run-all-suites.sh` and treats it as authoritative (Plan 05:184, 208). Plan 06:240 instructs the executor to "CONFIRM/USE the suite-EXCLUSION mechanism ... if Plan 05 did not add one, the gate passes an explicit suite list OMITTING 22" — but `run-all-suites.sh` has no documented parameter to accept a caller-supplied list, and it is frozen (Plan 06:154) and absent from Plan 06's write set. The fix depends on an interface that neither plan provides and the freeze forbids adding. Not resolved.

### New HIGH concerns

**NEW-HIGH-1 — Freeze/interface deadlock between Plan 05 and Plan 06.** This is the cycle-5 regression and the root cause of concerns 4 and 5 staying open. The cycle-5 revision added `tests/run-all-suites.sh` and `tests/lib/invoke_tool.sh` to the explicit frozen surface (Plan 06:148, 154) — but Plan 06's own tasks require *modifying their interfaces* (a dual `STAGED_EXEC_ROOT`/`ORACLE_GIT_ROOT` root split in the seam; a suite-exclusion knob in the runner). An executor following these plans literally will either (a) freeze the files and find the staged-parity gate unbuildable, or (b) edit them and trip `check-common-freeze.sh`. The two fixes the revision was meant to land are mutually exclusive with the freeze the same revision declares. This needs an explicit resolution: add the two knobs (per-lane root override in the seam; caller-supplied suite list in the runner) *before* the freeze snapshot, and document them as part of the frozen contract surface — not as post-freeze edits.

I do **not** count Codex's "excluding the entire phase-24 suite removes the richest goldens" as a separate standalone new HIGH: it is a real risk but it is the *symptom* of NEW-HIGH-1 (the absent exclusion interface forces an all-or-nothing exclusion). The correct remedy — exclude only the recursive hook self-test, or add a nested-test mode — is exactly what a proper exclusion interface enables, so I fold it into NEW-HIGH-1 rather than double-count.

### MEDIUM / LOW (Claude)
- **MEDIUM** — per-tool coverage (Plan 05:218) can be satisfied by any captured invocation, including a shallow `--help`/usage path; behavioral-case adequacy per routed tool is not required. Coverage could be present-but-hollow.
- **MEDIUM** — `tests/oracle-exempt.md` is prose while capture identities are `<tool>-<counter>` dirs; there is no machine-readable mapping from a captured call to its exemption, so `--require-parity`'s exempt-skipping (Plan 05:201) relies on ad-hoc path matching.
- **LOW** — `capture_footprint "$PWD"` (Plan 03:348) assumes cwd is the fixture; tests that pass fixtures via `--root` without `cd` would snapshot the wrong tree. Likely fine for the routed suites but unasserted.

### Risk Assessment (Claude)
**Overall: HIGH.** Four of five cycle-4 concerns have a genuinely improved, well-tested mechanism, and two sub-defects (gen-skills golden; within-process capture collision) are fully closed. But concerns 4 and 5 are blocked by a real internal contradiction introduced this cycle (the freeze-vs-interface deadlock), and concern 1's cross-run key alignment is unspecified. These are not "the fix is gestured" — they are "the fix is specified against a surface the same plan froze." One more focused pass that (a) adds the two interface knobs pre-freeze, and (b) specifies pid-independent cross-run key alignment, should converge.

### Disposition table (Claude)

| Cycle-4 concern | Disposition |
|---|---|
| 1. Routed capture — key collision / live byte-cmp / per-tool coverage | PARTIALLY RESOLVED |
| 2. init-wizard — gen-skills golden + shim exit-3 contract | PARTIALLY RESOLVED |
| 3. py-via-shim — bootstrap caught with seam PYTHONPATH cleared | PARTIALLY RESOLVED |
| 4. staged-index — STAGED_EXEC_ROOT/ORACLE_GIT_ROOT split | PARTIALLY RESOLVED |
| 5. self-test recursion — exclude hook self-test from fallback | PARTIALLY RESOLVED |
| NEW: Plan 05↔06 freeze/interface deadlock | NEW HIGH |

5 partially resolved + 0 unresolved + 1 new HIGH.

**Unresolved HIGH count this cycle (Claude): 6**

---

## Codex Review

### HIGH findings

#### 1. Routed capture remains internally inconsistent — **PARTIALLY RESOLVED**
The overwrite fix keys captures by `<testbasename>-<pid>` (Plan 03:315), while parity compares keyed directories from separate bash and py runs (Plan 05:200). Their PIDs necessarily differ, so corresponding invocations have different paths. The test's `IT_CAPTURE_KEY` override can mask this production defect.

Additionally, `capture_footprint "$PWD"` assumes cwd is the fixture (Plan 03:346), but existing tests commonly pass fixtures via `--root` without changing cwd (`tests/phase-10/test_brownfield_scan_confidence.sh:15`). Result-tree divergences can therefore be missed.

The required live-path test is also ambiguous: run-all has a hard-coded suite list (Plan 05:184), yet the test may bypass it by invoking the throwaway suite "the same way run-all does" (Plan 05:216).

#### 2. Init-wizard/gen-skills paths — **PARTIALLY RESOLVED**
The gen-skills drift golden is now mandatory and concretely asserts exit 1 (Plan 04:218). That sub-defect is fully closed.

However, exit-3 enforcement tests a synthetic "shim-shaped wrapper" (Plan 04:300), explicitly preferring it over the real shim (Plan 04:311). A future real `bin/init-wizard.sh` can omit the preflight while this test remains green.

#### 3. Shim-owned PYTHONPATH bootstrap — **PARTIALLY RESOLVED**
The normal lane still injects `PYTHONPATH` (Plan 03:337). The new test uses a fake shim in an isolated scaffold and may run it directly (Plan 03:431, 433). That proves the proposed template, but does not inspect or execute each actual manifest-listed shim with the masking environment cleared. A real bootstrap-free shim can still pass parity.

#### 4. Staged-index/root split — **PARTIALLY RESOLVED**
The plan now names `STAGED_EXEC_ROOT` and `ORACLE_GIT_ROOT` and seeds the manifest in the negative test (Plan 06:253, 272). But the frozen seam still derives all three functions from one `REPO_ROOT` — py shim (Plan 03:328), manifest lookup (same root), Python path (Plan 03:337). Plan 06 merely contains a `<staged-tool-bodies-from-STAGED_EXEC_ROOT>` placeholder (Plan 06:259), while the seam is frozen (Plan 06:148). The split is therefore not implementable through the specified interface.

#### 5. Recursion/self-test conflict — **PARTIALLY RESOLVED**
Excluding phase 22 is a plausible recursion break (Plan 06:258). However, Plan 05 defines no `--exclude-suite` or `WIKI_PARITY_SUITES` interface; it mandates a fixed suite list. Plan 06 cannot add the interface because `tests/run-all-suites.sh` is frozen and absent from its write set (Plan 06:154). The acceptance currently checks only exclusion-related text, not functioning runner behavior.

### New HIGH (Codex)
Excluding the entire phase-24 suite removes the richest characterization goldens from the only gate that runs on private migration branches. Plan 05 explicitly calls phase 22 the richest four-channel suite (Plan 05:40); Plan 06 says CI never runs on those branches, then excludes all of phase 22 (Plan 06:249, 258). Exclude only the recursive hook tests, or add a dedicated nested mode — not the whole characterization suite.

### MEDIUM (Codex)
- Per-tool coverage can be satisfied by any captured invocation, including a shallow usage/help path; behavioral case adequacy is not required (Plan 05:218).
- `oracle-exempt.md` is prose, while capture identities are tool/counter directories; no machine-readable mapping from a captured call to exemption is specified.

### Disposition table (Codex)

| Cycle-4 concern | Disposition |
|---|---|
| 1. Routed capture/keying/live comparison | PARTIALLY RESOLVED |
| 2. Init-wizard/gen-skills compatibility paths | PARTIALLY RESOLVED |
| 3. Shim PYTHONPATH bootstrap enforcement | PARTIALLY RESOLVED |
| 4. Staged-index Git-context split | PARTIALLY RESOLVED |
| 5. Recursion vs meaningful self-test | PARTIALLY RESOLVED |

No cycle-4 HIGH is fully resolved.

**Unresolved HIGH count this cycle (Codex): 6** — five partially resolved carried concerns + one new HIGH regression.

### Risk Assessment (Codex)
**Overall: HIGH.**

---

## Consensus Summary

Both reviewers, independently, reach the **identical** outcome: **all 5 cycle-4 HIGH areas remain PARTIALLY RESOLVED, plus 1 NEW HIGH = 6 unresolved, risk HIGH.** This is unusually tight convergence — they agree not just on the count but on the per-concern disposition and, critically, on the same root cause for the two hardest residuals (concerns 4 and 5): **the cycle-5 revision froze the two surfaces (`run-all-suites.sh` and the `invoke_tool` seam) that the same revision's fixes need to modify.** The orchestrator independently verified every load-bearing claim against the live tree (single-`REPO_ROOT` seam; no `--exclude-suite`/`WIKI_PARITY_SUITES` interface in Plan 05; 86 `--root`-without-`cd` invocations; the `$$`-keyed capture dir) — all hold.

The trend rose 5 → 6, but this is a *narrowing* story, not a regression in fix quality: each of the 5 carried concerns is now a single, sharper, source-pinned defect (and two sub-defects are fully closed — the mandatory gen-skills golden and the within-process capture-collision fix). The added HIGH is the freeze-vs-interface deadlock the revision introduced, which is the mechanism blocking concerns 4 and 5 from being buildable as written.

### Agreed Strengths (raised by both reviewers)
- The within-process capture-key collision is genuinely fixed: `<testbasename>-<pid>-<NN>` key (Plan 03:315-319) with a pre-fix-failing two-subprocess test (Plan 03:427) — distinct test files in one suite no longer overwrite each other.
- The gen-skills exit-1 drift golden is now mandatory and asserts exit 1 (Plan 04:218) — that cycle-4 sub-defect is fully closed.
- The negative staged-parity test now seeds a temporary `ported.manifest` entry so the Python leg genuinely runs (Plan 06:272), closing the "empty manifest → vacuous py leg" sub-defect.
- The shim-smoke test correctly clears the seam `PYTHONPATH` and asserts a bootstrap-free shim fails with ModuleNotFoundError (Plan 03:433) — the right mechanism for the masking defect.
- The exit-3 enforcement test is well-shaped (strip python3, assert rc==3, assert the bare variant returns 127) (Plan 04:290-318).

### Agreed Concerns (highest priority — both reviewers)
1. **[HIGH] Freeze/interface deadlock between Plan 05 and Plan 06 (NEW this cycle — both reviewers).** Plan 06 froze `run-all-suites.sh` and `tests/lib/invoke_tool.sh` (Plan 06:148, 154) but its own tasks need to change their interfaces — a per-lane `STAGED_EXEC_ROOT`/`ORACLE_GIT_ROOT` root split in the seam (concern #4) and a caller-supplied suite-exclusion knob in the runner (concern #5). The fixes and the freeze are mutually exclusive. *Fix:* add both knobs to the seam and runner BEFORE the freeze snapshot, and declare them part of the frozen contract surface.
2. **[HIGH] Staged-index split (#4) is unbuildable through the frozen single-`REPO_ROOT` seam (both reviewers).** The seam binds one `REPO_ROOT` to both the py tool body/`PYTHONPATH` and the oracle's `git worktree add`; Plan 06:259 leaves the wiring as a placeholder. *Fix:* give the seam a per-lane root override (exec-root vs git-root) pre-freeze.
3. **[HIGH] Self-test recursion exclusion (#5) depends on a suite-exclusion interface that does not exist (both reviewers).** Plan 05 hard-codes the suite list with no `--exclude-suite`/`WIKI_PARITY_SUITES` parameter; Plan 06 cannot add it to the frozen runner. *Fix:* add a caller-supplied suite-list / exclusion parameter to `run-all-suites.sh` pre-freeze, and exclude ONLY the recursive hook self-test (or a nested-test mode), not the whole phase-24 suite.
4. **[HIGH] Routed-capture cross-run key alignment (#1) is broken by the PID in the key (both reviewers).** The `$$`-bearing key disambiguates within a run but cannot pair the bash run's captures with the py run's captures (different PIDs); `--require-parity` specifies no pid-normalization. *Fix:* specify a pid-independent cross-run pairing (strip/normalize the pid segment, or key on suite+testbasename+counter only for the comparison walk). Also: `capture_footprint "$PWD"` misses tree divergences for the 86 `--root`-without-`cd` invocations.

### Single-reviewer HIGH framing (folded, not double-counted)
- Codex counts "excluding the entire phase-24 suite removes the richest goldens from the only gate on private branches" as its standalone NEW HIGH (Plan 05:40 vs Plan 06:249/258). Claude folds the SAME observation into NEW-HIGH-1 as the *symptom* of the absent exclusion interface (all-or-nothing exclusion). Either framing yields the same total of 6; the deduplicated count is **6** (5 carried partials + 1 new HIGH).

### Divergent Views
- **Almost none this cycle.** Both reach 6 / HIGH. The only difference is bookkeeping: Codex names the "whole-suite exclusion" as the discrete new HIGH; Claude names the "freeze/interface deadlock" as the new HIGH and treats the whole-suite exclusion as its consequence. These are two descriptions of one underlying defect (no exclusion interface → forced to drop the whole suite), so the counts agree at 6.
- **Trend read:** 12 → 7 → 5 → 5 → 6. The uptick is not a quality regression in the fixes — each carried concern narrowed to one sharp defect and two sub-defects closed outright — but the cycle-5 freeze introduced a genuine new blocker. Resolving the single freeze/interface deadlock (add the two knobs pre-freeze) directly unblocks concerns 4 and 5; the remaining residuals (concern #1 cross-run key alignment, concern #2/#3 exemplar-vs-population) are localized. One more focused pass should converge.

---

## Disposition for Replan

Cycle 5 closed two sub-defects (mandatory gen-skills golden; within-process capture collision) but left all 5 cycle-4 HIGH areas PARTIALLY RESOLVED and introduced one NEW HIGH (the freeze/interface deadlock). The fixes for concerns #4 and #5 are specified against surfaces the same revision froze, so they are not buildable as written. **All 6 are localized, single-defect fixes to Plans 03/04/05/06 — no re-architecture; the keystones (worktree oracle, `set -e` seam, freeze baseline) remain solid.**

1. **Freeze/interface deadlock (NEW HIGH).** Add the per-lane root override (seam) and the caller-supplied suite-exclusion knob (runner) to Plans 03/05 BEFORE the freeze snapshot in Plan 06; declare both as part of the frozen contract surface so Plan 06 consumes (not edits) them (Plans 03, 05, 06).
2. **Staged-index split (#4).** Implement the `STAGED_EXEC_ROOT` vs `ORACLE_GIT_ROOT` split via the new per-lane root override; replace the Plan 06:259 placeholder with the concrete wiring (Plans 03, 06).
3. **Self-test recursion (#5).** Use the new suite-exclusion interface to exclude ONLY the recursive hook self-test (or a nested-test mode), not the whole phase-24 suite; make the acceptance assert functioning runner behavior, not exclusion-related text (Plans 05, 06).
4. **Routed-capture cross-run alignment (#1).** Specify pid-independent cross-run pairing in `--require-parity`; fix `capture_footprint` to snapshot the real fixture root (not `$PWD`) for the `--root`-without-`cd` invocations (Plans 03, 05).
5. **Exit-3 contract (#2) and shim bootstrap (#3).** Bind the exit-3 preservation test and the shim-bootstrap-cleared-PYTHONPATH test to the real shipped shims (or document the per-shim enforcement that Phase 25 inherits), not only the synthetic exemplar (Plans 03, 04).

Feed this REVIEWS.md back into planning via `/gsd-plan-phase 22 --reviews`.

**Unresolved HIGH count this cycle: 6.**
