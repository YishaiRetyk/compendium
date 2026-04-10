---
phase: 3
reviewers: [gemini, codex]
reviewed_at: 2026-04-10
plans_reviewed: [03-01-PLAN.md, 03-02-PLAN.md, 03-03-PLAN.md, 03-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 3: Ingestion & Provenance Pipeline

## Gemini Review

This review evaluates the four implementation plans for **Phase 3: Ingestion & Provenance Pipeline**.

### Summary

The proposed plans effectively operationalize the conceptual "compiler pipeline" by bridging the gap between high-level workflows and concrete execution rules. The sequence is logical: first encoding the "laws of ingestion" (granularity and merge policies) into `AGENTS.md`, then providing a zero-dependency CLI tool for file management, and finally validating the system with two distinct source types (Article and Journal). The plans strictly adhere to the project's "agent-agnostic" and "markdown-first" philosophy while ensuring that knowledge accumulation (incremental updates) is prioritized over simple file overwriting.

### Strengths

- **Adaptive Granularity**: Plan 01's inclusion of a specific granularity table (D-01–D-05) is excellent. It provides the LLM with clear heuristics (e.g., atomic for papers vs. clusters for journals) that prevent "provenance noise" while maintaining rigor.
- **Incremental Update Policy**: The "Append-Then-Synthesize" mantra (D-06–D-10) is a critical architectural choice. It ensures that the wiki grows as a compounding artifact without losing historical provenance, solving the "silent deletion" risk identified in research.
- **Tooling Simplicity**: `bin/ingest.sh` (Plan 02) is correctly scoped to file-system "bookkeeping" only. By avoiding LLM API calls in the script, it remains portable and agent-agnostic.
- **Comprehensive Validation**: Using a synthetic article that overlaps with existing Phase 2 pages (Kahneman, Cognitive Biases) is a high-signal test. It forces the system to demonstrate its "MERGE/UPDATE" capabilities rather than just "CREATE."
- **Privacy Awareness**: Plan 04 correctly exercises the `local_only` privacy tier for personal journal entries, validating the privacy inheritance logic established in Phase 1.

### Concerns

- **Slug Fragility (Plan 02)**: **LOW**. The logic for deriving a slug from a filename can be fragile (e.g., if a file is named `Untitled 1.md`).
    - *Mitigation*: The plan includes a `--slug` override and instructions to sanitize the filename, which is sufficient for a CLI tool.
- **LLM Synthesis Drift (Plan 03/04)**: **MEDIUM**. There is a risk that the "Re-synthesize TL;DR" step might accidentally drop or hallucinate claims from the detail section if the page becomes very large.
    - *Mitigation*: Section 10 Pass 4 (Lint) is meant to catch this. Plans 03 and 04 should explicitly emphasize that the Lint pass must verify that the summary accurately reflects *all* detail-layer claims.
- **Source Type Consistency**: **LOW**. Research identified that "book" was used in Phase 2 but wasn't in the enum.
    - *Mitigation*: Plan 01 explicitly resolves this by adding `book-chapter` to the enum and mapping `source_type: book` to it.

### Suggestions

- **Granularity Heuristic**: In `AGENTS.md` (Plan 01), explicitly instruct the agent to "Err on the side of atomic granularity" for any claim that might be contradicted by a future source. This strengthens the contradiction detection (Phase 5).
- **Instruction Output**: In `bin/ingest.sh`, consider adding a "Copy to Clipboard" hint (if `pbcopy` or `xclip` is available) for the printed prompt, making the handoff to the LLM agent even smoother.
- **Validation Article Content**: For Plan 03, ensure the synthetic article includes at least one claim that *contradicts* a claim in the existing wiki (e.g., a revised date or a newly identified sub-bias). This would test the `[epistemic:: stale]` and `SUPERSEDE` logic earlier than Phase 4.

### Risk Assessment

**Risk Level: LOW**

The plans are well-grounded in the research findings and address the specific pitfalls (provenance resolution, silent deletions, and portability) identified in the research document. The transition from conceptual workflows to operational procedures is handled with high specificity, reducing the likelihood of agent ambiguity during ingestion.

- **Quality**: High. Clear traceability to requirements (INGST, PROV, CMPL).
- **Completeness**: High. Covers the full pipeline from file-drop to index-update.
- **Risks**: Minimal. Most "runtime" risks are addressed by the 5-pass pipeline structure itself.

---

## Codex Review

### 03-01-PLAN.md

**Summary:** Strong schema-hardening plan, tightly scoped to the actual Phase 3 blocker: AGENTS.md currently defines the pipeline conceptually but not operationally enough for consistent execution. Main risk is wording drift: the plan assumes exact section locations and exact strings, so it is brittle to prior edits.

**Strengths:**
- Targets the real ambiguity in the system: how to extract and how to merge.
- Maps cleanly to locked decisions D-01 through D-10.
- Uses acceptance criteria that are concrete and grep-verifiable.
- Preserves the agent-agnostic goal by putting behavior into AGENTS.md instead of code.
- Correctly treats Pass 0, Pass 2, Pass 3, and workflow steps 5-6 as the minimum required insertion points.
- Addresses an actual known inconsistency: `book` vs the current source type enum.
- Keeps scope contained to one file and one conceptual outcome.

**Concerns:**
- **MEDIUM:** The plan hardcodes section line ranges and exact phrasing assumptions. If AGENTS.md has drifted, an executor could patch the wrong location or overfit to text matching instead of section semantics.
- **MEDIUM:** The `book` handling is only partially resolved. The plan adds `book-chapter` and then says an existing `source_type: book` is "equivalent to book-chapter," but it does not explicitly decide whether `book` remains valid frontmatter going forward or should be normalized.
- **LOW:** The update policy tells agents to mark superseded claims with `[epistemic:: stale]` and a note, but this may pre-commit a specific contradiction-handling pattern before Phase 5 formalizes contradiction and staleness workflows.
- **LOW:** "All existing content is preserved" is a good constraint, but the plan does not state how to handle duplication if the current AGENTS wording already partially overlaps with the new additions.

**Suggestions:**
- Patch by section header, not by line number or nearby literal text.
- Clarify the source type decision: either "`book` remains accepted as a backward-compatible alias" or "`book` is deprecated in favor of `book-chapter`."
- Soften stale-marking instruction so it does not front-run Phase 5: "mark as superseded or stale per current schema conventions."
- Add one semantic verification step beyond grep: confirm the updated AGENTS.md still reads coherently as a human-facing spec.
- Make the required summary file optional or move it into a separate housekeeping task.

**Risk Assessment:** LOW-MEDIUM. Well targeted and likely to succeed, but brittle in execution and leaves the `book` vs `book-chapter` question half-settled.

### 03-02-PLAN.md

**Summary:** Pragmatic and appropriately minimal CLI plan. Respects the phase boundary by keeping the helper limited to file placement, hashing, and instructions. Slightly under-specifies behavior for non-markdown sources, existing destination collisions, and slug sanitization edge cases.

**Strengths:**
- Very good scope control: bash only, no API calls, no orchestration creep.
- Matches D-11 through D-13 closely.
- Correctly computes `content_hash` up front.
- Uses portable hash fallback logic with `sha256sum` and `shasum`.
- Keeps the script agent-agnostic by printing instructions instead of invoking models.
- Smoke-test verification is concrete and easy to run.

**Concerns:**
- **MEDIUM:** The plan says "zero external dependencies beyond GNU coreutils," but also claims portability with `shasum`. Those two statements pull in different directions.
- **MEDIUM:** No collision strategy is defined if `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/` already exists. A second run on the same slug/date could silently overwrite or co-mingle files.
- **MEDIUM:** The plan does not specify what happens for bundle-worthy sources with assets. AGENTS.md supports bundles with co-located assets.
- **LOW:** Slug derivation rules are described informally: transliteration, repeated hyphens, empty slugs, and filenames made entirely of stripped characters are not covered.
- **LOW:** The script uses UTC dates, while the repo context includes a local timezone.
- **LOW:** The plan says "copy (not move)," but does not mention permissions preservation or whether existing files should be refused.

**Suggestions:**
- Define explicit collision behavior: fail if the destination exists unless `--force` or `--suffix` is provided.
- State whether v1 only supports single-file ingest, or add a limited `--asset-dir`/directory mode.
- Add validation for derived slugs: if sanitization yields an empty string, fail with a clear error.
- Clarify the date policy: use UTC intentionally for deterministic paths, or switch to local date.
- Adjust success criteria wording from "GNU coreutils" to "standard shell tools with `sha256sum` or `shasum` available."
- Add one negative test for an existing destination path and one for a bad slug value.

**Risk Assessment:** MEDIUM. Sensible and likely to produce a useful helper, but under-specifies several user-facing edge cases. First real friction will probably be duplicate destination handling.

### 03-03-PLAN.md

**Summary:** The most ambitious plan in the phase. Strong in forcing overlap with existing Kahneman-domain pages, which validates incremental merge behavior. Main issue: bundles too many outcomes into one execution unit, and pre-decides which pages should be updated before the Diff pass runs.

**Strengths:**
- Tests the exact hard part of the phase: incremental updates to existing pages.
- Correctly depends on the schema and CLI groundwork from Plans 01 and 02.
- Forces atomic extraction for article-type content, validating adaptive granularity.
- Includes provenance, frontmatter, index, and log requirements end to end.
- Explicitly preserves existing provenance markers.
- Uses a source topic that naturally touches several existing pages.

**Concerns:**
- **HIGH:** The plan prescribes exact update targets (`daniel-kahneman`, `cognitive-biases`, `system-1-vs-system-2`, `decision-making`) before the diff pass is actually performed. That weakens pipeline integrity by partially deciding merge outputs in advance.
- **HIGH:** It assumes these pages should all be updated, but some new content might warrant a new page like `[[Prospect Theory]]` or `[[Loss Aversion]]` rather than overloading existing pages.
- **MEDIUM:** The synthetic article includes potentially time-sensitive or biographical claims; risks conflating source validation with factual validation.
- **MEDIUM:** No explicit rule for when a red link should remain versus when a new concept page must be created.
- **MEDIUM:** The lint step is too lightweight for the amount of mutation being done. "No contradictions" is requested, but there is no concrete contradiction-check method.
- **MEDIUM:** Acceptance criteria focus heavily on grep counts, which can be satisfied while producing poor synthesis.
- **LOW:** Requirement list includes `CMPL-01` but the plan implicitly exercises more.
- **LOW:** The source summary is synthetic and authored directly for the test, not quite the same as a naturally ingested raw source.

**Suggestions:**
- Make the update targets conditional rather than mandatory: "candidate pages expected to be considered during Diff pass."
- Add an explicit decision gate: if `Prospect Theory` or `Loss Aversion` crosses the threshold for a first-class concept page, create it instead.
- Separate semantic validation from structural validation. Require a brief manual review checklist:
  - New claims are actually novel relative to the pre-ingest page.
  - Claims landed in appropriate sections.
  - TL;DR and Key Facts materially reflect the new detail layer.
- Avoid synthetic "biography update" facts unless they are necessary to test merging.
- Add one explicit check that source-summary claims and merged-page claims use consistent locators and wording.
- Consider reducing mandatory updated pages from four to "at least two existing pages plus any necessary new page."

**Risk Assessment:** MEDIUM-HIGH. Conceptually aligned with the phase goal, but risks validating a scripted merge rather than a real diff-driven ingest. Biggest issue is pre-deciding outputs that the pipeline is supposed to discover.

### 03-04-PLAN.md

**Summary:** Good complementary validation plan exercising a different source type, privacy tier, and extraction granularity. Main risk: privacy propagation rule says `decision-making.md` should become `local_only`, which could unintentionally contaminate a broadly useful overview page.

**Strengths:**
- Excellent choice of contrasting validation mode: journal entry vs article.
- Correctly tests paragraph-level extraction instead of atomic claims.
- Good restraint: other pages only updated if the journal adds substantive claims.
- Handles personal content as `local_only` at the source level.
- Explicitly distinguishes direct observations from inferred synthesis.
- Validates that a second ingest can update an already-updated page.
- Avoids scope creep into many page updates.

**Concerns:**
- **HIGH:** The plan says `wiki/overviews/decision-making.md` should have `privacy: local_only` because it inherits the strictest tier from contributing sources, but that inheritance rule is not clearly established as a universal page-level rule. This could unintentionally make a major overview page unusable for cloud-safe workflows after a single private journal ingest.
- **MEDIUM:** Updating a shared overview page with personal reflections blurs the boundary between general knowledge synthesis and private self-knowledge.
- **MEDIUM:** Provenance locators are said to be paragraph-level, but instructions reference section names rather than explicit paragraph locators (`#paraN`).
- **MEDIUM:** Plan validates privacy on the source summary, but does not define how index entries should handle `local_only` content in a mixed-privacy vault.
- **LOW:** The journal is synthetic, so "personal" content is simulated rather than truly privacy-sensitive.
- **LOW:** Verification criterion "provenance count is less than article ingest" is directionally useful but not sufficient to prove correct clustering.

**Suggestions:**
- Resolve privacy inheritance explicitly before execution:
  - Keep `decision-making.md` cloud-safe and avoid merging local-only claims into it.
  - Split personal reflections into a separate local-only page linked from the overview.
  - Adopt strictest-tier inheritance as a formal rule in AGENTS.md before using it here.
- If testing paragraph-level provenance, use `#paraN` locators or a clearly defined paragraph-numbering convention.
- Add one acceptance criterion about content separation: the overview should remain a synthesis page, not become a journal excerpt dump.
- Consider creating a dedicated local-only page such as `personal-decision-patterns.md`.
- Add one lint check that no `local_only` content is accidentally referenced from cloud-safe pages.

**Risk Assessment:** MEDIUM. Extraction and merge strategy mostly sound, but privacy propagation is under-specified and could create a structural problem bigger than the validation itself.

### Overall Assessment (Codex)

The set of plans is coherent and well sequenced. Main cross-plan risks:

- **Schema ambiguity still leaking into execution:** `book` vs `book-chapter`, stale vs superseded semantics, and privacy inheritance need firmer decisions.
- **Validation plans partially pre-baking outputs:** especially in `03-03`, where the diff pass is supposed to decide what to update.
- **Overloading existing pages instead of testing page-creation judgment.**
- **Reliance on grep-heavy verification:** useful for structure, insufficient for semantic quality.

**Cross-Plan Suggestions:**
- Add a short phase-level verification checklist after `03-04`:
  - Both source types ingested successfully.
  - Atomic vs paragraph-level extraction visibly differ.
  - At least one merge decision was made based on actual diff, not preselection.
  - Privacy handling is consistent and documented.
  - No existing provenance markers were removed.
- Clarify privacy inheritance in AGENTS.md before running `03-04`.
- In `03-03`, allow creation of `[[Prospect Theory]]` or `[[Loss Aversion]]` if warranted.
- Add one semantic review pass per ingest, not just grep verification.
- Treat summary-file generation as secondary housekeeping.

**Overall Phase Plan Risk: MEDIUM.** Architecture sound, sequencing strong, but two issues need tightening before execution: diff-driven page targeting in `03-03`, and privacy inheritance in `03-04`.

---

## Consensus Summary

### Agreed Strengths
- **Adaptive granularity rules (D-01–D-05)** in Plan 01 are well-designed and operationalize the pipeline clearly (both reviewers).
- **Append-Then-Synthesize / Incremental update policy (D-06–D-10)** is a critical architectural choice preventing silent deletions (both).
- **CLI scope discipline** in Plan 02: bash-only, file-bookkeeping only, no LLM API calls (both).
- **Validation choice** in Plan 03: forcing overlap with existing Kahneman-domain pages is high-signal for merge behavior (both).
- **Source type contrast** between Plans 03 (article/atomic) and 04 (journal/paragraph) validates adaptive granularity end-to-end (both).

### Agreed Concerns (highest priority — raised by both reviewers or rated HIGH by one)

1. **[HIGH — Codex] Plan 03 pre-decides merge outputs.** The plan prescribes exact update targets before the Diff pass runs, undermining the pipeline's discover-then-merge logic. Risk: validates a scripted merge rather than a real diff-driven ingest.

2. **[HIGH — Codex] Plan 03 doesn't test page-creation judgment.** New concepts like `Prospect Theory` / `Loss Aversion` may warrant first-class pages but the plan forces overloading existing pages.

3. **[HIGH — Codex / LOW — Gemini] Plan 04 privacy inheritance rule is under-specified.** Making `decision-making.md` `local_only` from a single journal ingest could contaminate a broadly useful overview page. The strictest-tier-inheritance rule is not yet formalized in AGENTS.md. Gemini viewed this as a strength; Codex flagged it HIGH. **Divergent view worth investigating.**

4. **[MEDIUM — both] Lint / semantic verification is lightweight.** Gemini worries about TL;DR re-synthesis drift; Codex worries that grep-heavy acceptance criteria can be satisfied while producing poor synthesis. Both recommend adding semantic verification beyond grep counts.

5. **[MEDIUM — Codex] Plan 01 is brittle to AGENTS.md drift** (hardcoded line numbers, exact phrase matching). Patches should be by section header, not literal text.

6. **[MEDIUM — Codex] Plan 02 missing collision strategy** when `sources/YYYY/YYYY-MM/YYYY-MM-DD-slug/` already exists.

7. **[MEDIUM — Codex] `book` vs `book-chapter` source type decision is half-settled.** Plan 01 adds `book-chapter` but doesn't explicitly decide whether existing `book` frontmatter should be normalized or remain a backward-compatible alias.

### Divergent Views

- **Overall risk:** Gemini says **LOW** (plans are well-grounded in research); Codex says **MEDIUM** (execution brittleness + privacy inheritance problem). Worth investigating: Codex's concerns are more operational (what could go wrong at execution time), Gemini's assessment is more architectural (is the design sound).
- **Plan 04 privacy handling:** Gemini calls it a strength ("correctly exercises `local_only` tier"); Codex flags the strictest-tier-inheritance propagation as HIGH concern. The disagreement is about whether the rule itself is correct, not whether the plan implements a stated rule.

### Recommended Actions Before Execution

Based on consensus, the following should be addressed via `/gsd:plan-phase 3 --reviews`:

1. **Plan 01:** Clarify `book` vs `book-chapter` deprecation; patch by section header not line numbers; soften stale/superseded wording so it doesn't front-run Phase 5.
2. **Plan 02:** Add collision strategy (fail unless `--force`); clarify UTC vs local date policy; fix the "GNU coreutils" vs `shasum` portability contradiction.
3. **Plan 03:** Reframe update targets as "candidates to be considered during Diff pass" not mandatory; add decision gate for creating new concept pages (`Prospect Theory`, `Loss Aversion`); add semantic review checklist beyond grep.
4. **Plan 04:** Resolve privacy inheritance rule explicitly (formalize in AGENTS.md before execution, or avoid merging local-only claims into shared overview); use `#paraN` locators for paragraph-level provenance.
5. **Cross-plan:** Add a phase-level verification checklist ensuring diff-driven merge actually occurred and no provenance markers were removed.
