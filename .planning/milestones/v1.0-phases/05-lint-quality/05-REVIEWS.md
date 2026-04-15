---
phase: 5
reviewers: [codex, gemini]
reviewed_at: 2026-04-13
plans_reviewed: [05-01-PLAN.md, 05-02-PLAN.md, 05-03-PLAN.md, 05-04-PLAN.md]
---

# Cross-AI Plan Review — Phase 5

## Codex Review

### Plan 01 Review

**Summary**

Plan 01 is correctly sequenced as schema-first work and it covers the key documentation prerequisites for the lint system. The main weakness is that it mixes authoritative schema changes with mass backfill edits in a way that may hard-code assumptions too early, especially around `knowledge_domain` semantics and contradiction detection behavior before the implementation has been proven against real content.

**Strengths**

- Establishes the right dependency order: schema before enforcement.
- Ties changes directly to locked decisions D-01 through D-23.
- Makes the new fields and decay rules explicit and machine-enforceable.
- Includes backfill of existing pages so Plan 02 has usable inputs.
- Acceptance criteria are concrete and grep-verifiable.

**Concerns**

- **HIGH**: `knowledge_domain` is introduced as a single primary field, but the repo already has `domains` as a list. The plan does not define the relationship clearly enough, which risks inconsistent authoring and confusing lint behavior.
- **HIGH**: Step 5 in the proposed AGENTS.md lint workflow says contradiction detection should flag any section with claims from 2+ source IDs. That is materially broader than D-01 ("same subject/attribute disagreement") and will generate false positives.
- **MEDIUM**: The backfill task says "all existing wiki pages," but the file list is fixed to 10 pages. If more pages already exist, the plan will silently under-deliver.
- **MEDIUM**: Adding `has_contradictions` as "set by lint workflow" is reasonable, but the plan does not state whether agents may set it manually when adding contradiction markers during ingest/query flows.
- **LOW**: The validation checklist numbering is brittle and likely to drift when AGENTS.md changes again.

**Suggestions**

- Define `knowledge_domain` explicitly as the primary decay bucket and state how it should relate to `domains`: `domains` = topical classification, `knowledge_domain` = staleness policy bucket.
- Narrow AGENTS.md contradiction wording so the lint surfaces "potential contradiction candidates" rather than treating multi-source sections as contradictions.
- Replace the fixed backfill file list with a repo scan over all wiki page types, then validate coverage mechanically.
- State that `has_contradictions` may be set either by lint or by any workflow that inserts `[contradiction:...]` markers.
- Avoid encoding exact checklist item numbers in the plan unless necessary.

**Risk Assessment:** MEDIUM

---

### Plan 02 Review

**Summary**

Plan 02 is the core implementation plan and is directionally correct: deterministic bash wrapper, inline Python for structured parsing, persistent report, and on-demand execution. The main problem is that it tries to deliver too much in one wave and includes several heuristics that are likely to create noisy findings or brittle behavior on a small wiki.

**Strengths**

- Reuses established project patterns instead of inventing a new runtime.
- Separates report generation from stdout summary cleanly.
- Includes `--dry-run`, `--fix`, and category scoping, which is useful operationally.
- Captures the main lint categories needed for the phase goals.
- Uses structured finding records, which will scale better than ad hoc text output.

**Concerns**

- **HIGH**: The missing cross-reference heuristic differs from the stronger roadmap/context requirement that source-page `compiled_targets` overlap should be part of the signal.
- **HIGH**: Auto-fix for stale markers is underspecified at the text-edit level. "Add `[epistemic:: stale]` to claim" is not enough to implement safely without defining claim boundaries, marker placement, idempotency, and multi-marker handling.
- **HIGH**: Exit-code contract is risky. The plan says exit 1 on any errors found. If malformed YAML or broken provenance exists in the real wiki, this can break automation and prevent report generation.
- **MEDIUM**: Preserving `created_at` for `wiki/maintenance/lint-report.md` requires reading prior state.
- **MEDIUM**: The plan claims `--fix` exists but defers actual cross-ref autofix to Plan 03 while still documenting it here.
- **LOW**: A single large inline Python block may become hard to maintain and test.

**Suggestions**

- Tighten missing cross-reference detection to match the schema.
- Define stale-marker editing semantics precisely: one marker per claim, placement after provenance cluster, no duplicate stale markers, preserve formatting.
- Ensure report generation always runs even when error-level findings exist; reserve nonzero exit code for process failure.
- Separate "implemented in this plan" versus "documented future autofix."
- Consider writing findings to a temp JSON or TSV artifact inside the script, then rendering report and summary from that.

**Risk Assessment:** HIGH

---

### Plan 03 Review

**Summary**

Plan 03 completes the remaining feature set, but it is also where the largest correctness risk appears. The proposed contradiction detection is not actually contradiction detection; it is a multi-source-section heuristic. Gap detection is more aligned with the phase goals.

**Strengths**

- Keeps contradiction and gap work separate from structural/staleness checks.
- Correctly treats contradictions and gaps as report-only.
- Red-link salience rule matches the user decisions well.
- Maturity guardrail for sparse coverage is a good anti-noise measure.
- Question suggestions are lightweight and within scope.

**Concerns**

- **HIGH**: The contradiction heuristic does not satisfy CNTR-01. "Section has 2+ sources" is not "sources disagree on the same claim." It will flag ordinary synthesis sections constantly.
- **HIGH**: Because Plan 01 also bakes this heuristic into AGENTS.md step 5, Plan 03 risks institutionalizing a false definition of contradiction across schema and implementation.
- **MEDIUM**: The plan does not explain how source pairs are normalized or deduplicated across multiple locators.
- **MEDIUM**: Sparse coverage uses `knowledge_domain` values from page frontmatter but then counts source pages by their `domains` field. That mixes two classification systems.
- **MEDIUM**: Red-link detection may misclassify links if Obsidian uses aliases or filename/title normalization beyond simple exact matching.

**Suggestions**

- Reframe contradiction output as `possible_conflict` or `multi-source section requires review` unless there is a stronger mechanical rule.
- If CNTR-01 must be met in v1, use a narrower detector: same page, same section, same nearby noun phrase or bullet slot, different numeric/date/value assertions from different sources.
- Align sparse-coverage counting on one axis only.
- Normalize contradiction source pairs lexicographically so `A vs B` and `B vs A` collapse.

**Risk Assessment:** HIGH

---

### Plan 04 Review

**Summary**

Plan 04 is a sensible end-to-end validation and human gate. Its main weakness is that it assumes the earlier plans already deliver valid category coverage.

**Strengths**

- Includes real execution of the full workflow.
- Verifies `--dry-run` and category-specific execution.
- Checks report generation and log append behavior together.
- Adds a human checkpoint before phase completion.

**Concerns**

- **MEDIUM**: "All finding categories are represented" may not be realistic on a small, recent wiki.
- **MEDIUM**: The acceptance bar "at least 3 of the 7 categories produce findings" is somewhat arbitrary.
- **MEDIUM**: Human review may approve noisy output without resolving underlying semantic mismatch.
- **LOW**: The plan does not validate reproducibility or idempotence across repeated runs.

**Suggestions**

- Change validation from "category produces findings" to "category executes correctly and either emits findings or documents why none apply."
- Add an idempotence check: two consecutive non-`--fix` runs should not change report structure except timestamp.
- Require explicit review of false-positive rate, especially for cross-ref and contradiction warnings.

**Risk Assessment:** MEDIUM

---

### Codex Overall Assessment

**Overall Risk: HIGH.** The phase is achievable, but as written the plans are likely to deliver a useful lint scaffold plus noisy contradiction/cross-reference warnings rather than a trustworthy health-check system. The biggest improvement would be tightening the contradiction model and autofix boundaries before execution begins.

---

## Gemini Review

**Summary**

The plans systematically build the wiki's health-check infrastructure, starting with the extension of the `AGENTS.md` schema to define the "rules of health" (decay rates, contradiction syntax, severity tiers). It then implements these rules through a robust, file-based CLI helper (`bin/lint.sh`) that uses a finding accumulator pattern to generate persistent reports. The separation of structural/staleness checks from more complex semantic heuristics (contradictions/gaps) allows for iterative development.

**Strengths**

- **Schema-First Design:** Defining decay tables, severity tiers, and contradiction syntax in `AGENTS.md` before implementation ensures that any agent can understand and produce compliant content.
- **Layered Staleness Model:** The combination of domain-base rates, epistemic modifiers, and hash overrides creates a sophisticated but deterministic model for knowledge decay.
- **Maturity Guardrails:** The inclusion of a guardrail for sparse coverage detection prevents the system from being noisy in the early stages of a wiki's life.
- **Finding Accumulator Pattern:** The pipe-delimited finding format is excellent for both machine parsing and human readability.
- **Mechanical Auto-fix Boundary:** The plans strictly distinguish between deterministic fixes and judgment-based findings.

**Concerns**

- **MEDIUM**: Contradiction Heuristic Noise — The "2+ sources in the same section" heuristic will likely trigger high noise levels on `type: overview` and `type: comparison` pages, which are designed to synthesize multiple sources.
- **LOW**: Wikilink Resolution Complexity — Obsidian resolution is case-insensitive and handles aliases. Implementation needs to ensure case-insensitivity to avoid false-positive orphan reports.
- **LOW**: Frontmatter Consistency — `has_contradictions: true` could get out of sync with actual content if the lint script doesn't mechanically verify/fix the boolean based on the presence of `[contradiction:]` markers.

**Suggestions**

- **Refine Potential Contradiction Logic:** Exclude (or lower severity of) multi-source section flags for pages with `type: overview` or `type: comparison`, as these are inherently multi-source by design.
- **Expand Red Link Salience:** Add "Red links in the `Related Pages` section" to the salience rule (D-20).
- **Mechanical `has_contradictions` Sync:** Add a mechanical check that ensures the `has_contradictions` frontmatter boolean matches the presence/absence of `[contradiction:]` markers in the body, with an auto-fix to sync it.
- **Progressive UI:** Print "Linting [path]..." to `stderr` for better user feedback during long runs.

**Risk Assessment: LOW.** The plans use a proven technical stack that is already operational. The logic is deterministic and file-based. The clear success criteria and human review gate provide adequate safety.

**Approved for implementation with suggested minor refinements to the contradiction heuristic and frontmatter sync.**

---

## Consensus Summary

### Agreed Strengths
- Schema-first design is well-sequenced (both reviewers)
- Established project patterns reused correctly (both reviewers)
- Maturity guardrails for sparse coverage prevent noise (both reviewers)
- Finding accumulator pattern and structured output are good design (both reviewers)
- Mechanical auto-fix boundary is appropriate (both reviewers)

### Agreed Concerns
- **Contradiction heuristic is too broad** (Codex: HIGH, Gemini: MEDIUM) — "2+ sources in the same section" will flag normal synthesis sections (especially overview and comparison pages) as potential contradictions. Both reviewers flag this as the biggest refinement needed.
- **`has_contradictions` frontmatter sync** (Codex: MEDIUM, Gemini: LOW) — Both note the field could drift out of sync with actual page content unless lint mechanically verifies it.

### Divergent Views
- **Overall risk assessment:** Codex rates the phase HIGH risk, Gemini rates it LOW risk. The divergence stems from Codex viewing the contradiction heuristic as a fundamental gap that fails CNTR-01, while Gemini views it as a refinable noise issue within an otherwise sound approach.
- **Auto-fix specification depth:** Codex rates the stale-marker auto-fix as underspecified (HIGH concern), while Gemini does not flag this. Codex wants precise text-edit semantics defined before implementation; Gemini trusts the deterministic approach will work.
- **Exit code behavior:** Codex flags the exit-code contract as risky (HIGH); Gemini does not mention it.
