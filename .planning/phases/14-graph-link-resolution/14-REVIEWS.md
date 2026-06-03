---
phase: 14
reviewers: [gemini, codex]
reviewed_at: 2026-06-03T07:46:08Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md]
cycle: 3
---

# Cross-AI Plan Review — Phase 14 (Cycle 3, re-review)

> Re-review after the Cycle-2 replan. Two independent external reviewers (Gemini, Codex).
> Claude (self-CLI) was skipped for independence per the review workflow's self-CLI rule —
> this review session is itself running inside Claude Code. The orchestrator independently
> verified the load-bearing Codex finding against the plan files (see Consensus).
>
> Cycle-2 raised two HIGHs: (#1, orchestrator-confirmed) `--fix` `to_add` computed from
> stem-inclusive `reachable` so the id slug was never added for `id == filename` pages,
> breaking the LINK-02 literal invariant; (#2, spec-interpretation fork) Plan 03 widened
> `example: true` "not lint-enforced" into "not remediated", potentially missing LINK-09.
> This cycle assesses whether those are resolved AND hunts for regressions.

## Gemini Review

The Phase 14 implementation plans have converged to a high degree of technical rigor. Cycle 3 successfully resolves the two prior HIGH-severity concerns regarding the literal self-alias invariant and the remediation scope for example pages. The logic for `bin/lint.sh` now correctly distinguishes between graph reachability (the error trigger) and literal schema compliance (the `--fix` path), ensuring that pages are brought into full alignment with LINK-02 even when technically resolving. Remediation for `example: true` fixtures is explicitly addressed via hand-edits, closing the spec-interpretation gap. Defensive coding in `lint.sh` (isolated category calls, YAML-quoting) and comprehensive test coverage (10 cases including index/log scans and colon-title canaries) minimize the risk of regression or data corruption.

### 1. Cycle-2 HIGH Disposition

*   **HIGH #1 (`to_add` literal membership): RESOLVED.**
    *   **Evidence:** Plan 02, Change 6 (Subcheck A) explicitly separates `reachable` (which includes the `stem.lower()`) from `existing_lower` (which is literal alias membership). It then computes `to_add` against `existing_lower`:
        ```python
        existing_lower = {a.lower() for a in aliases}     # LITERAL membership
        # ...
        if title and title.lower() not in existing_lower:
            to_add.append(title)
        if pid and pid.lower() not in existing_lower:
            to_add.append(pid)
        ```
    *   This ensures the `id` slug is added even when `id == filename`, satisfying the literal requirement of LINK-02. The logic is verified by a dedicated regression canary in `tests/phase-09/test_lint_linkres.sh` (Test 9b).

*   **HIGH #2 (LINK-09 examples remediation): RESOLVED.**
    *   **Evidence:** Plan 03 (Objective) explicitly rules that "lint-skip means NOT-LINT-ENFORCED, not NOT-REMEDIATED." Task 1, Step 2b of Plan 03 provides a detailed hand-edit procedure for all 10 `example: true` dataview-fixture content pages, including a Python validation script to ensure they carry the literal self-alias.

### 2. Strengths
*   **Defensive Integration:** Plan 02, Change 6 builds the `obsidian_map` defensively inside the `linkres` block if it doesn't already exist. This prevents `NameError` crashes when the check is called in isolation via `--category linkres` (addressing Cycle-1 HIGH #1).
*   **Data Integrity:** The implementation of `_yaml_quote_alias` in Plan 02 and the corresponding canary tests in Plan 03 ensure that colon-bearing titles (common in decision records) do not corrupt the YAML frontmatter during `--fix` operations.
*   **Comprehensive Testing:** The 10-case test suite in `test_lint_linkres.sh` is excellent. It asserts through real JSON output (Test 3) rather than mock logic, and it covers the recently identified `index.md`/`log.md` body-link scan requirement (Test 10).
*   **Single-Writer Wave Discipline:** Plan 01 owns all `AGENTS.md` edits for the wave, while Plan 02 handles downstream `docs/` and code. This prevents the parallel-write hazards common in multi-agent environments.

### 3. Concerns
*   **None (HIGH/MEDIUM severity).** The plans are now fully aligned with the locked requirements and previous review feedback.
*   **LOW:** In Plan 03, Task 1, Step 6, the user must manually replace `<N_wiki>` and `<N_ex>` placeholders in the log. While a verification step is included to check for these markers, failing to do so would leave uninformative text in the permanent wiki log.

### 4. Suggestions
*   **Human Verification Nuance:** During the LINK-10 human-verify checkpoint in Plan 03, pay special attention to the `examples/dataview-fixtures/` sub-cluster. Since these were hand-edited, verify that they interlink correctly in the graph as expected, separate from the main wiki cluster.

### 5. Risk Assessment: LOW
The plans are surgically precise, address all previous concerns with code-level evidence, and include robust automated and human verification steps. The transition of existing data is handled both mechanically and (where required) manually, ensuring a high-quality outcome for the Obsidian graph.

**Review Status: APPROVED**

---

## Codex Review

## Summary

HIGH #1 is resolved in the embedded `bin/lint.sh` design: `--fix` now computes missing aliases from literal alias membership, so the id slug is added even when it is already filename-stem reachable. HIGH #2 is only partially resolved: Plan 03 adds the correct hand-edit workflow for the 10 `example:true` dataview fixture pages, but stale contradictory text still says all 12 `example:true` pages are exempt and should not be hand-edited. As submitted, the plans are close, but not convergence-clean.

## Cycle-2 HIGH Disposition

### HIGH #1: `to_add` computed from reachability instead of literal aliases

**RESOLVED.**

The revised embedded code separates reachability from literal alias membership:

```python
existing_lower = {a.lower() for a in aliases}     # LITERAL alias membership (drives --fix)
reachable = {stem.lower()} | existing_lower        # Obsidian resolvability (drives error)
```

And `to_add` is now computed against `existing_lower`, not `reachable`:

```python
if title and title.lower() not in existing_lower:
    to_add.append(title)
if pid and pid.lower() not in existing_lower:
    to_add.append(pid)
```

This directly fixes the prior failure: for `id == filename stem`, the id is still added because it is absent from aliases even though it is stem-reachable. Test 9b also explicitly guards this:

```python
assert 'my-concept' in aliases
```

### HIGH #2: `example:true` pages treated as remediation-exempt

**PARTIALLY RESOLVED.**

Correct remediation is present in Plan 03:

```text
10 dataview-fixture content pages ... literal self-alias (title + id) by HAND-EDIT
```

And Task 1 Step 2b explicitly lists the 10 fixture files and includes a YAML parse/self-alias verification loop.

However, contradictory stale text remains. Plan 01's decision-record Consequences still says:

```text
the 12 `example: true` fixture pages are exempt per the lint-skip convention
```

Plan 03 Task 1 Step 2 also says:

```text
The 12 `example: true` pages ... stay EXEMPT per LINK-09
Do not attempt to hand-edit the 12 example:true pages
```

That directly contradicts Step 2b and the Cycle-2 ruling. The human checkpoint repeats the stale framing:

```text
the 12 example:true fixtures stay exempt
```

So the implementation path can be correct, but the plan/spec text is not clean enough to call this fully resolved.

## Strengths

- The `--fix` literal-membership bug is fixed at the actual code level, not just in prose.
- `_yaml_quote_alias()` addresses the colon-title YAML corruption risk.
- `linkres` is made callable in isolation with a defensive `obsidian_map` build.
- `index.md` and `log.md` are now included in body-link scanning:

```python
for special in ('index.md', 'log.md'):
    ...
    linkres_scan.append(...)
```

- §11.3 schema drift is addressed in Plan 01 by adding `linkres` to the error remap, while Plan 02 updates `docs/reference/ci.md`.
- Test 9b is a good regression canary for the exact Cycle-2 HIGH #1 failure mode.

## Concerns

- **HIGH:** HIGH #2 still has contradictory instructions. Remove every statement saying the 12 `example:true` pages are exempt. The correct split is: 10 dataview fixtures hand-edited, 2 scaffolding files exempt.

- **MEDIUM:** LINK-02 literal self-alias membership is fixed by `--fix`, but not fully enforced by `linkres` without `--fix`. The error condition still uses `reachable`, so a page with `id == filename` but missing the literal id alias can pass CI. If LINK-02 is a hard invariant, `title/id not in existing_lower` should be a `linkres` error or at least a CI-gating finding.

- **MEDIUM:** `schema/obsidian/*.md` only gets:

```yaml
aliases:
  - {{title}}
```

That does not obviously ship both literal `title` and `id` aliases. If `{{title}}` expands to the filename slug, it misses the human title; if it expands to the human title, it misses the id slug.

- **LOW:** Plan 02 still says "9 cases" in a few places while describing 10 cases including 9b and 10.

- **LOW:** Plan 02 threat model still says `_apply_self_alias_fix` uses `except Exception: pass`, but the embedded helper now prints a warning. Update the threat text to match the code.

## Suggestions

- Delete or rewrite the stale exemption text in Plan 01 DR Consequences, Plan 03 Step 2, and the human checkpoint.
- Add a `linkres` test where a page has `aliases: ["My Concept"]` but lacks `"my-concept"` and assert it fails if LINK-02 is meant to be CI-enforced.
- Make the Obsidian templates explicitly address both aliases, or stop claiming they ship the full invariant.
- Keep the Plan 03 fixture self-alias verification; it is the right guard for LINK-09.

## Risk Assessment

**HIGH as submitted.** The code-level fix for HIGH #1 is solid, but HIGH #2 is still contradicted by multiple plan sections, including the proposed decision-record content. After removing those stale exemption statements and deciding whether literal self-alias membership should be CI-enforced, risk would drop to LOW/MEDIUM.

---

## Consensus Summary

Both reviewers **agree Cycle-2 HIGH #1 (`to_add` literal membership) is genuinely RESOLVED**
at the code level: Plan 02 subcheck A now computes `to_add` from `existing_lower` (literal alias
membership), not stem-inclusive `reachable`, so the id slug is added even when `id == filename`.
Test 9b is the regression canary. Orchestrator independently confirmed this against 14-02-PLAN.md
lines 593–615 — **RESOLVED**.

They **diverge on HIGH #2 (LINK-09 examples remediation) and on overall risk**. Gemini rates the
plans **LOW / APPROVED**, reading HIGH #2 as RESOLVED because the correct hand-edit workflow now
exists (Plan 03 objective + Step 2b). Codex rates them **HIGH as submitted / PARTIALLY RESOLVED**,
because the revision *added* the correct workflow but *left in place* three pieces of stale
contradictory text that still declare the 12 `example: true` pages exempt — one of which is a
direct intra-task contradiction, and one of which is the proposed decision-record body that would
be committed into the permanent wiki.

**The orchestrator independently verified Codex's load-bearing HIGH against the plan files. It is
confirmed real** (grep evidence below). As in Cycles 1 and 2, the deeper trace (Codex) wins over
the design-intent read (Gemini): Gemini saw the new correct workflow and stopped; Codex (and the
orchestrator) found that the old wrong workflow text coexists with it.

### Agreed Strengths

- **HIGH #1 fix is at the code level, not prose** — both reviewers cite the `existing_lower` /
  `reachable` split and the Test 9b canary explicitly.
- `_yaml_quote_alias()` + colon-title canaries (Test 9, Plan 03 Step 5b) close the YAML-corruption
  risk on the two real colon-titled decision pages.
- Defensive `if 'obsidian_map' not in dir():` build makes `--category linkres` callable in
  isolation (no NameError) — Cycle-1 HIGH #1 stays fixed.
- `index.md`/`log.md` body-link scan added (Plan 02 lines 641–658 + Test 10) — Cycle-2 MEDIUM
  closed.
- §11.3 source-of-truth severity-remap table updated in Plan 01 Edit E alongside `docs/reference/ci.md`
  in Plan 02 — Cycle-2 MEDIUM schema-drift closed; single-writer-per-wave discipline preserved.

### Agreed Concerns (highest priority)

- **[HIGH — confirmed live by orchestrator] HIGH #2 is only PARTIALLY RESOLVED: the plans carry
  the correct hand-edit workflow AND three pieces of stale contradictory "12 exempt" text.** The
  correct ruling is present (Plan 03 objective lines 63–69: "lint-skip means NOT-LINT-ENFORCED,
  not NOT-REMEDIATED"; Step 2b lines 183–216 hand-edit the 10 dataview fixtures). But stale
  contradictory text remains in three places (grep-confirmed):
    - **14-01-PLAN.md line 439** (decision-record Consequences body): *"the 12 `example: true`
      fixture pages are exempt per the lint-skip convention."* This is the worst instance — it is
      the proposed DR content, so executing Plan 01 verbatim would commit the WRONG ruling into the
      permanent `wiki/decisions/` record, directly contradicting LINK-09 and Plan 03.
    - **14-03-PLAN.md line 175** (Task 1 Step 2): *"The 12 `example: true` pages … stay EXEMPT per
      LINK-09 … Do not attempt to hand-edit the 12 example:true pages."* This directly contradicts
      Step 2b (line 183) in the SAME task, which mandates hand-editing 10 of those 12. An executor
      reading Step 2 first could skip Step 2b and leave LINK-09 unmet.
    - **14-03-PLAN.md line 351** (human-verify checkpoint `<what-built>`): *"the 12 example:true
      fixtures stay exempt"* — same stale framing surfaced to the human reviewer.
    **Fix (Codex, endorsed):** delete/rewrite all three stale statements to the agreed split —
    *10 dataview fixtures hand-edited (Step 2b), 2 scaffolding files (kahneman README.md + log.md)
    exempt.* This is a text-consistency fix, not a code change; the executable workflow is already
    correct. Until the contradiction is removed, the phase can finish "green" on the wrong reading
    (skip Step 2b) or commit a self-contradicting decision record.

### Divergent Views

- **HIGH #2 disposition:** Gemini RESOLVED (the correct workflow exists) vs Codex PARTIALLY
  RESOLVED (the wrong workflow text also still exists). Orchestrator sides with Codex —
  contradictory instructions in an executable plan are a real defect, and one instance lands in the
  committed DR. **Counts as 1 unresolved HIGH this cycle.**
- **Overall risk:** Gemini LOW / APPROVED vs Codex HIGH as submitted. Same Cycle-1/Cycle-2 pattern:
  design-level review approves once the right thing appears; code/text-trace review fails on the
  wrong thing still being present.

### Lower-severity items (non-blocking, worth folding into the same fix pass)

- **[MEDIUM — Codex]** LINK-02 literal membership is enforced only by `--fix`, not by `linkres`
  without `--fix`: the error condition uses `reachable`, so a page with `id == filename` but no
  literal id alias passes CI clean. If LINK-02 is meant to be a CI-hard invariant (not just a
  `--fix`-healable one), make `title/id not in existing_lower` an error (or CI-gating finding) and
  add a test for the `aliases: ["My Concept"]`-but-missing-`"my-concept"` case. **Decision needed:**
  is the literal invariant CI-enforced, or only `--fix`-healed? The requirement text (LINK-02
  "MUST include") leans toward CI-enforced; the current design only heals it.
- **[MEDIUM — Codex]** `schema/obsidian/*.md` ships only `aliases: - {{title}}`. Depending on what
  `{{title}}` expands to, this ships at most one of the two literal aliases — it does not obviously
  ship BOTH the human title AND the id slug, yet Plan 01's must-have claims the obsidian templates
  carry the self-alias invariant. Either make the obsidian templates ship both, or soften the
  must-have wording to "seeds the title self-alias (Obsidian auto-fills; id slug added on first
  lint --fix)".
- **[LOW — Codex]** Plan 02 still says "9 cases" in several places (objective line 68, task name,
  done block) while actually describing 10 (incl. 9b + 10). Cosmetic count drift.
- **[LOW — Codex]** Plan 02 threat-model row T-14-02-04 still describes `except Exception: pass`,
  but the embedded helper now `print(...)`s a warning. Align the threat text with the code.
- **[LOW — Gemini]** Plan 03 Step 6 `<N_wiki>` / `<N_ex>` log placeholders — ensure replaced with
  real counts before commit (a guard grep is already in the plan; keep it).

### Recommendation

Cycle-2 HIGH #1 is genuinely closed at the code level (`to_add` from literal membership + Test 9b),
and the Cycle-2 MEDIUMs (index/log scan, §11.3 drift) are closed. **One HIGH remains: HIGH #2 is
only partially resolved** — the correct examples-remediation workflow is present but coexists with
three stale "12 exempt" statements, including the proposed decision-record body (Plan 01 line 439)
and a direct intra-task contradiction (Plan 03 line 175 vs 183). Do not execute verbatim. Remove
the three stale exemption statements (text-only fix; the executable workflow is already correct),
and rule on the two MEDIUMs (is literal self-alias membership CI-enforced or only `--fix`-healed;
do the obsidian templates ship both aliases). With those applied, the phase cleanly achieves
LINK-01..10.

Recommended next step: `/gsd-plan-phase 14 --reviews`.
