---
phase: 14
reviewers: [gemini, claude, codex]
reviewed_at: 2026-06-02T15:52:59Z
plans_reviewed: [14-01-PLAN.md, 14-02-PLAN.md, 14-03-PLAN.md]
---

# Cross-AI Plan Review — Phase 14

> Three independent AI reviewers (Gemini, Claude, Codex). Claude verified its findings
> against the live `bin/lint.sh`; the two HIGH-severity bugs below were independently
> reproduced/corroborated by the maintainer against the live code (see Consensus Summary).

## Gemini Review

# Plan Review: Phase 14 — Graph Link Resolution

## Summary
The implementation plans for Phase 14 are exceptionally detailed, technically rigorous, and exhibit a deep understanding of the "Obsidian-accurate" resolution defect. The strategy correctly sequences the **Convention Correction** and **Linter Enforcement** in parallel (Wave 1) before proceeding to **Data Remediation** (Wave 2). The plans adhere strictly to the project's mandates regarding neutrality, atomicity of commits, and the authority of the `AGENTS.md` schema. The inclusion of a 5-bucket state machine for link resolution and a conservative normalization algorithm (D-02) effectively balances graph integrity with the need to preserve intentional "knowledge gap" red links.

## Strengths
- **Surgical Tooling Updates:** The `bin/lint.sh` additions are well-scoped. The use of a frontmatter-only fence for the `--fix` regex correctly mitigates the risk of corrupting page body content.
- **Robust TDD Discipline:** The 8-case test suite (`test_lint_linkres.sh`) provides comprehensive coverage for edge cases, including the critical "parens-litmus" test and multi-match warnings.
- **Architectural Integrity:** Reconciling the `orphan` check to use the same `obsidian_map` as the new `linkres` category ensures the linter no longer "lies" to the user about graph connectivity.
- **Neutrality Compliance:** The plans rigorously use abstract placeholders (`<page-title>`) for schema/template edits, preventing leakage of private vault terms into public surfaces.
- **Clear Human Checkpoints:** LINK-10 is correctly identified as a non-mechanical requirement requiring a manual Obsidian verification step before phase closure.

## Concerns
- **Selection of the `aliases:` key (MEDIUM):** The `_apply_self_alias_fix` helper relies on `ALIASES_RE` matching an existing `aliases:` key. In "brownfield" scenarios where a page might be missing the `aliases:` key entirely (rather than just having an empty list), the current regex will fail to match and the fix will skip the file. While safe, it may leave some legacy pages un-remediated.
- **Regex Edge Case (LOW):** The `ALIASES_RE` lookahead `(?=^\w|\Z)` assumes the next line is a top-level YAML key or EOF. If the frontmatter has trailing comments or unusual spacing between keys, the capture group might be fragile. However, given the project's strict template use, this is a minor risk.
- **Normalization of Underscores (LOW):** `normalize_link` replaces underscores with spaces. For pages where underscores are semantic, this may lead to collision warnings in `linkres`, though this is likely intended by the "conservative normalization" rule.

## Suggestions
- **Insertion Fallback:** In `_apply_self_alias_fix`, consider adding a fallback that appends `aliases:` to the frontmatter if the key is not found, rather than just skipping the file.
- **WIKILINK_RE Verification:** While the plan reuses the existing `WIKILINK_RE`, ensure the test fixtures include at least one link with a display alias (e.g., `[[Target|Display]]`) to confirm that `Target` is extracted for normalization, not `Display`.
- **LINT_VERSION Parity:** Ensure the `tests/phase-09/run.sh` aggregator is checked to confirm it discovers the new test file correctly (the plan assumes auto-discovery, which is consistent with existing patterns).

## Risk Assessment
**Overall Risk: LOW**

The phase is a "PATCH" milestone aimed at correctness. The logic is deterministic and mechanical. The two-wave approach minimizes the risk of breaking existing data before the enforcement logic is verified. The most complex logic (the normalization helper) is isolated and covered by targeted tests. The preservation of the `duplicate` category's independent resolution logic (as documented in Research Pitfall 5) prevents unintended regressions in near-duplicate detection while fixing graph integrity.

---

## Claude Review

I've now verified the load-bearing claims against the live `bin/lint.sh`. Here is my review.

# Cross-AI Plan Review: Phase 14 — Graph Link Resolution

## 1. Summary

This is a well-researched, well-structured three-plan phase with an unusually solid analog map and a correct mental model of Obsidian's resolution semantics (case-insensitive filename-stem + alias matching, never `title`). The convention/enforcement/remediation decomposition is sound, the Wave-1 parallelism is genuine (Plan 02's tests are self-contained temp wikis with no dependency on Plan 01's prose edits), and the conservative normalization algorithm faithfully implements the locked D-02 decision. **However, I found two HIGH-severity correctness bugs that will break the headline deliverable as written** — (a) the `linkres` block references `obsidian_map`, which `bin/lint.sh` only builds inside the `should_run('orphan')` guard, so the phase's signature command `bin/lint.sh --category linkres wiki/` will crash with a `NameError`; and (b) the `--fix` helper emits alias values unquoted, which will corrupt the frontmatter of every page whose `title` contains `: ` — and I confirmed at least two such pages already exist in `wiki/`, plus the decision record Plan 01 itself authors. Both are fixable with small changes, but neither is caught by the planned tests (which use clean fixtures). There is also a cross-wave CI-sequencing gap. The plans are close, but should not execute Plan 02/03 verbatim without addressing these.

---

## 2. Plan 14-01 (Convention + DR) — Review

### Strengths
- Correctly redirects all edits to `AGENTS.md` (the byte-source) and syncs `CLAUDE.md`, despite the requirement text naming "CLAUDE.md §8". Sync direction and the pre-commit byte-equality hazard are called out repeatedly.
- Neutrality discipline is explicit and correct (template-public files get placeholders; the DR body, being wiki data, may use concrete Obsidian terms).
- DR shape mirrors the verified analog (`dr-2026-04-14-phase6-decision-type.md`): `trigger_type: schema-update`, `affected_pages: []`, 7 sections, FORBIDDEN PATTERNS comment.
- Runs `bin/validate-op.sh` on the index/log UPDATEs per §9.

### Concerns
- **[MEDIUM] The DR's own self-alias is malformed YAML — and it's the exemplar.** Plan 14-01 specifies:
  ```yaml
  aliases:
    - Obsidian Filename + Alias Resolution: Self-Alias Invariant
    - dr-2026-06-02-obsidian-filename-alias-resolution
  ```
  The first item contains `: ` (colon-space). Unquoted in a YAML sequence, this parses as a **mapping** `{'Obsidian Filename + Alias Resolution': 'Self-Alias Invariant'}`, not a string. The `title:` field is correctly quoted, but its self-alias copy is not. So the page that is supposed to *demonstrate* the self-alias invariant ships a broken one. It must be `- "Obsidian Filename + Alias Resolution: Self-Alias Invariant"`. (This is a specific instance of the general `--fix` bug below — see 14-02.)
- **[LOW] The §8 "Graph View Implications" sentence is not explicitly corrected.** RESEARCH flags line ~657 ("Obsidian resolves aliases to the canonical page automatically") as "partially correct/misleading," but Plan 01's four edits (A–D) add rule 4a and a Bad/Good example without touching that sentence. The new 4a largely neutralizes it, but consider an explicit pass so a reader of that subsection isn't left with the old framing.
- **[LOW] Spec-vs-enforcement wording.** Checklist items 18–19 say "`aliases` *contains* the title/id." The linter (Plan 02) enforces *reachability* (`title ∈ {stem} ∪ aliases`), which is more lenient (a page whose `title.lower() == stem` needs no alias). This is the correct, Obsidian-accurate behavior, but the checklist prose implies literal membership. Minor mismatch; consider phrasing item 18/19 as "reachable via filename stem or aliases" to match what's actually enforced and avoid future "compliance" edits that add redundant aliases.

### Verdict: **LOW risk.** Fix the unquoted-colon alias in the DR; everything else is polish.

---

## 3. Plan 14-02 (Linter enforcement) — Review

### Strengths
- Excellent analog selection: `duplicate` block as structural template, `has_contradictions` as the idempotent-`--fix` template, `WIKILINK_RE`/`add_finding`/`should_run` reused rather than reinvented.
- The frontmatter-section fence (`fm_end = content.find('\n---', 3)`) in `_apply_self_alias_fix` correctly prevents the body-`aliases:` capture (Pitfall 2). I traced it — the recomposition `new_fm + content[len(fm_section):]` is correct.
- `normalize_link` is conservative and matches D-02; the parens-as-characters semantics (`Hack (Agentive Stack)` → `hack agentive stack`) is right, and the `_ ` separate-replacement for `\w`-includes-underscore is a correct detail.
- TDD ordering (write the failing test first) and the atomic `LINT_VERSION` + `test_lint_require_version.sh` bump are handled.

### Concerns
- **[HIGH] `obsidian_map` is undefined under `--category linkres` → `NameError` crash.** I verified `bin/lint.sh:1080`: `resolution_map`/`obsidian_map` is built **inside** `if should_run('orphan'):` (line 1084). The planned `linkres` block (RESEARCH §7, subcheck B) does `if t_lower in obsidian_map:` but does **not** build `obsidian_map` itself. Under `--category linkres` (category filter ≠ `all`), `should_run('orphan')` is `False`, so the orphan block is skipped and `obsidian_map` never exists. The very commands this phase is built around —
  - `bin/lint.sh --category linkres --format json "$WIKI"` (every test in Plan 02 Task 1), and
  - `bin/lint.sh --category linkres wiki/` (Plan 03 / LINK-07 success criterion)

  — will raise `NameError: name 'obsidian_map' is not defined` and emit no/invalid JSON. The `gap` block already defends against exactly this with `if 'resolution_map' not in dir():` (line 1482); the `linkres` block needs the same self-build (or hoist the map build above the `should_run` guards). RESEARCH/PATTERNS describe linkres as "reuses obsidian_map built in orphan block" without noting that the guard makes it conditional — a literal implementation breaks. *This is the single most important fix.*
- **[HIGH] `--fix` writes unquoted alias values → YAML corruption for titles containing `: `.** `_apply_self_alias_fix` builds `aliases_lines = '\n'.join(f'  - {a}' for a in new_aliases)` with no quoting. I confirmed real pages will hit this:
  - `wiki/decisions/dr-2026-06-02-sc1-examples-isolable-subgraph.md` — title `SC1 Reframing: examples/ Forms a Visually Isolable Sub-Graph`
  - `wiki/decisions/dr-2026-05-01-complementary-systems-boundary.md` — title `Complementary Systems Boundary: ...`

  Both titles are unreachable via their slug stems → subcheck A fires → `--fix` emits `  - SC1 Reframing: examples/ Forms...` unquoted → YAML parses it as a dict, not a string. On the next run, `str(dict)` is still unreachable → `--fix` fires *again* → compounding corruption and broken idempotency. Tests won't catch this (fixtures use clean titles like "My Concept"). Plan 03's yaml-category verify (step 5) might surface it *after* corruption, as a confusing downstream error. **Fix:** quote/escape alias values (e.g. emit `  - "{a.replace(chr(34), chr(92)+chr(34))}"`, or dump via `yaml.safe_dump`). Titles with `[`, `]`, leading `#/*/&/?/!`, etc. have the same hazard.
- **[MEDIUM] Test 3's parens-litmus assertion is broken *and* tests the wrong thing.** The inline `python3 -c` re-implements `normalize_link` as a single-line string containing `def n(t): s=...; ...; print(n(...))`. Putting `print(...)` after a one-line `def` via `;` folds the `print` *into* the function body (it never executes) → empty stdout → `norm == ''` → assertion fails spuriously. Even if the syntax were fixed, it validates a *copy* of the algorithm, not `bin/lint.sh`'s actual function. Recommend asserting through real lint output instead: feed `[[Hack Agentive Stack]]` and assert a single `linkres` error pointing at `hack-agentive-stack` — that exercises the SUT.
- **[MEDIUM] Test 4 (multi-match warning) fixture guidance is confused and likely passes for the wrong reason.** The plan's Task-1 prose visibly thrashes ("This requires careful fixture design… Actually: …"). The landing design (two pages titled "Beta Concept") has two problems: (1) both pages have `aliases: []`, so they each emit subcheck-A *title-unreachable errors* — a naive "assert 0 errors / 1 warning" will fail. (2) If you instead self-alias both pages to silence subcheck A, then `[[Beta Concept]]` becomes an exact alias on both → it's in `obsidian_map` → resolves → **no warning at all** (the multi-match branch is unreachable when the link text is a literal alias). A genuine multi-match requires two self-aliased pages whose *normalized* forms collide on a key that is *not* a literal stem/alias, hit by a *variant* link — e.g. pages `ctx-one.md`(title "Bounded Contexts") + `ctx-two.md`(title "Bounded Context"), both self-aliased, linked via `[[bounded-context]]` (hyphen, not a literal alias) → normalizes to `bounded context` → matches both → warning. The plan should specify a concrete, validated fixture rather than leaving the executor to discover this.
- **[MEDIUM] Plan 02's must-have "`bin/lint.sh --ci --strict` over the existing `wiki/` stays green" is false the moment linkres lands.** `--ci` is full-lint with the severity remap (CLAUDE.md §11.3), not diff-scoped. After adding `'linkres':'error'`, the 45 unreachable-title pages in `wiki/` produce 45 `error` findings → `--ci` exits 1. It only "stays green" after Plan 03 remediates. So either the must-have is unverifiable as stated, or it conflates `--ci` (full, will be red) with `--strict` (diff-scoped new-page checks, which *would* stay green since `--strict` doesn't enforce linkres reachability). See the cross-wave note in §5.
- **[LOW] The `id`-unreachable branch of subcheck A is near-dead code.** Since schema rule 10 requires `id == filename`, `pid.lower() == stem` always holds for compliant pages, so the id-unreachable error never fires. That's fine (id is added to aliases via the title-triggered fix call), but it means the only thing that adds `id` to a page whose `title` is *already* reachable-by-stem is… nothing. Edge case, but worth a comment so a future reader doesn't think id-membership is enforced.
- **[LOW] `except Exception: pass` silently drops `--fix` failures.** On a 65-page batch (Plan 03), a page that fails to write leaves the error finding emitted but the file unchanged, discoverable only by re-running. Prefer a stderr warning.

### Verdict: **HIGH risk as written.** The two HIGH bugs block the deliverable; the test-fixture issues mean the suite could go green without actually validating the subtle paths.

---

## 4. Plan 14-03 (Data remediation + human-verify) — Review

### Strengths
- Correct sequencing within the plan: `--fix` first (self-aliases), then manual variant reconciliation (`[[Bounded Contexts]]` → `[[Bounded Context]]s`), matching D-08 and Pitfall 9.
- Good human-verify checkpoint design for LINK-10 (hideUnresolved, named exemplar `domain-driven-design.md`, spot-check instructions, clear resume signal).
- Append-only log entry and atomic commit per §3.

### Concerns
- **[MEDIUM] "All 20 examples/ pages backfilled by `--fix`" is mechanically impossible.** RESEARCH itself states 11 of the 20 examples pages have `example: true`, and `bin/lint.sh:972` skips `example: true` pages out of `all_pages` *unconditionally* (independent of scan root). So `--fix` can only touch the 9 `example: false` kahneman pages; the 11 `example: true` pages are never seen by the linter and won't get self-aliases. (I verified line 962 keys on `rel_root` relative to the scan root, so pointing lint at `examples/` *does* let the walk descend — but line 972 still drops `example:true`.) LINK-09 says "respecting `example: true` / lint-skip conventions," which may mean those 11 are intentionally exempt — but then Plan 03's must-have ("20 pages have self-aliases — backfilled by `--fix`") and its narrative ("backfill all 65 pages") are wrong. Either hand-edit the 11 or restate the target as "9 via `--fix`; 11 example:true exempt." Resolve the contradiction before execution.
- **[MEDIUM-HIGH, inherited] `--fix` over `wiki/` will corrupt the two colon-titled decision pages** (see 14-02 HIGH #2) unless the quoting bug is fixed first. Plan 03 is where the corruption actually lands, across 45 pages. Its yaml verify (step 5) is the safety net but fires *after* the write.
- **[LOW] Verify command quoting bug.** The last automated check, `grep -q "Bounded Context]]s\|\[\[Bounded Context\]\]s" ... wiki/ -r`, mixes an unescaped `]]s` alternative with an escaped one and puts `-r` after the path; it's likely to misbehave. The preceding check (no `[[Bounded Contexts]]`) is the real assertion; this one is redundant and fragile.

### Verdict: **MEDIUM risk**, mostly inherited from Plan 02. The examples-count contradiction and the colon-title corruption need resolving before this wave runs.

---

## 5. Cross-Wave / Dependency-Ordering Assessment

- **Wave-1 parallelism is genuine.** Plan 02's tests build their own temp wikis and don't read Plan 01's edits; Plan 01 doesn't touch `bin/lint.sh`. Good.
- **[MEDIUM-HIGH] CI goes red between Wave 1 and Wave 2.** The `.github/workflows/lint.yml` `lint` job runs `--ci` over the repo. Once Plan 02 is committed (linkres = error), `--ci` surfaces ~45 wiki linkres errors and exits 1 — and stays red until Plan 03 finishes, which is gated on a *human* checkpoint (`autonomous: false`). On a long-lived branch this is an extended red window; if any intermediate push targets a branch-protected ref, it blocks. The plans never acknowledge this. Mitigations: (a) land 02+03 in a single PR/merge; (b) explicitly note the expected red window and that the branch is not merged until 03 completes; (c) keep `--strict` (diff-scoped, won't flag pre-existing pages) as the only required gate during the window. Recommend stating the chosen strategy in Plan 03's objective.

---

## 6. Does the phase achieve LINK-01..10?

| REQ | Achieved as written? | Blocker |
|-----|----------------------|---------|
| LINK-01/02/03 | ✅ (fix DR colon alias) | — |
| LINK-04 | ⚠️ logic correct, but… | `obsidian_map` NameError under `--category linkres` |
| LINK-05 | ⚠️ | same crash; Test 4/Test 3 don't truly validate it |
| LINK-06 | ⚠️ | `--fix` YAML-quoting corruption; orphan reconciliation fine |
| LINK-07 | ❌ until both HIGH bugs fixed | crash + corruption on `wiki/` |
| LINK-08 | ✅ (logic sound) | depends on 07 |
| LINK-09 | ⚠️ | 11 `example:true` pages unreachable by `--fix` |
| LINK-10 | ✅ (human-verify) | depends on 07/08 |

---

## 7. Suggestions (concrete)

1. **Build `obsidian_map` defensively inside the `linkres` block** (mirror the `gap` guard at line 1482), or hoist the map build above the `should_run` guards so all of orphan/gap/linkres share it. Add a Plan 02 test that runs `--category linkres` *in isolation* over a fixture with body links (the existing tests already do this, so this bug *will* surface as a crash — make sure Task 1's assertions distinguish "crash/empty JSON" from "0 findings").
2. **Quote alias values in `_apply_self_alias_fix`.** Emit `  - "<escaped>"` (escape `"` and `\`) or serialize the list with `yaml.safe_dump`. Add a fixture page whose `title` contains `: ` (e.g. "Topic: Subtitle") to Test 6/idempotency and assert the post-`--fix` file re-parses with the alias as a *string* and a second `--fix` is a no-op.
3. **Fix the DR self-alias** in Plan 01 to quote the colon-bearing title.
4. **Rewrite Test 3** to assert via real lint output (`[[Hack Agentive Stack]]` → one unique-match error citing `hack-agentive-stack`) rather than an inline re-implementation.
5. **Pin down the Test 4 fixture** with a concrete two-page collide-on-normalized-variant design (both self-aliased to avoid subcheck-A noise; link via a non-literal variant). Don't leave it to the executor.
6. **Reconcile the examples count**: decide whether the 11 `example:true` pages are exempt (update LINK-09 wording + Plan 03 must-have to "9 via `--fix`") or must be hand-edited (add a task).
7. **State the CI-red-window strategy** in Plan 03 (single-merge, or branch-not-merged-until-03).
8. Replace `except Exception: pass` with an `except Exception as e:` that emits a stderr warning, so silent batch-fix failures are visible.

---

## 8. Overall Risk Assessment

**HIGH** — driven specifically by Plan 02, which gates Plan 03.

Justification: The research and decomposition are strong and the locked decisions are faithfully implemented, but two concrete, verified defects will cause the phase's headline command (`bin/lint.sh --category linkres wiki/`) to **crash**, and the `--fix` remediation to **corrupt real frontmatter** (≥2 existing decision pages plus the DR Plan 01 authors). Neither is caught by the planned tests because the fixtures use clean, slug-reachable, colon-free titles. Add the cross-wave CI-red window and the impossible "20 examples via `--fix`" claim, and Plan 02/03 should not run verbatim. All findings are fixable with small, localized changes (defensive map build, alias quoting, two fixture rewrites, one count reconciliation, one sequencing note). With those addressed, the phase drops to **LOW-MEDIUM** risk and would cleanly achieve LINK-01..10. Plan 01 is independently low-risk and can proceed once its DR alias is quoted.

---

## Codex Review

## Summary

The phase is well-scoped and mostly coherent: Plan 14-01 fixes the documented convention, Plan 14-02 adds mechanical enforcement, and Plan 14-03 remediates existing data plus preserves a human Obsidian verification checkpoint. The biggest risks are in Plan 14-02: the proposed YAML alias rewrite is regex-based and likely brittle, the `linkres` matching logic may over-report self-links or ambiguous normalized matches, and the multi-match test fixture design is not yet sound. There is also a documentation consistency gap: `linkres` is added to `docs/reference/ci.md`, but the plans do not clearly update the authoritative AGENTS/CLAUDE lint category/severity documentation if it exists there.

### Plan 14-01 — Strengths
- Correctly identifies AGENTS.md as source of truth and CLAUDE.md as a byte-copy artifact.
- Good neutrality controls for template-public paths.
- The self-alias invariant is documented at both rule and validation-checklist levels.
- Updating both generic templates and Obsidian templates addresses future-page creation paths.
- Decision record is appropriate because this is a schema/convention correction with future explanatory value.

### Plan 14-01 — Concerns
- **MEDIUM:** The plan assumes `schema/obsidian/*.md` exists and contains `aliases: []`. If any file is absent or structured differently, the task may silently under-deliver.
- **MEDIUM:** Plan 14-02 says `docs/reference/ci.md` should align with CLAUDE.md §11.3, but Plan 14-01 does not update any AGENTS/CLAUDE lint-category or CI-severity section. If §11.3 lists categories, it will become stale.
- **LOW:** The DR body mentions `bin/lint.sh linkres enforcement` before Plan 14-02 has landed. Acceptable if the phase lands atomically, but DR wording should avoid implying enforcement already exists until Wave 1 is complete.
- **LOW:** The DR says no affected pages, but the decision materially changes invariants for all wiki pages. `affected_pages: []` is defensible for infrastructure-only, but the Affected Pages section should be explicit that data remediation is tracked separately.

### Plan 14-01 — Risk Assessment
**LOW-MEDIUM.** Mostly documentation/template work with clear verification. Risk is mainly stale authoritative documentation or missed template files.

### Plan 14-02 — Strengths
- Good separation between exact Obsidian resolution (`obsidian_map`) and conservative normalized diagnostics (`norm_map`).
- Correctly keeps true no-match red links out of `linkres`, preserving `gap` as informational.
- The D-02 normalization constraints are conservative and well specified.
- TDD ordering is good, and coverage targets the right behavioral classes.
- `--fix` scope is intentionally limited to self-aliases, avoiding editorial body-link rewrites.

### Plan 14-02 — Concerns
- **HIGH:** `_apply_self_alias_fix()` is regex-based YAML rewriting and can corrupt or miss valid frontmatter. `ALIASES_RE = r'^aliases:.*?(?=^\w|\Z)'` will stop before the next unindented word, but YAML keys can be comments, blank lines, quoted keys, nested structures, or keys after comments. It also emits unquoted aliases, so titles containing `:`, `#`, `[`, `]`, leading `*`, or other YAML-significant characters may become invalid.
- **HIGH:** The proposed helper uses stale `fm` after the first fix. If both title and id are missing, Subcheck A calls `_apply_self_alias_fix()` for title, then again for id using the original `fm`; depending on file rewrite timing, it may emit duplicate autofix findings or rewrite from stale aliases.
- **HIGH:** Test 4 fixture design is explicitly confused in the plan. It needs a deterministic multi-match case before implementation begins.
- **MEDIUM:** `obsidian_map` lowercases aliases and stems, approximating Obsidian case-insensitivity. Probably fine, but Obsidian also has path and same-folder behaviors. The plan intentionally ignores path-qualified links like `[[folder/page]]`; if those exist, they may false-positive.
- **MEDIUM:** `norm_map` includes titles even when titles are not Obsidian-reachable. Intentional for detecting should-resolve variants, but may produce errors for pages with duplicate titles, stale titles, or source-summary titles that are not meant to be canonical link targets.
- **MEDIUM:** Body link matching does not skip code fences, inline code, HTML comments, or frontmatter-like examples in body text. `linkres` as CI-gating makes false positives more costly.
- **MEDIUM:** `all_pages` apparently skips `example: true`; Plan 14-03 wants examples remediated. If `--fix` also uses `all_pages`, it will not modify skipped examples unless the loader behaves differently for direct `examples/` paths.
- **LOW:** Swallowing all exceptions in `_apply_self_alias_fix()` avoids crashes but hides failed fixes. Since `linkres` is CI-gating, better to report an `autofix` warning/error on failed write.
- **LOW:** Usage/category additions should also update any category validation list if one exists, not just the usage string.

### Plan 14-02 — Suggestions
- Replace regex YAML rewriting with a YAML-aware frontmatter updater if the repo already has one. If not, constrain the regex more safely: parse frontmatter boundaries, locate the exact `aliases:` block by line scanning, quote aliases with a YAML dumper or at least `json.dumps(value)`-style double quoting.
- In `linkres`, compute missing title/id once per page and call `_apply_self_alias_fix()` once.
- Rebuild page metadata after `--fix` only if later checks in the same run rely on updated aliases, or document that a second run is expected.
- Finalize Test 4 as two pages with distinct filenames and same normalized title, neither having the raw link as alias (`beta-a.md` title "Beta Concept", `beta-b.md` title "Beta-Concept", body link `[[Beta Concept]]`; ensure no exact filename/alias resolve).
- Add tests for YAML quoting edge cases: colon in title, brackets/parens, existing aliases preserved, empty `aliases:` null, missing `aliases` key.
- Add a test for wikilinks in code fences or document that the linter intentionally scans all markdown text.

### Plan 14-02 — Risk Assessment
**MEDIUM-HIGH.** The concept is sound, but the mutation path is brittle. A CI-gating check plus regex frontmatter rewrite raises the chance of either false positives or YAML damage unless tightened.

### Plan 14-03 — Strengths
- Correctly sequences after convention and linter enforcement.
- Uses `--fix` only for mechanical self-alias backfill and keeps body-link variant reconciliation human-reviewed.
- The `[[Bounded Context]]s` remediation follows the right Obsidian convention.
- Includes YAML validation after rewrite, which is essential given frontmatter mutation.
- Human verification in Obsidian is appropriate because the defect is ultimately UI/graph behavior.

### Plan 14-03 — Concerns
- **HIGH:** The plan assumes `--fix examples/` updates all 20 example pages, but Plan 14-02 says `all_pages` skips `example: true`. This may prevent examples from being modified and fail LINK-09.
- **MEDIUM:** Page counts are inconsistent: project context says 49 wiki pages, Plan 03 says 45 backfilled, log template says "all 45 wiki pages." Verify counts dynamically rather than hard-coding them in the log.
- **MEDIUM:** `bin/lint.sh --category linkres wiki/` exiting 0 may still allow warnings. Success criteria say zero errors, but "exits 0" alone may be misleading if report-only mode always exits 0.
- **MEDIUM:** Manual variant reconciliation is underspecified for remaining unique matches beyond `[[Bounded Contexts]]`. The plan says "possibly" for other variants, but success depends on all unique-match errors being resolved.
- **LOW:** `grep -q "Domain-Driven Design"` only proves the string exists somewhere, not that it is in the aliases list.
- **LOW:** Human verification is blocking but not tied to a recorded artifact beyond summary/log.

### Plan 14-03 — Suggestions
- Add a deterministic alias audit script/check for both `wiki/` and `examples/` that parses frontmatter and verifies `title` and `id` are in `aliases`.
- If `example: true` pages are skipped by lint, either add a `--include-examples` mode or use a separate remediation script for examples.
- Generate the log counts from actual git diff or parsed frontmatter checks, not from research-time counts.
- Strengthen final verification to parse `wiki/overviews/domain-driven-design.md` frontmatter and assert both aliases are in `aliases`.
- Treat any remaining `linkres` warning as a manual triage item in the summary, even if not CI-blocking.

### Plan 14-03 — Risk Assessment
**MEDIUM.** Remediation is straightforward if Plan 14-02 works correctly, but the examples skip behavior and regex rewrite safety could block LINK-09 or create YAML churn.

### Codex Overall Assessment
The plans likely achieve LINK-01 through LINK-08 if the linter implementation is hardened. LINK-09 is at risk because examples may be skipped by the same loader used by `linkres`. LINK-10 is appropriately handled with a human checkpoint. Main improvements before execution: (1) harden `--fix` — avoid regex-only YAML mutation, quote aliases safely, call the fixer once per page, add tests for frontmatter edge cases; (2) settle the examples behavior explicitly, because the plan says both "examples are skipped" and "run --fix on examples to update them."

---

## Consensus Summary

All three reviewers agree the phase is well-researched and well-decomposed (convention → enforcement → remediation; genuine Wave-1 parallelism). They diverge sharply on risk: Gemini rated it **LOW** (reviewed at the design/intent level), while Claude and Codex rated it **HIGH / MEDIUM-HIGH** after scrutinizing the actual `bin/lint.sh` interface code embedded in the plans. The maintainer verified the two HIGH findings against live `bin/lint.sh` — **both are confirmed real**.

### Agreed Strengths
- Sound three-plan / two-wave decomposition; Wave-1 parallelism is genuine (Plan 02 tests are self-contained temp wikis). (Gemini, Claude, Codex)
- Faithful implementation of the locked D-02 conservative-normalization decision; parens-as-characters semantics correct. (Gemini, Claude, Codex)
- `--fix` correctly scoped to mechanical self-alias backfill only; body-link reconciliation kept human-reviewed (D-06/D-08). (Gemini, Claude, Codex)
- Neutrality discipline (placeholders in template-public files) and the DR shape are correct. (Gemini, Claude, Codex)
- LINK-10 correctly handled as a human-verify checkpoint. (Gemini, Claude, Codex)

### Agreed Concerns (highest priority)
- **[HIGH — confirmed live] `--fix` writes unquoted YAML alias values → frontmatter corruption.** Claude and Codex independently flagged this; Claude named two real colon-titled decision pages plus the DR Plan 01 itself authors. Both raise this as a HIGH; Gemini partially touches the regex fragility at MEDIUM/LOW. **Fix: quote/escape alias values (yaml.safe_dump or explicit double-quoting).**
- **[HIGH — confirmed live] `obsidian_map` NameError under `--category linkres`.** The map is built only inside `if should_run('orphan'):` (lint.sh:1080); the `linkres` block references it without a self-build, so the phase's signature commands crash. Raised HIGH by Claude; Codex's "linkres matching logic" concern is adjacent. **Fix: build the map defensively inside the linkres block (mirror the gap guard at line 1482) or hoist it above the should_run guards.**
- **[HIGH/MEDIUM — confirmed live] `example: true` pages cannot be backfilled by `--fix`.** lint.sh:972 drops `example: true` unconditionally, so 11 of 20 examples pages are unreachable. Plan 03's "all 20 examples backfilled by --fix" / "backfill all 65 pages" is mechanically impossible vs LINK-09's "respecting example:true conventions." Flagged HIGH by Codex, MEDIUM by Claude. **Fix: reconcile the count — hand-edit the 11, or restate as "9 via --fix; 11 example:true exempt."**
- **[MEDIUM] Test fixtures don't validate the subtle paths.** Test 3 (parens-litmus) re-implements the algorithm inline (broken `def…;print` folding) and tests a copy, not the SUT; Test 4 (multi-match) fixture guidance is confused and likely passes for the wrong reason. (Claude, Codex)
- **[MEDIUM] Cross-wave CI red window.** Once Plan 02 lands `linkres=error`, full `--ci` over the repo exits 1 until Plan 03 (human-gated) completes. Unacknowledged in the plans. (Claude)

### Divergent Views
- **Overall risk:** Gemini LOW vs Claude HIGH vs Codex MEDIUM-HIGH. The divergence is explained by review depth: Gemini assessed design intent; Claude/Codex traced the embedded interface code against live `bin/lint.sh`. The maintainer's verification sides with Claude/Codex — the two HIGH bugs are real and not caught by the planned tests.
- **Regex YAML rewriting:** Codex recommends replacing regex with a YAML-aware updater; Gemini considers the frontmatter-fence sufficient and rates the regex risk LOW. Claude accepts the fence (verified correct for body-protection) but flags the *quoting* gap as the real HIGH.
- **`schema/obsidian/*.md` existence:** Codex flags as a MEDIUM assumption-risk; the other two assume the files exist (consistent with the plan's file list).

### Recommendation
Do not execute Plan 02/03 verbatim. Address the two confirmed HIGH bugs (alias quoting + defensive `obsidian_map` build) and the examples-count contradiction before execution; rewrite Test 3/Test 4 fixtures to exercise the SUT; note the CI-red-window strategy in Plan 03. All findings are small, localized fixes — with them applied, the phase drops to LOW-MEDIUM risk and cleanly achieves LINK-01..10. Recommended next step: `/gsd-plan-phase 14 --reviews`.
