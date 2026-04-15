---
phase: 02
reviewers: [gemini, codex]
reviewed_at: 2026-04-09T11:30:00Z
plans_reviewed: [02-01-PLAN.md, 02-02-PLAN.md, 02-03-PLAN.md]
---

# Cross-AI Plan Review — Phase 02

## Gemini Review

The proposed plans for Phase 2 provide a logical, high-fidelity progression from abstract schema definitions to concrete, interlinked knowledge artifacts. The "Wave" structure (Templates -> Examples -> Navigation/Docs) correctly manages dependencies, ensuring that example content is constrained by the templates and navigation is tested against real files. The selection of the Kahneman/Cognitive Biases domain is a sophisticated choice that will effectively stress-test the system's ability to handle overlapping concepts, entity relationships, and nuanced provenance. Overall, the plans are highly aligned with the project's core value of "compounding synthesis" and resolve several conflicting decisions from previous phases with clear prioritization.

### Strengths
- **Logical Dependency Chain:** Using Wave 1 (Templates) as the structural foundation for Wave 2 (Examples) ensures that the example content is "born" into the correct schema, reducing the risk of schema-example drift.
- **High-Signal Domain Choice:** The "Thinking, Fast and Slow" domain is ideal for testing the Concept vs. Entity vs. Comparison distinction. It provides a dense web of relationships that validates the cross-referencing requirements (3+ links per page).
- **Explicit Conflict Resolution:** Plan 02-03 proactively addresses the conflict between AGENTS.md and CONTEXT.md regarding log ordering.
- **Provenance Rigor:** The focus on provenance chains and epistemic markers in the example pages directly validates the system's core "epistemic status" value proposition.
- **Progressive Disclosure via HTML Comments:** Using HTML comments in templates to provide agent instructions without cluttering the final Obsidian view.

### Concerns
- **Log File Scalability (HIGH):** Plan 02-03 sets the Log ordering to "newest at bottom." In a long-lived project, log.md will become massive. Requiring agents to read/process the entire file to find recent context will eventually exceed context windows.
- **AGENTS.md Context Pressure (MEDIUM):** AGENTS.md is already 1178 lines. Plan 02-03 adds three more subsections. Approaching a point where "lost in the middle" effects may affect agent attention.
- **Template-Example Drift (LOW):** Since linting rules (D-10) are deferred to Phase 5, there is no automated way to ensure example pages adhere to templates beyond best effort.
- **Frontmatter Verbosity (LOW):** 16-21 base fields per page is a heavy metadata load that may lead to agent errors.

### Suggestions
- Implement a Log Rotation or Header Strategy for log.md scalability.
- Consider moving rationale documentation to external docs instead of growing AGENTS.md.
- Add a self-correction/verification task to Plan 02-02 for template-example consistency.
- Include suggestion for Obsidian CSS snippets to visually highlight epistemic markers.

### Risk Assessment: LOW

---

## Codex Review

### Plan 02-01: Page Type Templates

**Summary:** Reasonable Wave 1 foundation. Splitting templates by shared section ordering vs distinct page types is pragmatic, and the skeleton-plus-comments approach matches D-12/D-13. Main risk: optimizes for file presence and heading shape more than behavioral correctness.

**Strengths:** Aligns with D-12/D-13, good decomposition, tight scope, easy-to-verify acceptance criteria, encodes section ordering directly.

**Concerns:**
- MEDIUM: Grep-based acceptance criteria too weak to prove schema compliance
- MEDIUM: "16 base frontmatter fields" may drift from actual AGENTS schema
- MEDIUM: HTML comments may be invisible in some editors and not respected by all agents
- LOW: No mention that templates must prevent forbidden patterns from AGENTS.md
- LOW: Comparison/source-summary may need stronger guidance

**Suggestions:** Add acceptance criteria for exact required frontmatter keys. Include comments for forbidden behaviors. Add placeholder examples for provenance and epistemic markers. Prefer schema-derived wording over counted fields.

**Risk Assessment: LOW-MEDIUM**

### Plan 02-02: Example Pages

**Summary:** Most important plan — proves conventions work in practice. Main issue: evidentiary realism. The plan claims real content density, full epistemic marker coverage, a connected graph, and provenance chains from one source. Achievable only with careful design.

**Strengths:** Strong D-01 alignment, correct dependency on templates, domain coherence, graph-cluster requirement useful, explicitly demonstrates all epistemic marker types.

**Concerns:**
- HIGH: Demonstrating all four epistemic types from single source is artificial. `stale` and `tentative` usually depend on temporal drift or weak evidence.
- HIGH: "Provenance chains link to source summary page" potentially underspecified.
- MEDIUM: 3+ links per page may encourage over-linking under "first mention only" rule
- MEDIUM: Source is only "part 1" — comparison/overview claims may outrun what that source supports
- MEDIUM: No validation of aliases vs canonical titles
- LOW: No check on progressive disclosure quality

**Suggestions:** Use deliberately mixed-evidence examples. Treat `stale` carefully. Clarify prov markers vs Sources section. Add one intentional red link. Verify alias/supersession field exercise.

**Risk Assessment: MEDIUM-HIGH**

### Plan 02-03: Index, Log & Schema Docs

**Summary:** Directionally correct and necessary. Main risk: three kinds of work at once. Manageable if log format and index behavior are specified more concretely.

**Strengths:** Matches D-09, respects sole authority rule, good timing after examples exist, resolves conflict explicitly, small file count.

**Concerns:**
- HIGH: "Parseable entries" for log.md is too vague — without strict format, LOG-01-03 only partially met
- MEDIUM: Index "updated on ingest" is behavioral — plan only creates initial file
- MEDIUM: New AGENTS subsections may create duplication with existing material
- MEDIUM: AGENTS-over-CONTEXT override should be documented as resolved
- LOW: Manual index needs consistency spec as wiki grows

**Suggestions:** Define exact log entry schema now. Add explicit AGENTS language that workflows must update index/log. Keep AGENTS additions narrowly scoped. Define initial index layout explicitly.

**Risk Assessment: MEDIUM**

### Cross-Plan Observations

**Concerns:**
- HIGH: Phase may finish with compliant files but without proof agents can use them during real ingest
- MEDIUM: Page-level vs claim-level epistemic distinction should be tested in examples, not only documented
- MEDIUM: Examples rely on one source domain — weakens validation for comparison/overview synthesis
- LOW: Index drift deferred, making initial structure more important

**Suggestions:** Add final phase-level verification pass. Tighten acceptance criteria around semantic correctness. Use at least two source examples or constrain claims. Make epistemic distinction explicit in examples before documenting.

**Overall Risk Assessment: MEDIUM**

---

## Consensus Summary

### Agreed Strengths
- **Wave dependency ordering is correct** — templates before examples, examples before index/log/docs (both reviewers)
- **Domain choice is effective** — Kahneman/cognitive biases exercises entity/concept/comparison distinctions well (both reviewers)
- **User decisions are respected** — D-01, D-04/D-06, D-09, D-12/D-13 all implemented (both reviewers)
- **Scope is controlled** — no over-engineering, minimal files per wave (both reviewers)

### Agreed Concerns
1. **Epistemic marker realism (HIGH)** — Both reviewers flag that demonstrating all four epistemic types (especially `stale` and `tentative`) from a single source is artificial. Codex rates this HIGH; Gemini implicitly acknowledges through "provenance rigor" framing.
2. **Log format underspecification (HIGH)** — Codex calls "parseable entries" too vague. Gemini flags log scalability. Both agree the log needs tighter format definition.
3. **AGENTS.md growing large (MEDIUM)** — Gemini flags "lost in the middle" context pressure. Codex warns new subsections may duplicate existing material.
4. **Acceptance criteria are structural, not behavioral (MEDIUM)** — Codex explicitly says grep-based checks prove file presence but not schema compliance or agent usability. Gemini acknowledges through template-example drift concern.
5. **Single-source domain limits synthesis validation (MEDIUM)** — Codex flags comparison/overview pages may outrun what one source supports. Gemini doesn't raise this but it's implicit in the assessment.

### Divergent Views
- **Risk level:** Gemini rates overall LOW, Codex rates MEDIUM. Gemini focuses on structural completeness; Codex focuses on behavioral/semantic correctness ("demo-ware" risk).
- **AGENTS.md additions:** Gemini suggests moving rationale to external docs. Codex accepts AGENTS as the right location but warns against duplication. Both have valid points — the Phase 1 decision was "sole authority" in AGENTS.md.
- **Log scalability:** Gemini raises this as HIGH concern with rotation suggestion. Codex focuses on format strictness. Different facets of the same problem.
